# MAL-batch 性能优化点（依据 cmd/batch 性能实测）

> 对应实现：`impls/batch/`
> 依据：`../../bat_perf_report.html`（cmd/batch 等价写法微基准，两轮共 31 个用例）
> 状态：尚未实施，按下方优先级逐条推进

## 0. 性能画像（为什么"这台机器"慢）

本实现 = **宏分发 + 多模块跨文件调用 + 基于环境变量的对象模型（NS 双句柄 + 引用计数 + 写时复制）**。
每执行一个 Mal 表达式，代价链条是：

```
表达式节点 → MAIN_Eval 递归
   每子节点 → UTIL_Invoke(宏) → 非PACKED：跨文件 call = 一个 cmd.exe 子进程   [t05 2868µs]
   每次 Invoke 进出 → 2 轮 临时文件枚举 做 GC/清栈                        [t30 ~53µs/变量]
   对象建/改/删 → NS Free/CloneBody 又一轮 临时文件枚举深拷贝               [t30/t31]
   所有对象堆在全局环境变量表 → 表越堆越大 → 所有 set 变慢                 [t14 x7.9]
```

节点数 × 对象数 × 环境规模 三者相乘 → 二次方恶化。这就是"慢到必须重构"的根因。

对应性能实测速查（详见 bat_perf_report.html）：

| 结论 | 数据 |
|---|---|
| goto 循环比括号块 for 慢 | 1068 vs 472µs/圈（2.26x） |
| 跨文件 `call` 比 `call :label` 贵 | 2868 vs 2229µs（+29%） |
| 环境膨胀 3000 变量 → 普通 `set` | 42 → 329µs（~8x） |
| 枚举/清理已知 100 变量：索引直写/临时文件/子进程 | 40 / 53 / 126µs 每变量（3.13x） |
| 文件越大 `call/goto` 标签定位越贵 | 5009 行文件 7.75x |
| 去除 PATH | 内部命令无收益（cmd 不扫）；裸名外部解析才受影响 |
| setlocal 开关选择 | 无差异（成本=环境复制本身） |

---

## 1. 优化点清单（按 ROI 排序）

| # | 优化点 | 位置 | ROI |
|---|---|---|---|
| 1 | eval 递归改同文件/PACKED，消除跨文件子进程 | `util.bat:UTIL_Invoke` | 🔥🔥🔥 |
| 2 | 消除每个 Invoke 的临时文件枚举 GC | `util.bat:102-121` | 🔥🔥🔥 |
| 3 | NS 写时复制改已知索引直写、少深拷贝 | `nsutil.bat:*` | 🔥🔥🔥 |
| 4 | 控制环境膨胀（及时 Free / 短名局部变量） | `nsutil.bat:_G.NS[_G.NSP++]` | 🔥🔥 |
| 5 | reader 29 个 goto 改括号块/for | `reader.bat` | 🔥🔥 |
| 6 | `ENV_Find` 的 goto 链 + 每层线性扫 | `env.bat:48-74` | 🔥🔥 |
| 7 | 裸名 `call NSUTIL/...` 改 `%~dp0` 全路径 | 全库 `call XXX :...` | 🔥 |
| 8 | PACKED 单文件后热标签靠前、控行数 | `pack.bat` | 🔥 |

---

## 2. 逐条方案

### #1 eval 递归的跨文件子进程（架构级，先做）

**现象**：`util.bat` `:UTIL_Invoke` 非 PACKED 分支（约 89-95 行）：

```bat
rem 非 PACKED：
if /i "%~1" == "MAIN" (
    call !_G.MAIN! CALL_SELF :MAIN_%~2 ...
) else (
    call %~1 :%~1_%~2 ...        rem 跨文件 = 起子进程
)
```

`step2_eval.bat` `MAIN_Eval`（120-127 行）对列表每个子项 `%{% MAIN Eval ... %}` 又递归叠加 `call`。
**一个 N 节点表达式 ≈ 树深度次 cmd.exe 子进程**。

**方案**：
- 全量走 `_G.PACKED` 同文件单分支 `call :%~1_%~2`（省子进程）。
- 或按既定"生成式扁平单文件 + 热路径内联"路线，让 eval 主循环在**同一个 `/L` 循环 + 括号块**内完成，彻底去掉逐节点子进程。

**收益**：每节点差 ~640µs，且消除环境拷贝放大（t15：膨胀环境跨文件 call 慢 3.4x）。

### #2 每次 `UTIL_Invoke` 的临时文件枚举 GC

**现象**：`util.bat` NS 分支（102-113 行）每次调用退出都执行：

```bat
( set "_G.LEVEL[!_T.PrevLevel!]" ) > "%TEMP%\mal_gc.txt" 2>nul
for /f "usebackq delims==" %%a in ("%TEMP%\mal_gc.txt") do (
    call NSUTIL :NSUTIL_Free "%%a"
    set "%%a="
)
( set "_L[!_G.LEVEL!]" ) > "%TEMP%\mal_l.txt" 2>nul
for /f "usebackq delims==" %%a in ("%TEMP%\mal_l.txt") do set "%%a="
```

