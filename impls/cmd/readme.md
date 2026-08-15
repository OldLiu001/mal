# CMD Impl - Design Document

## Overview

基于 Windows CMD 批处理脚本实现 MAL (Make a Lisp) 解释器。
利用 CMD 的管道机制和 `for /f` + `more` 的 stdin 捕获能力，
将每个处理阶段建模为独立的数据变换单元，
通过管道串联完成 READ -> EVAL -> PRINT 的完整流程。


## Core CMD Features

### 1. `for /f` + `more` 捕获 stdin

`more` 命令读取 stdin 直到 EOF，逐行输出。
配合 `for /f "delims=" %%a in ('more') do ...` 可以逐行捕获管道传入的数据：

```cmd
for /f "delims=" %%a in ('more') do (
    set "line=%%a"
    rem process line...
)
```

这是管道数据接收端的核心机制。
`writeall.cmd` 和 `readall.cmd` 已使用此模式。


### 2. `%*` 动态执行

在脚本开头放置 `%*`，传入的参数会被直接当作命令执行：
第一个参数作为 label 或命令名，其余参数作为其参数。

```cmd
@echo off
%*
```

调用 `script.cmd :SomeLabel arg1 arg2` 时，
等价于执行 `:SomeLabel arg1 arg2`。

利用此特性，一个 .cmd 文件可以同时充当多个角色的调度器：
- 无参数时进入默认入口 (REPL)
- 带参数时将参数作为指令执行

这使得脚本可以像函数一样被调用，实现模块化调度。


### 3. `set /p "=str"<nul` 不换行输出

`set /p` 原本用于交互式输入，但用 `<nul` 重定向空输入时，
它只输出提示字符串而不换行，也不等待输入：

```cmd
set /p "=user> "<nul
```

输出 `user> ` 后不换行，适合 REPL 提示符。
也可用于在管道中拼接不含换行的数据片段。


### 4. 管道数据变换

CMD 的管道 `|` 将左侧 stdout 连接到右侧 stdin。
每个 .cmd 脚本可以是一个数据变换单元：

```
echo "data" | transform1.cmd | transform2.cmd | output.cmd
```

数据在管道中以转义后的字符串形式流动，
每个阶段读取、变换、再输出。
这是整个 CMD impl 的架构基础。


## Architecture

### Data Flow

```
stdin -> readline.cmd -> [escaped string]
                              |
                              v
                         reader.cmd --> [token stream / AST]
                              |
                              v
                         eval.cmd -----> [result AST]
                              |
                              v
                         printer.cmd --> [escaped string]
                              |
                              v
                         writeall.cmd -> stdout
```

核心思路：将 MAL 的 READ-EVAL-PRINT 拆分为管道中的多个阶段，
每个阶段是一个独立 .cmd 脚本，
通过 stdin/stdout 传递转义后的字符串数据。


### Special Symbol Mapping

CMD 对以下字符有特殊处理，在管道传输前必须转义：

```
!  --- $E    (delayed expansion)
^  --- $C    (escape char)
"  --- $D    (quotation)
%  --- $P    (variable expansion)
$  --- $$    (escape sequence prefix itself)
```

转义在 `readline.cmd` 中完成，还原在 `writeall.cmd` 中完成。
中间管道阶段处理的全是转义后的安全字符串。


### Module Design

#### IO 层

- **readline.cmd** - 从 stdin 读一行，输出转义字符串
- **readall.cmd** - 从 stdin 读到 EOF，逐行输出转义字符串
- **writeall.cmd** - 从 stdin 读转义字符串，还原并输出原始文本

#### Reader 层

