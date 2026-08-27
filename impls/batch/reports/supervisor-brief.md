# 监督交接简报（对抗性审查者 → 任意执行会话）

> 用途：执行会话（原「你好」对话，chatId=mta24zujvhnd4usr）因基础设施故障中断时，
> 新会话凭本文件 + `todo.md` + `reports/` 全部历史即可无损冷启动。
> 审查者：QwenWork 会话「审查，你好…」（本仓库外，由它持续下达轮次指令并实地复核）。
> 本文件最后更新：2026-08-27 09:05（第 6 轮进行中）。

## 1. 项目与目标

- `impls/batch`：用 Windows 批处理实现 MAL（Make a Lisp）。
- 总目标：step5 → step6 → step7 → step8 → step9 → **stepA**（自举评测器）。
- 每步验收标准：官方 `tests/stepN_*.mal` 全量通过（`_runall.py` 分块、**串行**、诚实贴 PASS 计数），一步一 commit+push（分支 `batch-ai-dev`），同时更新 `todo.md`。
- 优化项 #3/#5 推迟到 stepA 之后；stepA 的可行性以实测外推为准，不许猜。

## 2. 当前基线（已核实于远端）

- HEAD=`a4bf606`，`origin/batch-ai-dev` 同步。step0-4 官方全绿（step4 179/179，`cda4f29`）。
- step5 WIP 链条（全部已提交）：
  - `b56ce52` TCO 跳板 + **marker 生命周期 bug 修复**（根因：if/do/let* 使尾求值嵌套 ≥2 层，单跳上移不够；正解=摘除全部层级注册+循环显式管理生命周期）。浅例全绿：`f 3→0`、`sum2 10→55`。
  - `831e8c1` nsutil 门控槽位回收基础设施（NXFREE 弹出不自增 NSP；Free 门控压栈；`_T.FR.H` 单级展开修正）。常规路径惰性（step4 A 43/43 验证）。
  - `813ebd5` New/Clone/CloneMeta 初始化 `.RC=1`（惰性）。
  - `021eae5` **A 轮帧复用**：自尾递归（同 CapEnv+同 Binds 句柄）复用 env、参数轻覆盖，互递归安全回退重建。实测 NSP 斜率 **+67→+32/轮**，墙钟 **~26s→~9s/轮**，`sum2 50→1275` 实拿（wall 515s）。
  - `a4bf606` round5 分析：B1/B2 强耦合论证（见 `reports/round5.md`）。

## 3. 正在进行的第 6 轮：B 原子引用计数重构（审查者已批准的最高风险项）

设计定稿 = `reports/round5.md` 六落点 + 审查者追加的**两级验证序列**：

1. 一次性落地原子 `RCMODE` 开关（存储 incref / 覆盖 decref / 拆 Set+SetDirect+CloneBody 的 CloneMeta wrapper 放大 / Free 两式正确 DecRef / FreeNSBody 逐字段 DecRef / RC==0 真清 + 推 NXFREE / 销毁递归改工作队列 `_G.DESTROY`+Drain / decref 下穿 0 立即炸）。
2. **第一稳定态**：RCMODE=on + RECYCLE=off（只记账不回收，NSP 仍涨，语义须 100% 等价）→ 全绿 = 记账正确。
3. **第二稳定态**：RECYCLE=on（槽位复用入场，回收前必须清空 body 全部字段与 meta 残留键）→ 全绿 + `sum2 100` NSP 斜率 ≤+2/轮 = 复用安全。
4. 每稳定态各一个 commit；报告 `reports/round6.md` 入库。

定向新用例（先建后跑）：列表的列表整链释放；同一 meta 存两字段覆盖其一另一可读；逃逸闭包 plus5/plus7；TCO 内 `def!` 存参数值（已知限制，不得崩溃）。

B3 承接：第二态绿后 sum2 1000 实测 → 外推 10000（自递归/互递归分开）。**阈值 8 小时**：达标直接后台跑官方 step5 分块；超限则带 ①每轮跨文件 spawn 清单 ②PACKED-#8 微实验（热标签前置+控行数重打包，只测不提交；#1 naive PACKED 已实测更慢勿重蹈）回来裁决。互递归"按 Binds 句柄键控复用缓存"仅在重建路径外推超阈值时批准。

闸门顺序（两级各自都跑）：定向用例 → step4 A 43/43 → 闭包三用例/sumdown → step3 38 → step4 deferrable 分块。慢回归全程 ~1.5-2.5h，用后台+长超时。

## 4. 血泪坑清单（全部实测踩过，逐条有效）

- 回归**必须串行**：`%TEMP%\mal_f_!LEVEL!.txt` 等跨进程共享，并行必假 FAIL。跑前删 `%TEMP%\mal_*.txt` 陈旧枚举文件。
- Bash/编辑工具会把批处理文本里的 `>nul` 重写为 `>/dev/null`：构造含 nul 的文本用 `'2'+chr(62)+'nul'` 拼接。python 字符串里 `%TEMP%\xxx` 注意 `\n`/`\x` 转义污染（raw string 或 chr(92)）——历史上两次重大误判都源于此。
- 写 `.cmd` 探针必须 CRLF；块内 `>&2 echo` 会 rc=255，用 `>>file echo` 形式。
- **勿改 `nsutil.bat:437` 注释**（改注释文本会"执行新文本"）。`贝。Free` stderr 噪音是已知遗留，`_runall.py` 已分离 stderr。
- **禁止全局杀 cmd**（`Get-Process cmd | Stop-Process` 会误杀计划任务/其它会话）：Popen 记 PID，`taskkill /PID x /T /F`。后台任务禁止裸 `&`（会被 shell 退出带走），用工具的 run_in_background。
- step1 多表单在无控制台 pipe 下第一表单后断流（伴随 `贝。Free`）：环境 quirk，**不当闸门**；闸门参照物用 step4 A。
- 测试数字必须来自真实输出粘贴；审查者会在远端核对 commit、抽查复跑。"改了现象不变"连续两次 → 停下做最小可复现，不许叠改动赌。

## 5. 审查者复核方式（供新会话自查对齐）

- `git ls-remote origin refs/heads/batch-ai-dev` 对 commit 号；`git status` 对"工作区干净"声明。
- 抽跑浅例（`f 3→0`、`sum2 10→55`）验证"marker 修复完好"类声明。
- 长汇报一律以 `reports/roundN.md` 入库版本为准（消息通道 ~2000 字截断）。
- 执行会话历史可从 `AppData/Roaming/QwenWorkCN/data/agents.db` messages 表取全文。

## 6. 中断恢复协议（本次授权新增）

若执行会话再遇基础设施级失败（流超时 / All backends failed 等，且非任务内容问题）：
1. 审查者先核表现场（无半成品/无孤儿进程），再尝试续跑原会话一次。
2. 若再次失败，审查者直接**新建任务**，首条指令=「读 `impls/batch/reports/supervisor-brief.md` 与 `todo.md`，从第 N 轮最后一个 commit 继续，纪律不变」，并继续原轮次目标与验收标准。
3. 执行侧每轮铁律保证任意时点可弃：改动前基线必须已 commit；每个稳定态立即 commit。