即 t30 临时文件模式（53µs/变量）+ 磁盘 IO。**每次函数调用都发生**。

**方案**：GC 集合若生成期可知 → `for /l` 索引直写（t32，40µs/变量，省临时文件、省磁盘）；
无法预知时，把"逐层清扫"改为"层结束一次性清理"，降低调用频次。

### #3 NS 写时复制（COW）深拷贝是 GC 放大器

**现象**：`nsutil.bat`：
- `NSUTIL_FreeNSBody`（369-373）释放 body 时临时文件枚举所有 `Data.Key[...]` 再逐项清 `Value[...]`；
- `NSUTIL_CloneBody`（396-405）复制 body 时同样枚举 + 逐项 CloneMeta/拷贝；
- `NSUTIL_Set`（434-444）只要 `RefCnt>1`（被共享）就整 body CloneBody 深拷贝；写完字段后 `HasField/IsValidNS/CloneMeta` 一串额外 `set`（446-466）。

对象字段越多，每次写一次字段都 O(字段数) 深拷贝 + 枚举。

**方案**：
- 字段存**已知下标的紧凑数组**，用 `for /l` 直写（t32）；
- 单 owner 对象用 move 而非 clone；减少 COW 触发面（不要为每个只读共享就复制）；
- `Free` 用索引直清，避免临时文件。

### #4 环境膨胀是二次方放大器

**现象**：`_G.NS[_G.NSP++]` 无上限分配（`nsutil.bat:NSUTIL_New/Clone`），每个 NS 占 Meta+Body 两槽，每字段两变量；程序越跑环境表越大。

**实测**：环境膨胀 3000 变量后普通 `set` 慢 ~8x（t14）、跨进程 call 慢 3.4x（t15）。

**方案**：控制活对象总量、及时 `Free`；临时对象用**短名 `_T.*` 局部变量**不进 `_G.NS` 长键堆；`.Data` 字段减少到必需量。可做**环境压缩**：每轮 GC 后重建紧凑索引。

### #5 reader 的 goto（词法热路径）

**现象**：`reader.bat` 全文件 29 个 `goto`（每 token 反复重定位 + 重解析），对应 t03 goto 慢 2.26x。

**方案**：reader 主循环改**括号块 + `for /l`**；字符匹配/回退用循环变量控制，不用 goto 回跳。

### #6 `ENV_Find` 的 goto 链 + 线性扫

**现象**：`env.bat` `:ENV_Find_Loop`（48-74）用 `goto` 沿 Outer 链上溯，每层 `for /l` 线性扫 `Key[1..Cnt]`。符号解析是热路径，越深层越贵（重复 goto 重解析 + O(深度×层内项)）。

**方案**：外层链改 `for /l` 顺序遍历（不进 goto）；小 env 用数组直查；可将符号查找下沉到 eval 的同一括号块内避免重复 `call`。

### #7 裸名跨文件 `call` 隐含 PATH 搜索

**现象**：全库大量 `call NSUTIL :NSUTIL_Get`、`call UTIL :UTIL_Invoke`（无扩展名、无路径）——cmd 需先在当前目录再沿 PATH 解析该 `.bat`。PATH 越长越贵（t41，长 PATH 外部解析 152ms/次）。

**方案**：统一 `call "%~dp0NSUTIL.bat" :...`（绝对路径，跳过 PATH 查找）；PACKED 同文件后天然消除。

### #8 PACKED 单文件的"标签定位"新代价

**现象**：生成式扁平单文件省子进程/省 PATH 查找，但把几百个函数标签挤进一个大文件。**文件越大、标签越靠后，`call/goto` 定位越贵**（t51：5009 行文件慢 7.75x）。

**方案**：生成器把高频子例程（`MAIN_Eval`、`NSUTIL_Get/Set`、`READER_*` 主循环、`ENV_*`）排在单文件**靠前**，冷函数置后；控制单文件总行数；若行数失控，按"高内聚"切成几个子例程同文件调用（同文件仍省子进程，只是换行数 vs 标签定位的折中）。

---

## 3. 建议推进顺序

1. **里程碑 A（大涨）**：#1 + #2 + #7 → 一个表达式已不再逐节点起子进程、不逐调用写临时文件。评估作为重构主干。
2. **里程碑 B**：#3 + #4 → 对象层不深拷贝、环境不膨胀，消除二次方退化。
3. **里程碑 C**：#5 + #6 + #8 → 极热路径（reader / 符号查找 / 单文件标签布局）打磨 finetune。

每个里程碑以 `test-*.bat` 回归 + （如 server 已实现）`runtest.py` 为准，性能对拍用 `bat_perf_report.html` 的结论做参照。

---

*本文档由 cmd/batch 微基准实测驱动，数据源见 `../../bat_perf_report.html` 与个人知识库《批处理cmd解析与性能.md》。*