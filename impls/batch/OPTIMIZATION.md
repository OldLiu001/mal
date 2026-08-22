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

## 进展记录（按发布时间序）

| 日期 | 提交 | 变更 | 验证 | 收益（同法对拍） |
|---|---|---|---|---|
| 2026-08-22 | `b531563` | util.bat：GetRet 内联直写替嵌套 Copy 子调用、Get/SetRet 去 `_T` 全量清扫 | step1 官方 120/120 | 12 form 13.49s→10.39s（-23%） |
| 2026-08-22 | `29603bd` | nsutil.bat：NSUTIL_Get 用 `if defined` 守卫替代冗余 HasField 子调用 | step1 官方 120/120 | 12 form 10.39s→9.67s（累计 -28%） |
| 2026-08-22 | `0866e36` | util/nsutil：`%&%` 跨文件 Copy 全改 `call set` 间接读取；Invoke 删 NSUTIL 分支内重复 `_L` 清扫 | step1 官方 120/120 | 24 form 186.3s→152.9s（-18%） |
| 2026-08-23 | 回退 | nsutil.bat：Set 内把 `HasField`/`IsValidNS` 内联为 `call set` 双重解引用（先解析值再读 `.Type`）——**回退**。该内联对含 `~`/`(` 的字面值触发 `%~` 路径算子崩溃；改用 `if defined` 守卫后又破坏 NS 引用检测（字段值必须先解引用才是句柄，间接路径失效） | 方案不成立，回退至 `call NSUTIL` 子调用（NSUTIL_Get 的 IndirectGet 内联保留） | 正确性优先：内联必须以不解引用原始字面值、又能识别间接句柄为前提 |

### 实测观察（2026-08-22）
- 用 PowerShell 管道对拍：step1 进程存在约 7s 的固定启动/init 开销（cmd 环境复制 + NSUTIL/UTIL 初始化），
  每 form 边际成本在批内随量下降，说明**大批量下每 form 的真实成本高出单进程小批量对拍**；官方 runtest 单进程喂
  多 form，故优化每 form 路径仍有真实收益（step1 官方 120 test 在约 200s 内完成，约 1.6s/test）。
- 由于该固定启动开销，**优化每次字段读/交接的子进程（#1#2#7）比只压单次解析更有价值**——已落地方向正确。

### 下一步候选
- **reader 词法热路径（#5）**：`reader.bat` 仍有大量 goto/成块的 `{g`/`{s`，可批量去 goto 化 + 合并字段读写为块。
- **环境膨胀（#4）**：`_G.NS[...]` 全局递增且不复用，程序越长表越大、所有 set 变慢。GC 后重建紧凑索引是最根本防御。
- **`UTIL_Invoke` 临时文件 GC（#2 残余）**：每次 Invoke 退出仍写 `mal_l.txt`/`mal_gc.txt` 两次磁盘，可改为 `for /l` 索引直清。
- **step2/step3**：eval/env 更重，基础设施收益应辐射过去，需单跑官方 test 建立基线。

### 实测补充（2026-08-23，本会话结论）

1. **Set 的 `call set` 双重解引用不成立**：`call set "_T.R=%%!_T.V!%%"` 在 `_T.V` 为含 `~`/`(` 的字面值时会
   re-parse 出 `%~@…%`，触发"batch-parameter path operator"报错（功能仍恢复，但产生污染 stderr，官方 runtest
   判定易失败）。外层加 `if defined !_T.V!.Type` 守卫虽避免崩溃，却**错误拦截了合法的间接 NS 句柄**——NS 字段值
   在调用方已被 `!…!` 解引用为句柄名（如 `_G.NS[7]`），其 `.Type` 属于句柄所指对象而非该变量本身，故直接
   `if defined 值.Type` 失配。结论：正确识别"值是否为 NSMeta"必须走真实解引用，不能既快又安全地仅靠 `if defined`。

2. **`~@` 路径噪声是既有问题**：`splice-unquote`（`~@(…)`）触发路径算子报错在**未优化基线同样存在**，属于
   `IsValidNS` 对符号字面值解引用的固有噪音，输出正确、exit=0，不应优先在此处内联。

3. **PACKED 朴素扁平化会导致无限递归（重要事故）**：把各模块纯文本按 `pack.bat` 式 `:模块名` 拼接、并让入口
   `call :模块_函数` 同文件分发，实测单表单约 300ms/form（对照 unpacked ~15s/form，约 40x）——速度极具吸引力。
   但 `io/readline` 等模块靠 `CALL_READLINE`/`CALL_WRITEALL` 标签自我分发（`call %~f0 CALL_READLINE`），
   压扁后 `goto :READLINE` 定位到错误段落，触发 `cmd /c call <file> CALL_READLINE` **自成环无限递归**，单进程
   数十秒内孵化数百个 cmd 子进程直至内存耗尽。结论：PACKED 是正确的大方向（消除跨文件子进程），但**必须专门设计
   扁平化的 `_模块_函数` 统一命名与转发层**，彻底移除 `%T.UTIL%`/文件级 goto 分发，杜绝文件自我调用递归；当前
   朴素拼接不可用。

> 事故止损经验：批量批处理测试在该环境必须**单进程、短超时、不并行后台**，出现进程数快速增长时立即 `Stop-Process`
> 全量清理并断根（进程树可能脱离后台 job 自我繁殖）。

---

*本文档由 cmd/batch 微基准实测驱动，数据源见 `../../bat_perf_report.html` 与个人知识库《批处理cmd解析与性能.md》。*