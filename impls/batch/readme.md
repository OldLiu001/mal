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

## 6. 进度台账（2026-08-15）
- step0：24/24 官方 runtest 管道通过（早期）；file_driver 19/19。
- step1（step1_read_print.mal）：**109/109 全量通过（--all，含 deferrable）**；24/24 非 deferrable。
- 性能：子进程消除已落地；NSUTIL 直调优化为下一步。
- 遗留：.tmpbak 备份文件待清理；readme 待随 step2+ 持续更新。

TODO：
- [x] step1 全量（含 map）通过
- [ ] NSUTIL 热路径直调（性能 3-5x）
- [ ] step2_eval / step3_env / step4_if_fn_do / step5_tco（bak 可参照）
- [ ] step6_file ~ step9_try / stepA_self-host
- [ ] git 提交（注意 nul 文件）
