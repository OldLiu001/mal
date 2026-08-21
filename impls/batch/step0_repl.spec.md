# step0_repl.spec.md

> 本文件与同名源码双向同步：改代码必须同步本文件，改本文件必须落实到代码。

## 用途

step0_repl.bat 是 Make-A-Lisp 的 step0 入口：建立 REPL（读取-求值-打印循环）。
此步不做真正的表达式求值——`MAIN_Eval` 与 `MAIN_Read` 都是恒等函数（读入原样透传），
`MAIN_Print` 直接写回。作用是把「UTIL/NSUTIL 基础设施 + 宏分发 + IO 管线」跑通一个
最小闭环，作为后续 step(reader/env/eval) 复用的样板。

## 对外接口

| 名称 | 签名/格式 | 说明 |
|---|---|---|
| `MAIN_Main` | `:MAIN_Main` | 入口：设 Prompt、进入 REPL 读-评-打循环 |
| `MAIN_REPL_Loop | 内联于 MAIN_Main 的 `for /l` 无限循环 | 反复 `Prompt→Read→REP→(空输入则退出)` |
| `MAIN_Read` | `:MAIN_Read Mal -> Mal` | 恒等读入：`set %%.Mal=!%~1!` 原样返回 |
| `MAIN_Eval` | `:MAIN_Eval Mal -> Mal` | 恒等求值：原样返回 |
| `MAIN_Print` | `:MAIN_Print Mal -> Mal` | 经 `IO WriteEncLine` 写出后返回 |
| `MAIN_REP` | `:MAIN_REP Mal` | 串联 Read→Eval→Print 与 `%->%` 取回 |
| 空输入 | REPL 读到空行 | `exit /b 0` 退出进程 |

## 关键行为与约束

1. **REPL 循环为 `for /l` 死循环**（`for /l %%i in (0 0 2147483647)`）包裹原括号块，
   使整个读-评-打循环体**只在进入时为解析器 parse 一次**，之后每次迭代执行已缓存命令，
   不再像 `goto` 回跳那样每轮重新定位标签并重解析。这是以「括号块 parse 一次」摊薄
   循环开销的优化（对照 cmd 性能实测：goto 循环比等价括号块 for 慢约 2.26 倍）。
2. 退出条件唯一：`ReadEncLine` 读到空输入（文件末尾 / 空行）→ `exit /b 0` 直接终止
   整个批次并返回调用者，退出前不回收任何东西（本步无持久对象）。
3. `%%.` 为「_L[level]. 前缀」占位循环变量（`for %%. in (_L[!_G.LEVEL!].)`），与外层
   `for /l %%i` 的迭代变量**区分命名**，避免嵌套 for 变量遮蔽。
4. 恒等求值：本步不解析 Mal 语法，任何输入原样 echo 回（含 `(` `)` 特殊字符），由
   `IO ReadEncLine` 的转义管线保证括号不在解析期裸嵌（见 readme 坑1）。
5. 不涉及：NS 创建/GC、类型系统、reader/printer、环境——均由后续 step 引入。

## 边界与异常用例（corner cases）

| 用例名 | 输入 | 预期行为/结果 |
|---|---|---|
| 空输入-退出 | EOF / 空行 | 打印 Prompt 后 `exit /b 0`，进程正常退出 |
| 单行普通值 | `123` | `user> 123`（恒等回显），继续等待下一行 |
| 列表字面量 | `(+ 1 2)` | `user> (+ 1 2)`（不解析不求值，原样透传） |
| 空列表 | `()` | `user> ()`（括号经转义管线安全透传） |
| 多行会话 | `1\n(+ 1 2)\n`（文件重定向） | 逐行 `user> <值>`，末行后退出 |
| 特殊字符 | `a"b!c^d%e` | 各特殊字符经转义/反转义后原样返回（语义一致） |

## 依赖与影响面

- 依赖：util.bat（宏/UTIL_Invoke）、nsutil.bat（初始化/LEVEL）、io.bat（ReadEncLine/
  WriteEncLine/WriteVar）、readline/writeall（转义管线）。运行方式：`step0_repl.bat < in.txt`。
- 影响面：仅 REPL 循环结构；对后续 step 的影响是确立「括号块 for/l 死循环」的样板写法。
- 谁依赖我：step1+ 的 REPL 入口沿此样板演进；性能基准对拍以此为 step0 计时基线。

## 变更记录

| 日期 | 版本 | 变更摘要 | 关联 commit |
|---|---|---|---|
| 2026-08-22 | 0.1.0 | 去 goto 化 REPL 循环：`:MAIN_REPL_Loop` + `goto` → `for /l` 死循环括号块，命中「goto 慢 2.26x」实测结论 | 待提交 |