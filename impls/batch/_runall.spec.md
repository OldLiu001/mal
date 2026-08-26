# _runall.py 的 spec（batch 官方用例批量回归网关）

> 本文件与同名源码双向同步：改代码必须同步本文件，改本文件必须落实到代码。

## 用途

`_runall.py` 是 MAL batch 的**批量官方用例回归网关**：解析 `*_step*.mal` 测试文件，
把全部输入表单经 stdin 一次喂给主 bat（READALL 模式）或交互喂 REPL（PROMPT 面符号），
逐条比对输入→期望输出，输出 PASS/FAIL 汇总。与 `_check.py`（单进程有状态）互补。

## 对外接口

| 项 | 说明 |
|---|---|
| 调用 | `python _runall.py <step.bat> <test.mal> [timeout] [--readall]` |
| `--readall` | 各输入表单逐条输出；DEBUG-EVAL 追踪的 `EVAL: ...` 行按前缀归并到当前表单的下一结果行 |
| 输出 | 逐 FAIL 明细 + 末尾 `PASS=.. FAIL=.. total=..` |

## 期望解析规则

| 行形式 | 处理 |
|---|---|
| 裸 `;` 开头（含 `;>>> deferrable/soft/optional`） | **跳过**，不作为输入也不作期望 —— 否则喂进 REPL 的 `>>>` 会触发 readall 重定向语法错误并错位所有输出 |
| 紧跟输入的 `;=>值` | 精确相等断言 |
| 紧跟输入的 `;/regex/` | **真实正则断言**：以 `re.DOTALL` 匹配（跨行，吸收递归 DEBUG-EVAL 的 `EVAL:` 子行），不再跳过 |
| 连续无讨论期望的真实输入行 | **各自独立成测试**（原解析器会吞掉后续行导致计数偏少）|

## 边界与异常用例

| 用例 | 行为 |
|---|---|
| 无 prompt（非 READALL 模式）| 报错退出 |
| 输出不足（< 输入数） | 缺省的 out 置 `<MISSING>` 判 FAIL |
| 期望为浮空 `;=>` | 期望空输出 |
| READALL 多行结果 | 批次在每个表单 REP 前输出 `user> ` 提示符；解析器按提示符切分，把每个表单的全部输出（prn/println 副作用行 + 结果行 + DEBUG-EVAL 的 `EVAL:` 行）归并为**一个**结果（无提示符时回退旧逐行分组） |
| stderr 输出 | **分离捕获，不并入结果解析**：cmd 层间歇性噪音（`call set` 重解析吞下一行注释 → `'贝。Free' 不是内部或外部命令`）会污染结果对齐；stderr 字节数打印提示并转储 `_runall_stderr.log` 供诊断 |

## 依赖与影响面

- 依赖：标准库 re/subprocess/time；`readall`/主 step bat 的 READALL 输出（仅 stdout）。
- 影响面：仅测试驱动，不进运行产物；以 step3_env 全量 `PASS=38/38` 为守门。

## 变更记录

- 2026-08-25：README 结果提取改为**按 `user> ` 提示符切分**——批次 `MAIN_ReadAll` 每表单 REP 前
  打印提示符，多行输出（prn/println 副作用行 + 结果行）归并为单结果，修复 prn/do 表单导致的
  逐行分组错位（Block B t27+ 假 FAIL 的根因）；无提示符时回退逐行分组。

- 2026-08-25：stderr 改为分离捕获（`stderr=PIPE`，不再 `STDOUT` 合并）——修复间歇性
  `'贝。Free' 不是内部或外部命令`（cmd `call set` 间接展开在值含特殊字符时把下一行注释吞进
  重解析命令所致，纯 stderr 噪音，stdout 结果始终正确）对 READALL 结果对齐的污染；
  同时日志化 stderr 字节数与转储 `_runall_stderr.log`。

- 2026-08-24：`;/regex/` 从「跳过断言」改为**真实正则断言**（re.DOTALL 跨行匹配），使 soft/可选
  的 DEBUG-EVAL 用例不靠放行而真实通过；READALL 结果提取增加「`EVAL:` 前缀行归并到当前表单」
  的多行分组，适配递归 DEBUG-EVAL 追踪；此前跳过逻辑仅作过渡。step3 全量以真实断言 PASS=38/38。

- 2026-08-24：解析器重写 —— ①跳过裸 `;` 指令/注释行，②每个真实输入行独立成测试，
  ③`;/regex` 按跳过断言；期望比较兼容 `;=>` 与 `;/` 两种前缀。消除 READALL 输出错位
  与计数偏少的 20/38 假象，恢复 38/38。