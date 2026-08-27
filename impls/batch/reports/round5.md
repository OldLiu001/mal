# 第 5 轮汇报（B1 尝试：发现 B1/B2 不可干净拆分）

## 基线核对
- 进入本轮 HEAD=`021eae5`（A 轮帧复用，已推远端）。
- 本轮**最终无代码提交**：nsutil.bat 编辑后回退（`git checkout`），现 == 021eae5，无 RCMODE/RC 残留。tracked 文件无改动。

## 做了什么（B1 尝试，主动止损）
按批准设计给 `NSUTIL_Free` 加 `RCMODE=1` 门控 DecRef。落地时撞到两处，判定"再叠改动=带病推进"，遂回退：

### 发现 1：meta `.RC` 读取有 reg-var / 直接句柄两式，写错即静默读空
Free 的入参有两种形态（与 `.Target` 完全一致）：
- 直接句柄：`%~1` = `_G.NS[7]` → RC 读 `!%~1.RC!`
- 层级 GC 的 reg-var：`%~1` = `_G.LEVEL[2][_G.NS[7]]` → RC 读 `call set "x=%%!%~1!.RC%%"`
我初版把两者混用一条 `%%!%~1!.RC%%`，对直接句柄会展开成 `%<空>.RC%`→读空→DecRef 判断失效（暗腐，正是"宁可炸不可暗腐"要避免的）。正确写法必须像现有 `.Target` 那样两分支。可修，但引出发现 2 才是要停下来的主因。

### 发现 2（决定性）：B1（拆 Set 的 CloneMeta wrapper）与 B2（DecRef 释放 + 回收）在语义上强耦合，无法各自独立"过闸即提交"
当前 wrapper 不只是"字段的值拷贝"，它同时承担两件正交职责：
1. **字段所有权**：每个字段持有**独立 wrapper meta**，覆盖字段时 `Free` 释放的是这个独占 wrapper → 绝不误伤被多字段共享的原对象。这正是"覆盖旧值 -1"能安全工作的前提。
2. **body 生命周期**：wrapper 的 `.Target` 指向原 body 并 `RefCnt+1`；`CloneBody`（COW，line 474）深拷贝字段时又对每个 NS 字段再 `CloneMeta`（line 426-428）。即 **body.RefCnt（meta↔body 共享）与 wrapper（字段↔值独占）是两套纠缠的引用系统**。

若按 B1 只"存原句柄 + RC+1、拆 wrapper"，则：
- 字段覆盖的释放（旧代码 `Free` 独占 wrapper）要同时改成"对原句柄 RC-1"——即依赖 B2 的 DecRef 语义；
- 且 `CloneBody` 的字段复制也必须改成"RC+1 原句柄"而非 CloneMeta；
- 且此刻还没有 B2 的工作队列销毁与 NXFREE 常态回收，DecRef 归零路径不完整会 double-free。
→ **B1 单独提交时，RCMODE=1 分支必然处于"拆了 wrapper 但释放侧未闭环"的中间态，跑闭包/step4 一定回退或暗腐**。硬凑成"绿"只能靠 RCMODE 默认 off 把新代码全旁路掉——那就是提交死代码，违背"每段过真闸"。

## 修正后的落地方案（请你复核 B 的分段）
建议把 **B1+B2 合并为一个原子 RC 开关**（`RCMODE` 一次性把存储 incref / 字段覆盖 decref / 层级 GC decref / FreeNSBody 递归释放 / CloneBody 复制 incref / RC==0 真清+推 NXFREE / 工作队列销毁 全带上），而非两段。理由：RC 模型的正确性依赖"每一个增减引用点都改到"，缺任一点即失衡；分段只会造出无法独立验证的中间态。
- 落地顺序（单轮内、门控默认 off，逐步打开做定点实验，不各自 commit 半成品）：
  1. New/Clone/CloneMeta：RC=1（已在 813ebd5）。
  2. Set/SetDirect：RCMODE 下——存原句柄 +1、覆盖旧值 DecRef、**不** CloneMeta；`CloneBody` 字段复制 +1（不 CloneMeta）。
  3. Free：两式正确 DecRef；RC==0 真清 + （RECYCLE 或常态）推 NXFREE。
  4. FreeNSBody：死体时逐字段 DecRef（去 wrapper 后字段直指原 meta）。
  5. 销毁递归 → 工作队列（`_G.DESTROY` 栈 + Drain），规避 §1.7-2 再入不安全。
  6. 断言：decref 下穿 0 立即 `%?|%` 炸。
- 验证门（RCMODE=1）：闭包三用例 + plus5/plus7 + sumdown → step4 A 43/43 → step3 38 → step4 deferrable → 全绿才 RCMODE 默认开 + 提交。

## 结论 / 请求裁决
- 本轮无代码入库（守住不带病推进）。
- 请确认：**B 改为"B1+B2 合并原子 RC 开关"**（我倾向此项）；若你坚持两段，我会在下一轮先交一个"仅 New/Clone/Set 全路径 RC 记账但回收仍走旧 wrapper 语义"的纯统计版（能过全部旧闸、且证明 RC 计数与实际引用吻合），再切释放——但这只是把风险后移，不如原子方案干净。
- 三问答案（① RC 挂 meta、并拆 CloneMeta-wrapper 存储放大，两套计数正交但需同改 CloneBody；② 各 DecRef/incref 落点见上；③ `_G.RCMODE` off=现状逐字节一致、on=RC，可二分）仍成立。

## B3 提醒已记
- 速度：A 后 sum2 自递归 ~9s/轮、残余 NSP +32/轮（B 才压平）；互递归走重建仍是 A 前水平。B 后需重测 sum2 100/1000 定外推，>8h 走"每轮调用清单 + PACKED #8 微实验"路线，不重蹈 #1 naive PACKED。
