# MAL Batch 实现（Windows 批处理）

用纯 Windows CMD 批处理实现 Make-A-Lisp。当前分支：batch-ai-dev。
`bak/` 是老实现（step0–step3 通过官方测试）；本目录是新实现（从零重写，架构解耦，进行中）。

> **本文档聚合了本目录所有文档**（readme + 性能优化 + PACKED 安全基线），分散的
> `OPTIMIZATION.md`/`PACKED_SAFETY.md` 已并入下文各节。spec（`*.spec.md`）保持独立。
> TOC：
> 1. [架构总览](#1-架构总览)　2. [输入输出管线](#2-输入输出管线)　
> 3. [性能（含优化画像/方案/进展记录）](#3-性能)　4. [踩坑记录](#4-踩坑记录)　
> 5. [老实现（bak）经验](#5-老实现bak经验)　6. [架构缺陷清单](#6-架构缺陷清单)　
> 7. [进度台账](#7-进度台账)　8. [性能优化点清单（ROI 排序）](#8-性能优化点清单roi-排序)　
> 9. [PACKED 改造安全基线](#9-packed-改造安全基线)

## 1. 架构总览

### 1.1 分层
| 层 | 文件 | 职责 |
|---|---|---|
| 入口 | step*_*.bat | REPL/测试入口，初始化 UTIL+NSUTIL |
| 基础设施 | util.bat | 宏定义、UTIL_Invoke 调用机制、异常/返回、GC |
| 内存管理 | nsutil.bat | NS 对象创建/克隆/读写/释放，引用计数 |
| 类型系统 | types.bat | MalNum/MalSym/MalStr/MalLst/MalVec/MalMap/MalFn... |
| 读取器 | reader.bat | Tokenize → ReadForm/ReadList/ReadMap/ReadAtom → AST |
| 打印器 | printer.bat | AST → Mal 表示法字符串 |
| 字符串 | str.bat | 可变 String NS（Line[] 存储） |
| 环境 | env.bat | step3 环境（待续） |
| IO | io.bat | 读入/写出（READLINE/WRITEALL 转义管线） |
| 辅助 | readline/writeall/readall/pack.bat | 转义、解码、单文件打包 |

### 1.2 变量命名
- 全局：_G.*（_G.LEVEL/_G.RET/_G.ERR/_G.TRACE/_G.NSP/_G.NS[N]）
- 局部：_L[level].VarName；函数内 `for %%. in (_L[!_G.LEVEL!].)` 取层前缀
- NS：_G.NS[N]（NSMeta：.Type/.Target/.RefCnt；Body：.Data.Key[F]/.Data.Value[F]）
- 老实现（bak）：_L{level}_Var / _G_VAR（花括号+下划线，无点号）

### 1.3 宏（调用机制）
UTIL_Init 定义宏变量，展开成 call 语句：
| 宏 | 展开 | 用途 |
|---|---|---|
| %{% MOD Fn args %} | call util :UTIL_Invoke MOD Fn args | 函数调用 |
| %{n%/%{g%/%{s%/%{c% | %{% + NSUTIL New/Get/Set/Clone | NS 快捷操作 |
| %->% Var | & call util :UTIL_GetRet Var | 取返回值 |
| %<-% Var | call util :UTIL_SetRet Var | 设返回值 |
| %?% | if defined _G.ERR | 错误分支 |
| %??% "msg" | call util :UTIL_Throw | 抛异常 |
| %?|% "msg" | call util :UTIL_Fatal | 致命退出 |
| %-|% | exit /b 0 | 提前返回 |
| %&% From To | call util :UTIL_Copy | 变量复制 |
| %_G.SKIPTHIS% | rem（FAST 模式） | 跳过断言 |

UTIL_Invoke：直接以 %~1/%~2 分发 → call MOD :MOD_Fn args（MAIN 走 CALL_SELF）→ 返回后清理 _L[level]* 并 Free 上层注册 NS（GC）。

## 2. 输入输出管线
stdin → READLINE（转义）→ IO_ReadEncLine → 解析器 → IO_WriteEncLine → echo."值"|WRITEALL（解码）→ stdout
转义：`"`→$D、`!`→$E、`^`→$C、`%`→$P、`$`→$$、`:`→$A。**协议不覆盖 ( )**。

## 3. 性能（2026-08-15 修复）
### 3.1 根因
"两段 11–13s 卡顿"是**假象**：块内 `%TIME%` 解析期展开，标记时间戳≠执行时间。
真实数据（s1m，362 次顶层标记）：平均 72ms/调用、最大间隙 260ms、无 >300ms 间隙。
真问题：**每个 UTIL_Invoke 产生 2–3 个 cmd 子进程**（for/f ('echo.%*') 分发 + GC 扫描 + _L 清理），每次 ~10–40ms。

### 3.2 修复
1. **分发去子进程**：`for /f ('echo.%*')` → 直接 `%~1/%~2` 传参（%3–%9 透传）。
   语义等价依据：`call :label "a b"` 的 %1/%* 保留引号（实证）；字符串版 for/f `in ("%*")` 遇括号语法错误，不可用。
2. **枚举去子进程**：`for /f ('set "前缀"')` → `( set "前缀" ) > %TEMP%\mal_*.txt 2>nul` + `for /f "usebackq delims==" (file)`。
   实测 12–25x；**空匹配必须 2>nul**（否则 stderr 刷"环境变量未定义"）。
3. CALL_SELF（step1_read_print.bat）、FreeNSBody/CloneBody 的 Data.Key 扫描同样改直接调用/文件枚举。

### 3.3 数据（修复后，无调试标记）
| 输入 | 修复前 | 修复后 |
|---|---|---|
| 空 | 1.9s | 0.14s |
| 123 | 10.5s | 2.78s |
| (+ 1 2) | 43.5s | 12.30s |

### 3.4 剩余瓶颈
`call :标签` 往返 ≈ 1.7ms，**与文件大小无关**（2KB vs 90KB 同价，标签扫描不是瓶颈）。
每逻辑调用 = 8–10 次物理 call（Invoke+模块分发+SetRet/GetRet/Copy+嵌套 NSUTIL 链）≈ 25–37ms。
pack.bat 单文件打包无提升（86KB 大文件 IO 子进程更慢）。下一步方向：NSUTIL 热路径直调。

### 3.5 性能改进方案（2026-08-17 分析，按收益/风险排序）
| 方案 | 改什么 | 预期收益 | 风险 | 工作量 |
|---|---|---|---|---|
| P1 NSUTIL 直调 | {n/{s/{g 宏 → `call NSUTIL :NSUTIL_X` 直调；函数体局部变量改 `_T.<FN>.` 前缀 | 2-3x（每 NSUTIL 操作 10ms→2ms） | 中（注册层 LEVEL 语义） | M |
| P2 GetRet 并入 Invoke | UTIL_Invoke 尾部直接复制 _G.RET 到出参 | ~20% | 低 | S |
| P4 _L 清理计数门 | 维护每层局部计数，空层跳过清理 | ~10% | 低 | S |
| P6 EncKey 缓存 | 符号 .Enc 字段缓存编码 | ~5-10% | 低 | S |
| P5 链式 env | EnvCopyOuter 改 NewEnv.Outer 指针 + 查找上溯 | step3 会话大头之一 | 中 | M |
| P3 IO 内联 | ReadEncLine 内联 set /p + 缓存 ESC | ~0.2-0.5s/用例 | 中 | M |
| P7 热路径单函数化 | reader/printer 合并调用链 | x 倍级 | 高 | L |

实施顺序：① P1+P2（与 step3 收尾并行）→ ② step3 剩余用例（mynum/w/y 编码一致性、嵌套 let*、DEBUG-EVAL）→ ③ P4+P6 → ④ P5（step4 fn/闭包前置）→ ⑤ P3。预计合计 3-6x；stepA 自举前 P1/P2 是硬门槛。

## 4. 踩坑记录

### 坑1：解析期 vs 执行期
%VAR% 解析期展开；!VAR! 执行期展开；for/if 括号块整体解析一次。块内解析期出现未加引号的 ( ) → `X was unexpected at this time`。纪律：特殊文本只进引号或变量值，禁止裸嵌。

### 坑2：值传参两道鬼门关
UTIL_Invoke 传参：①空格分词错位（值必须整体带引号）；②%* 解析期展开，值里 () 会进命令串。规则：值参数一律带引号，接收方第一行 set "局部=%~N" 入变量。**注意：for /f 的 `*` 令牌保留引号原文（tokens=1,* 时 %%b = 原样余部），这是"值带引号传参"能工作的关键。**

### 坑3：if defined %~1.Target 模式
把参数值嵌入变量名检查：值是 NS 引用（_G.NS[5]）没事，值是 (1 2 3) 就解析期崩。修法A：set "%%.T=%~1" 后用 %%.T.Target（for 变量名）。修法B（判断值是否NS）：call set 二次展开。

### 坑4：%~1 去引号
call 去一层、%~N 再去一层。传 "(1 2 3)" 收 (1 2 3)。

### 坑5：块内 echo
解析期字面含 ' + ) 组合崩 unexpected '；动态文本走变量。

### 坑6：变量名 vs 值
*Var（接收方 !%~1! 解引用）vs _Val（值），调用前想清楚。

### 坑7：UTF-8 BOM
Set-Content -Encoding UTF8 写 BOM → @echo off 失效。写 .bat 用 ASCII 或 WriteAllText + UTF8Encoding($false)。

### 坑8：nul 是保留设备名
>nul 误建的文件无法复制/删除/提交（用 \\?\ 前缀删除）。

### 坑9：管道 EOF
echo x | step.bat 在 EOF 后 set /p 立即返回空 → REPL 无限刷 user>。测试用文件重定向驱动。

### 坑10：runtest.py Unix-only
顶层 import pty/fcntl/termios。自写 file_driver.py（os.system + 临时文件，可靠）。

### 坑11：宏层叠
set "{s=!{! NSUTIL Set" 只有一层延迟展开；%} 闭合符括号配对必须保持。

### 坑12：块内 %TIME% 是解析期值
定位性能必须用**顶层**标记（for/f 块外的 echo），否则时间戳全是"块解析时间"。

### 坑13：NSUTIL_Set 自杀式回收（2026-08-15 修复，map 输出 {} 的根因）
Set 覆盖已有 NS 值字段时：先 Free 旧值，再 IsValidNS 新值——**若新旧是同一句柄（重复 Set 同一值），旧值回收把"正要存的新值"杀掉**，随后 IsValidNS 失败、把死句柄直接存入字段；teardown 再因 RefCnt 已减而彻底 Free 掉 body。
修复：Set 开头先 `set "%%.V=%~3"`，HasField 命中且 `"!%%.OldVal!" == "!%%.V!"` 时 `%-|%` 提前返回（值未变，什么都不做）。

### 坑14：消息传输层会掩码 "token=" 前缀
写脚本内容含 `token=!%%.Token!` 之类的字样会被传输层当密钥掩成 `***`（写入文件后就是字面 ***）。调试输出避免 `token=` 前缀（用 tok= 等）。

## 5. 老实现（bak）经验
- 值不整体传参：列表打印逐项 AppendVar（变量名），(")/") 单字符字面量。
- NS 标记：_G_NS[N].= 作为"是NS"标记。
- AutoFreeList：返回 NS 登记到上层，UTIL_Invoke 收尾统一 Free（新实现沿用为 _G.LEVEL[level][ns]）。
- RefCnt：Link/Copy +1，Free 递减到 0 释放。新实现加 CloneMeta/写时复制。

## 6. 架构缺陷清单（2026-08-17 分析，基于实施全程一手实测）

### 高危
| # | 缺陷 | 影响 | 方案/状态 |
|---|---|---|---|
| H1 | **cmd 环境变量大小写不敏感**：`Item[mynum]` 与 `Item[MYNUM]` 同一变量（实测 mynum 返回 222） | 违反 MAL 符号大小写语义，step3 失败 | EncKey 逐字符编码（小写→ch0/其他→ch1）已实施；治标（每次查找一次编码循环） |
| H2 | **NSUTIL_Set 覆盖同句柄时旧值回收自杀**（坑13） | map 输出 {} 根因 | 已修（OldVal==V 提前返回） |
| H3 | **%} 宏在 _G.ERR 时 exit /b 0 → REPL 错误分支从未执行** | step1 错误用例假通过 | 已修（顶层 REP/错误分支用显式 call !_T.UTIL! :UTIL_Invoke） |
| H4 | **内存模型双句柄语义（meta vs body）**：HasField/Get 期望 meta（有 .Target）；直接拼 .Data.Value 期望 body | 两类 API 混用极易踩坑（EnvCopyOuter 全读空、符号查找全失败） | 未修：统一约定 NSUTIL API 收 meta、直接访问先解 .Target；或提供 EnvBody 解析辅助 |

### 中危
| # | 缺陷 | 方案/状态 |
|---|---|---|
| M1 | 转义管线改变符号语义（def! → def$E 字面），MalMap 字段名含 $D/$E 脆弱 | 符号 key 统一在转义后域操作（现状）；长期 reader 层反转义 |
| M2 | 直接 call（非 UTIL_Invoke）不递增 LEVEL → 局部变量共享覆盖风险（MAdd/EncKey 与调用者同 _L[level]） | 直调函数统一 _T.<FN>. 前缀（与 P1 同批） |
| M3 | let* 用 EnvCopyOuter 复制外层而非链式 env：O(绑定数)/次，依赖 RawKeys 维护 | 链式 env（Outer 指针 + 查找上溯），step4 fn/闭包前置 |
| M4 | EncKey 逐字符编码每次符号查找都执行 | 编码缓存到符号 .Enc 字段 |

### 低危
| # | 缺陷 | 方案 |
|---|---|---|
| L1 | 生成器脚本（gen_step2/3.py）与手修 patch（fix_s3_*.py）并存；写 .bat 必须 newline=""（
\n 双重转义成 \r\r\n 实测崩） | 收敛为单一生成器或直接维护 bat 源文件 |
| L2 | 测试驱动依赖：file_driver 需 --session（有状态单会话）、check 行尾匹配、;/ 正则 | 固化 file_driver 入仓库 |
| L3 | MalMap 字段名嵌特殊字符可调试性差；%TEMP%\mal_*.txt 跨进程共享有污染风险（并发 REPL 实测） | 临时文件加进程唯一后缀；文档化 |

## 7. 进度台账（2026-08-17）
- step0：24/24 官方 runtest 管道通过（早期）；file_driver 19/19。
- step1（step1_read_print.mal）：**119/119 全通过**（含错误/正则用例；file_driver 支持 `;/regex` 与 REPL 错误分支修复）。
- step2（step2_eval.mal）：**15/15 全通过**（算术/集合求值/错误用例）。
- step3（step3_env.mal）：**26/35**——剩 4 个 non-optional（mynum/w/y 大小写编码一致性、嵌套 let*）+ 5 个 optional DEBUG-EVAL。
  已修：def!/let*（AutoEval=False）、EnvCopyOuter（Get 路径）、EncKey 大小写编码、meta/body 句柄。
- 架构缺陷与性能改进分析报告已并入本文档（3.5 性能方案、6 架构缺陷清单）。

TODO：
- [x] step1 全量（含 map/错误用例）
- [x] step2_eval 验证通过
- [ ] step3_env 剩余 4 个 non-optional + DEBUG-EVAL（optional）
- [x] 性能优化 P1（NSUTIL 直调：宏 {n/{s/{g/{c 直调 + _T. 前缀局部变量 + 内层 9 处直调；123 2.8→2.5s、列表 12.3→10.0s，回归跑批中）
- [ ] 性能优化 P2（GetRet 并入 Invoke）
- [ ] step4_if_fn_do / step5_tco（链式 env 前置）
- [ ] step6_file ~ step9_try / stepA_self-host
- [ ] git 提交

---
---

# 8. 性能优化点清单（ROI 排序）

> 数据源：`../../bat_perf_report.html`（cmd/batch 等价写法微基准，两轮共 31 个用例）
> 与个人知识库《批处理cmd解析与性能.md》。状态：按下方优先级逐条推进。

## 8.0 性能画像（为什么"这台机器"慢）

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

## 8.1 优化点清单（按 ROI 排序）

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

## 8.2 逐条方案

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

## 8.3 建议推进顺序

1. **里程碑 A（大涨）**：#1 + #2 + #7 → 一个表达式已不再逐节点起子进程、不逐调用写临时文件。评估作为重构主干。
2. **里程碑 B**：#3 + #4 → 对象层不深拷贝、环境不膨胀，消除二次方退化。
3. **里程碑 C**：#5 + #6 + #8 → 极热路径（reader / 符号查找 / 单文件标签布局）打磨 finetune。

每个里程碑以 `test-*.bat` 回归 + （如 server 已实现）`runtest.py` 为准，性能对拍用 `bat_perf_report.html` 的结论做参照。

## 8.4 性能进展记录（按发布时间序）

| 日期 | 提交 | 变更 | 验证 | 收益（同法对拍） |
|---|---|---|---|---|
| 2026-08-22 | `b531563` | util.bat：GetRet 内联直写替嵌套 Copy 子调用、Get/SetRet 去 `_T` 全量清扫 | step1 官方 120/120 | 12 form 13.49s→10.39s（-23%） |
| 2026-08-22 | `29603bd` | nsutil.bat：NSUTIL_Get 用 `if defined` 守卫替代冗余 HasField 子调用 | step1 官方 120/120 | 12 form 10.39s→9.67s（累计 -28%） |
| 2026-08-22 | `0866e36` | util/nsutil：`%&%` 跨文件 Copy 全改 `call set` 间接读取；Invoke 删 NSUTIL 分支内重复 `_L` 清扫 | step1 官方 120/120 | 24 form 186.3s→152.9s（-18%） |
| 2026-08-23 | 回退 | nsutil.bat：Set 内把 `HasField`/`IsValidNS` 内联为 `call set` 双重解引用（先解析值再读 `.Type`）——**回退**。该内联对含 `~`/`(` 的字面值触发 `%~` 路径算子崩溃；改用 `if defined` 守卫后又破坏 NS 引用检测（字段值必须先解引用才是句柄，间接路径失效） | 方案不成立，回退至 `call NSUTIL` 子调用（NSUTIL_Get 的 IndirectGet 内联保留） | 正确性优先：内联必须以不解引用原始字面值、又能识别间接句柄为前提 |

### 8.4.1 实测观察（2026-08-22）
- 用 PowerShell 管道对拍：step1 进程存在约 7s 的固定启动/init 开销（cmd 环境复制 + NSUTIL/UTIL 初始化），
  每 form 边际成本在批内随量下降，说明**大批量下每 form 的真实成本高出单进程小批量对拍**；官方 runtest 单进程喂
  多 form，故优化每 form 路径仍有真实收益（step1 官方 120 test 在约 200s 内完成，约 1.6s/test）。
- 由于该固定启动开销，**优化每次字段读/交接的子进程（#1#2#7）比只压单次解析更有价值**——已落地方向正确。

### 8.4.2 下一步候选
- **reader 词法热路径（#5）**：`reader.bat` 仍有大量 goto/成块的 `{g`/`{s`，可批量去 goto 化 + 合并字段读写为块。
- **环境膨胀（#4）**：`_G.NS[...]` 全局递增且不复用，程序越长表越大、所有 set 变慢。GC 后重建紧凑索引是最根本防御。
- **`UTIL_Invoke` 临时文件 GC（#2 残余）**：每次 Invoke 退出仍写 `mal_l.txt`/`mal_gc.txt` 两次磁盘，可改为 `for /l` 索引直清。
- **step2/step3**：eval/env 更重，基础设施收益应辐射过去，需单跑官方 test 建立基线。

### 8.4.3 实测补充（2026-08-23，本会话结论）

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

4. **PACKED 同进程 `call :label` 会破坏对象读 `!%%.Field!`（本会话实测，阻断 PACKED）**：
   按 9.5 的"入口转发 + 同文件 `:模块_函数`"做安全压扁后（`_pack.py` 拼 util/nsutil/reader/printer/
   str/types/env/io + 头 `call :NSUTIL_Init` + `call :MAIN_Main`），核心 NS 初始化本体正常
   （`_G.NSUTIL` 已置位、`_G.NS[1..2].Type=NSBody/NSMeta` 成立），但**首次 `%{n% %%.R %}`（`call :NSUTIL_New`）
   返回后，调用方后续 `!%%.R!` 一律读到空**，即使 `_L[0].R` 已被 `set "%~1=..."` 正确写成 `_G.NS[2]`；
   逐条 `!%%.X!`（秒字面值/`_G.NS[2]` 值/`_L[9].`/`L[1].` 前缀）在**隔离测试中全部正常**，唯独真实
   PACKED 进程内出现 → 报 `Fatal: 'NS' undefined.`（`!%%.Reader!` 传递为空）。
   结论：**PACKED 的"同文件 `call :label` + 共享 `.` for-var"组合不可靠**——原多模块架构的 `.` for-var 对象
   域（`_L[LEVEL].`/`_T.XX.`）依赖**跨文件子进程隔离**才不串扰，压成单文件后失去该隔离，根因不是打包脚本，
   而是 `_G.NS`/`_G.LEVEL` 全局 + `.` for-var 与进程内递归调用的隐蔽交互（隔离无法复现，需换对象模型）。
   判定：**PACKED 变换不具备"只改拼接、不动对象模型"的可行性**，需重设计（每个模块用不同 for 字母 / 弃用
   `.` for-var 域），风险与收益不成比例，本轮冻结。**

5. **实测性能画像（本会话，README 同机对拍，非官方 runtest）**：用 `_drive.py` 同进程喂表单（排除单进程启动、
   含 step1 init 的首表单 ~7s 后计时）：
   - 原子表单（`1`/`abc`/`xyz`）边际 **~3-5s/form**；
   - 列表表单（`(a)`/`(a b)`/`(a b c d e f g h i j)`）**~32s/form 且与元素个数几乎无关**（1、2、10 元素同为
     ~32s）——是**固定每列表开销**，不是逐元素线性成本；
   - 单一 `(+ 1 2)`（含启动/init）=`_safe.py` 全进程 **32.78s/exit 0**。
   含义：瓶颈是**每列表级别的一次级联**（列表触发 ReadList 层加深 → UTIL_Invoke 递归 → 每层跨文件子进程 +
   每 Invoke 的 `mal_gc.txt`/`mal_l.txt` 临时文件 GC），与列表长度无关，与 §8.4.0 画像一致。原子已较优、
   列表仍被"跨文件子进程 + 环境快照 GC"钉死——**只有消除跨文件子进程（PACKED 方向）才能根治，而该方向被
   §8.4.3.4 冻结**，需先重设计对象模型。任何不根治此点的微内联收益有限。

> 事故止损经验：批量批处理测试在该环境必须**单进程、短超时、不并行后台**，出现进程数快速增长时立即 `Stop-Process`
> 全量清理并断根（进程树可能脱离后台 job 自我繁殖）。

（原始 `OPTIMIZATION.md` 已于 2026-08-23 并入本节，文件移除。spec/数据源 `../../bat_perf_report.html` 保持。）

---
---

# 9. PACKED 改造安全基线

> **现状（2026-08-23 定稿）：PACKED 已冻结**。见 §8.4.3.4——同进程 `call :label` + 共享 `.` for-var
> 会在真实 PACKED 内破坏对象读 `!%%.Field!`（隔离无法复现），需另设计对象模型，本轮不再投入。
> 本节的静态设计（宏转发/入口包裹/自杀递归风险）**保留作为基线**，一旦未来重构对象模型再启用。
> 原 `PACKED_DESIGN.md` 已于本轮并入本节 + §8.4.3，文件移除。
>
> 目的：为"多模块压扁为单文件（PACKED）"提供**静态、0 执行**的安全约束，
> 杜绝上次事故（`cmd /c call <file> CALL_READLINE` 自成环无限递归直至内存耗尽）。
> 只做审计约束，不修改任何可执行逻辑。修改代码前必须先满足此处所有规则。

## 9.0 为什么 PACKED 理论上快（~40x，但被 §8.4.3.4 阻断）

非 PACKED 下 `_T.UTIL` = `%~n0`（裸名 `util`），宏展开为 `call util :UTIL_Invoke ...` = **跨文件 = 新建
cmd 子进程**。单表单 `(+ 1 2)` 走 Read→(tokens)→Print→(PRINTER/STR)→IO，每层跨文件 `call`，一次 REPL
触发**上百次 cmd 子进程**，每次继承整个环境表——几十秒的根因。PACKED 下 `_T.UTIL` 空 → 全变 `call :label`
同文件跳转零子进程（`call :label` 2229µs vs 跨文件 2868µs，且免环境复制放大）。

## 9.1 事故根因回顾（为什么朴素拼接会炸）

`io.bat`/`readall.bat` 对 `READLINE`/`WRITEALL` 的调用有两种身份：

| 调用形式 | 语义 | PACKED 后的问题 |
|---|---|---|
| `call READLINE` | 裸名外部命令 → 解析到 **`readline.bat`** 文件 | 非 PACKED 路径；压扁后被 `_G.PACKED` 遮蔽不触发 |
| `call "%~s0" CALL_READLINE` | **`%~s0` 回指当前脚本本体**，靠首参 `CALL_READLINE` 经打包入口转发头分派 | 若转发头标签与顺序脚本命名不一致 → `goto` 近似落点错位 |

`pack.bat` 生成的头是：
```bat
if "%~1" equ "CALL_READALL"  goto :READALL
if "%~1" equ "CALL_READLINE" goto :READLINE
if "%~1" equ "CALL_WRITEALL" goto :WRITEALL
:MAIN
```
而 `readline.bat` 是**顺序执行脚本**（无 `:CALL_READLINE` 函数，直接跑顶层 `set /p` + `:READLINE_Replace` 循环）。**关键约束**：
1. 转发头 `goto :READLINE` 必须命中**单文件中确实存在**的精确标签（大小写一致）。
2. 若标签缺失/错名，cmd 会**近似落点**到 `:READLINE_Replace` 等内部段 → 带 `CALL_READLINE`
   参数再次进入该段 → 自我调用形成环 → 级联起子进程 → **进程树爆炸、内存耗尽**。
3. 现状核对（历史产物 `mal_step0_packed.bat`）：旧版打包器生成的标签是**全小写**
   `:readline`/`:writeall`，与 `goto :READLINE` 的**大写目标不匹配** → 正落入上述错位。
   此产物是死亡历史遗留（旧 `UTILITIES` fork），非当前仓库所用，但印证了根因方向。

> 关键判定：压扁安全的充分条件 = **打包入口转发头的标签名与顺序脚本在单文件中的
> 标签大小写完全一致**，且 `call "%~s0" CALL_*` 自带 `_G.PACKED` 保护。本轮不改
> readline/writeall 本体，只确保调用与转发头匹配。

## 9.2 静态危险点清单

以下位置含"自身引用 + 标签/裸名分派"，是压扁的关注点（调用层，**readline/writeall 本体不可动**）：

| 文件:行 | 模式 | 说明 |
|---|---|---|
| `io.bat:33` | `'call "%~s0" CALL_READLINE'`（PACKED 分支） | 方式 2 分发，需转发头命中 |
| `io.bat:54` | `'call "%~s0" CALL_WRITEALL'`（PACKED 分支） | 方式 2 分发，需转发头命中 |
| `io.bat:27` | `'call READLINE'`（裸名） | 非 PACKED 路径，压扁后不出现 |
| `io.bat:52` | `call WRITEALL`（裸名） | 非 PACKED 路径，压扁后不出现 |
| `readall.bat:7` | `call "%~0" CALL_READLINE` | 方式 2 分发 |
| `readall.bat:5` | `call readline`（裸名） | 非 PACKED 路径 |

**通用红线（改造时逐条对照）**
- ✅ **`readline.bat`、`writeall.bat` 本体禁止任何改动**——内部转义/参数延迟展开/逐字符
  循环顺序高度易碎，作者已在其各自上下文内谨慎定型。任何改动须先做充分回归
  （跑 stepX 官方 `runtest.py` 全量）再谈。
- ✅ 压扁的正确思路 = **不改 readline/writeall 本体**，而是让 `io.bat`/`readall.bat`
  的 `%~s0 CALL_*` 调用经**打包入口转发头**命中这些顺序脚本的标签位置（见 `pack.bat`）：
  ```bat
  if "%~1" equ "CALL_READLINE" goto :READLINE   rem 命中 readline 顺序执行段
  if "%~1" equ "CALL_WRITEALL" goto :WRITEALL
  ```
- ⚠️ 该转发头要求**目标顺序脚本在单文件中以精确大写标签定位**；若标签大小写/命名与
  `goto` 目标不一致，cmd 会近似落点 → 错位。**这是上次爆内存的可疑根因**，改造前必须
  核对 `pack.bat` 生成的标签名与转发目标完全一致。

## 9.3 打包入口转发层设计（调用点方案，readline/writeall 不动）

正确方向（作者在 `pack.bat` 已埋好）：

1. **`readline.bat`/`writeall.bat` 保持顺序执行脚本原样**，作为"读 stdin → 输出转义后
   stdout"的黑盒，不封装成 `:xxx_Run` 函数。
2. 压扁单文件的入口头是**唯一转发层**：`CALL_READLINE → :READLINE`、
   `CALL_WRITEALL → :WRITEALL`、`CALL_READALL → :READALL`。
3. `io.bat`/`readall.bat` 的 PACKED 分支 `call "%~s0" CALL_*` 经该头分发到对应顺序脚本。
4. 前提校验：生成的单文件里**确实存在** `:READLINE`/`:WRITEALL`/`:READALL` 标签，
   且与 `goto` 目标大小写完全一致（缺一或错名 → 近似落点 → 递归）。
5. 压扁后不得残留裸名 `call READLINE`/`call WRITEALL`（非 PACKED 分支被 `_G.PACKED`/SINGLE_FILE
   保护遮蔽，天然不触发）。

## 9.4 运行与止损规则（防止再次爆内存）

- **任何 PACKED 压测只喂单个表单，且设 `timeout` 壳**（几秒内超时即杀）。
- 跑之前先对目标文件执行一次本审计模式的静态扫描（grep `%~s0`/`%~0`/裸名调用）。
- 一旦观察到 cmd 进程数飙升（>20），立即全量 `taskkill` 清理并中断任务，
  不要等它自然结束。
- 进程暴涨疑似是递归 → 先承认事故，改代码结构（不是靠调参绕过），再重试。

## 9.5 现状结论与方向澄清

- 作者在 `pack.bat` 已埋好**打包入口转发头**（`CALL_READ* → goto :READ*`），说明
  "调用点方案"（readline/writeall 本体不动、只靠转发头命中）是既定正确方向。
- 关键充分条件：**转发头标签名与顺序脚本单文件标签大小写完全一致**，否则券近似落点递归
  （历史产物 `mal_step0_packed.bat` 的 `:readline` 小写 vs `goto :READLINE` 大写即错例）。
- 下一步安全路径：核对并**修正打包转发头的标签命名**（而不是改 readline/writeall 本体），
  然后单表单单超时小步验证。
- **方向澄清（本会话定稿）**：曾验证"文件头 `%*` 分包层 + 同名函数"的**调用点转发范式的
  机制可行性**（见下 9.6），但这**不意味着**要给 readline/writeall 本体做真函数化——它们是
  顺序执行黑盒，按 9.1~9.3 只需靠打包入口转发头命中，**本体保持原样**更好（不触碰易碎转义
  逻辑）。9.6 的样板纯粹用于验证"`%*` 分包 + 标签转发"这条路能成立。

## 9.6 令牌转发样板验证（writeall，本会话实测）

用 **临时原型**（不含任何非 ASCII 注释，`_wa_proto.bat`，验证后已删）验证了
"顺序执行脚本 → 真函数 + 分派层"的改写范式可行，输出如下：

| 进入方式 | 输入 | 输出 | 判定 |
|---|---|---|---|
| 裸名 `call WRITEALL` | `(+ 1 2)` | `(+ 1 2)` | ✅ |
| 分派 `call WRITEALL CALL_WRITEALL` | `(+ 1 2)` | `(+ 1 2)` | ✅ |
| 裸名（含转义） | `$$E$$C$$P= $A` | `$E$C$P= :` | ✅ 转义还原正确 |
| 分派（含转义） | `$$E$$C$$P= $A` | `$E$C$P= :` | ✅ |

**验证范式（writeall 样板）**：
```bat
@echo off
setlocal ENABLEDELAYEDEXPANSION
if /i "%~1"=="CALL_WRITEALL" ( call :WRITEALL_Run & exit /b 0 )
if "%~1"==""               ( call :WRITEALL_Run & exit /b 0 )
>&2 echo [%~nx0] ERROR: unknown arg=%~1 & exit /b 1

:WRITEALL_Run
for /f "delims=" %%i in ('more') do (
    ... 原顺序逻辑，goto :_WA_Loop 保持 ...
)
exit /b 0
```

**结论**：
- 真函数化的关键：**`%*` 分包层在文件头直接 `exit /b` 或回落**，杜绝 `%~s0` 自回指。
- **写入 .bat 的文件必须纯 ASCII**（批处理按 GBK 解析 UTF-8 中文注释会当命令执行，
  实测产生 `'3)'` 等报错）。后续所有模块改写只允许 ASCII 注释。
- 验证需在含 `System32` 的 PATH 下运行（`more` 依赖系统 PATH；本沙盒需临时追加
  `$env:SystemRoot\System32`）。

（原始 `PACKED_SAFETY.md` 已于 2026-08-23 并入本节，文件移除。）