- **reader.cmd** - Tokenize + ReadForm，将转义字符串解析为 AST
  - Tokenize: 逐字符扫描，识别 `(` `)` `[` `]` `{` `}` `'` `` ` `` `~` `@` `~@` `;` 以及普通 token
  - ReadForm: 根据 peek 到的 token 决定解析为 list 或 atom
  - ReadList: 递归读取到 `)` 为止
  - ReadAtom: 读取单个 token，判断类型 (number / symbol / string / nil / true / false)

#### Printer 层

- **printer.cmd** - 将 AST 转回转义字符串输出

#### Eval 层 (后续 step)

- **eval.cmd** - 对 AST 求值

#### Main / REPL

- **step0_repl.cmd** - READ -> EVAL -> PRINT 循环
- **step1_read_print.cmd** - step0 + reader/printer 的完整实现

### 管道串联示例

REPL 单次循环的数据流：

```cmd
rem 1. 读取用户输入并转义
for /f "delims=" %%a in ('call readline.cmd') do set "Input=%%a"

rem 2. READ: 转义字符串 -> AST (通过变量传递)
call :READ "!Input!"

rem 3. EVAL: AST -> AST (step0/step1 直接返回)
call :EVAL

rem 4. PRINT: AST -> 转义字符串 -> stdout
call :PRINT
```

管道式变换 (概念):

```cmd
echo "!Input!" | reader.cmd | eval.cmd | printer.cmd | writeall.cmd
```


## Key Design Decisions

### 为什么用管道 + 转义？

CMD 的特殊字符 (`!`, `^`, `"`, `%`) 在变量赋值、`call` 传参、`for /f` 捕获时
行为不一致，容易丢失或被解释。
统一的转义方案确保数据在管道任意阶段都是安全的纯文本。


### 为什么用 `%*` 动态执行？

相比 `call :label arg1 arg2`，`%*` 方式更简洁：
- 脚本既是 REPL 入口，又是可被其他脚本调用的函数库
- 调用方只需 `call script.cmd :FunctionName args...`
- 无参数时自动进入 REPL 主循环


### 变量传递 vs 管道传递

当前实现中，阶段间数据主要通过变量 (ReturnValue) 传递，
管道主要用于 IO 层 (readline/writeall)。
后续可考虑将更多阶段改为管道串联，以减少变量命名冲突。


### 环境存储 (待定)

CMD 的 `setlocal` / `endlocal` 提供了作用域隔离，
但跨 `call` 的变量传递需要显式管理。
batch impl 使用全局变量名空间 (`_G.*`, `_L[level].*`) 和 NSUTIL 框架。

CMD impl 的环境存储方案待定，可能的方向：
1. 全局变量前缀命名 (`ENV_*`)，简单但不支持嵌套作用域
2. 模拟栈帧 (类似 step0_repl.cmd 中的 StackPush/Pop)
3. 临时文件存储环境数据


## Current Status

- [x] readline.cmd - stdin 读取 + 转义
- [x] writeall.cmd - 转义还原 + stdout 输出
- [x] readall.cmd - 多行读取 + 转义
- [x] step0_repl.cmd - 基础 REPL (Read=Eval=Print=identity)
- [x] step1_read_print.cmd - READ + PRINT (reader/printer 集成)
- [x] reader.cmd - Tokenize + ReadForm (部分实现，含单元测试)
- [ ] printer.cmd - 独立打印机模块
- [ ] types.cmd - MAL 类型系统
- [ ] eval.cmd - 求值器
- [ ] env.cmd - 环境存储
- [ ] step2_eval.cmd - 完整求值
- [ ] step3_env.cmd - 环境与符号查找


## File Structure

```
impls/cmd/
  readme.md          - 本文档
  spec.txt           - 特殊符号映射表
  readline.cmd       - stdin 读取一行 + 转义
  readall.cmd        - stdin 读取到 EOF + 转义
  writeall.cmd       - 转义还原 + stdout 输出
  reader.cmd         - Tokenize + ReadForm
  step0_repl.cmd     - 基础 REPL
  step1_read_print.cmd - READ + PRINT
  test/
    runtest.cmd      - 测试运行器
    runtest.log      - 测试日志
```


## Next Steps

1. 完善 reader.cmd 中的 ReadForm / ReadList / ReadAtom
2. 实现 printer.cmd (AST -> 转义字符串)
3. 实现 types.cmd (MalNum / MalSym / MalStr / MalLst / MalVec / MalMap / MalFn ...)
4. 实现 eval.cmd (step2)
5. 设计环境存储方案 (step3)
