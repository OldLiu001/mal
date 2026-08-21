# MAL Batch 实现（Windows 批处理）

用纯 Windows CMD 批处理实现 Make-A-Lisp。当前分支：batch-ai-dev。
`bak/` 是老实现（step0–step3 通过官方测试）；本目录是新实现（从零重写，架构解耦，进行中）。

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
