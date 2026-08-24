# readall.bat 的 spec（stdin 多行→逐行喂 readline）

> 本文件与同名源码双向同步：改代码必须同步本文件，改本文件必须落实到代码。

## 用途

`readall.bat` 以 `for /f in ('more')` 从 stdin 读全部行，逐行经 `echo.<line> | call readline`
转成 ML 转义串喂给上层，是 `step3_env.bat MAIN_ReadAll` 批量驱动的输入源。解决 REPL 循环里
`for /f in ('call READLINE')` 只读第一行、后续 `set /p` 拿空的 stdin 多行复用障碍。

## 对外接口

| 项 | 说明 |
|---|---|
| 调用 | `readall.bat [RAW]` |
| `RAW` | 首位参为 `RAW` 时不加额外引号直接喂 readline，避免多余引号造成编码偏差 |
| 非 RAW | 镜像路径 `echo "%%a" | call readline` 显式加引号 |
| PACKED | 单文件分支直调 `"%~0" CALL_READLINE`，经打包入口转发头分发 |

## 边界与异常用例

| 用例 | 行为 |
|---|---|
| stdin 含 `>`（如测试 `;>>>` 指令行） | `echo.%%a|call readline` 会触发 cmd 重定向语法错误故不能由本层修复，由调用方 `_runall.py` 先行剔除 |
| 多行/空尾行 | more 逐行产出，空行照常传递；不吞尾行 |

## 依赖与影响面

- 依赖：`more`（需 PATH 含 System32）、`readline.bat`。
- 影响面：仅 step3 READALL 输入链路；改动以 38/38 计量回归为守门。

## 变更记录

- 2026-08-24：新增 `RAW` 参数，支持不加引号直喂 readline，解决带引号导致的转义编码偏差。