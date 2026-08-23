# _check.py 的 spec（step1 逐用例回归网关）

> 本文件与同名源码双向同步：改代码必须同步本文件，改本文件必须落实到代码。

## 用途

`_check.py` 是 MAL batch 的**逐用例回归网关**：以单进程有状态会话喂 `step1_read_print.bat`，
按官方 step1_read_print.mal 的「输入→预期输出」逐条比对判 PASS/FAIL，输出汇总统计。
是「多 commit+push 防进度丢失 + 每步回归守门」纪律的执行器。

## 对外接口

| 项 | 说明 |
|---|---|
| 调用 | `python _check.py <mal_file> <main_bat> [timeout]` |
| 输出 | 每用例如 `N OK/FAIL in=… exp=… got=…`，末尾 `PASS=.. FAIL=.. total=.. wall=..` |
| 终止符 | 以 `\r\nuser> ` 作为提示（TERM），首屏初始化提示 INIT_TERM |

## 边界与异常用例

| 用例 | 行为 |
|---|---|
| 超时（读不到 prompt） | 默认 120s；超时则调用 `resync()` 排空到下一个 prompt，避免后续用例流错位 |
| EOF | `read_until` 返回 EOF 标记，按已有缓冲判定，不无限等 |
| 空输入/注释输入 | 期望为无输出（`got='user>' exp=None`），走 `INIT_TERM`/`endswith(TERM)` 分支 |

## 依赖与影响面

- 依赖：`cmd` 子进程、`file_driver` 式会话保持；不含第三方库（除标准库）。
- 影响面：仅测试驱动，不进入运行产物；变更需以 job 全量 `PASS=121/121` 为守门标准。

## 变更记录

- 2026-08-23：默认超时 20s→120s；新增超时后 `resync()` 流重同步，解决列表/错误用例如 `FAIL t21..t23`
  的「got 为前一个输入残留」误判（job 1449 PASS=121/121 wall=336s）。