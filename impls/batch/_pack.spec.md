# _pack.py 的 spec（MAL batch 单文件构建器）

> 本文件与同名源码双向同步：改代码必须同步本文件，改本文件必须落实到代码。

## 用途

`_pack.py` 把 MAL batch 多模块（util/nsutil/reader/printer/str/types/env/io + 入口）
concat 成单个 `mal_packed.bat`，并把模块内 `call NSUTIL :X` / `call UTIL :X` 改写为同文件 `call :X`，
从而在单进程内完成宏分发，作为「消除跨文件子进程」实验（readme §8.2.1 #1）的载体。

## 对外接口

| 项 | 说明 |
|---|---|
| 调用 | `python _pack.py step1_read_print.bat mal_packed.bat` |
| 输出 | 生成 `mal_packed.bat`；`REALDLINE/WRITEALL` 以 `CALL_READLINE/CALL_WRITEALL` 子函数转发 |
| 产物 | 未跟踪构建产物（不复用为版本文件），以非 packed 主路径为唯一门禁 |

## 边界与异常用例

| 用例 | 行为 |
|---|---|
| 头部 FAST 时序 | **头部必须在 `call :NSUTIL_Init` 之前 `set _G.FAST=1`**；否则 UTIL_Init 走非 fast 分支、冗余 assert 生效，reader 单进程下误报 `'NS' undefined` |
| 头注释编码 | 生成头**禁止含非 ASCII 中文注释**——cmd 按非 CP936 字节解析多字节会把注释行拆成伪命令（如 `'st'`/`'程下误报'` is not recognized） |
| 非 PACKED 分支 | `io.bat` 的裸 `call READLINE`/`call WRITEALL` 仅 _G.PACKED 未定义时生效，改写必须避开 |

## 依赖与影响面

- 依赖：`core` 列表模块 + 入口；仅标准库。
- 影响面：只产生 `mal_packed.bat`；非 packed 主路径源码与运行不受影响。

## 变更记录

- 2026-08-24：头部在 `NSUTIL_Init` 前 `set _G.FAST=1`，修复 packed 一进 reader 就报 `'NS' undefined` 的初始化顺序 bug；
  生成头保持纯 ASCII，规避中文注释被 cmd 误解导致产物崩溃。