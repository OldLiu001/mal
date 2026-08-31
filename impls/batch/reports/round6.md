# Round 6：B 原子引用计数重构（RCMODE）

日期：2026-08-27  
分支：batch-ai-dev  
基线：8e04a72（监督交接简报）
目标：round5.md 六落点 → 两级稳定态 → 深递归可行 + 槽位复用

## 一、原子 RC 设计（与 round5 修正案一致）

核心：单开关 `_G.RCMODE`（默认 off 保持逐字节旧语义，on 开新计数模型），
落点全部独立成函数，原函数仅前置一行路由 `if defined _G.RCMODE ( call :xxxRC ... )`。

| 落点 | 函数 | RCMODE=on 行为 |
|---|---|---|
| 存储+1 | SetRC / SetDirectRC | 存原句柄 + `IncRef`（替代 CloneMeta wrapper） |
| 覆盖-1 | SetRC / SetDirectRC | 覆盖旧字段 `DecRef`（替代 Free） |
| COW 克隆 | CloneBodyRC | 字段共享句柄 +1（不深拷 wrapper） |
| Free 两式 | FreeRC → DecRef | RC-1，RC==0 才真销毁 |
| 逐字段释放 | DrainDestroy（替代 FreeNSBody） | body 死亡时逐字段 DecRef |
| 销毁队列 | `_G.DESTROY` + Drain | 递归 teardown 改工作队列，规避 §1.7-2 再入 |
| 下穿断言 | DecRef | RC<1 立即 Fatal（decref underflow） |
| 槽位复用 | Drain（RECYCLE=on 时） | 相邻 (body,meta) 对压 NXFREE，仅 body 死亡才复用 |

计数模型：meta.RC = 引用数（注册引用 1 + 字段引用 N，GC 释放注册引用、覆盖/销毁释放字段引用）；
body.RefCnt 仍由 Clone 系列 meta 共享计数，body 归零时其字段全部 DecRef。

## 二、第一稳定态：RCMODE=on + RECYCLE=off（只记账不回收，语义须 100% 等价）

验证序列（严格串行，跑前清 `%TEMP%\mal_*.txt`）：

| 闸门 | 用例 | 结果 |
|---|---|---|
| step4 A 43/43 | `_t4_mand_a.mal` | POLL（RCMODE=on 492.41s, PASS=43 FAIL=0） |
| B-RC 定向深结构 | `_rc_deep.mal` | POLL（172.37s, PASS=5 FAIL=0） |
| 闭包函数 | `_step4_fntest.mal` | POLL（126.91s, PASS=5 FAIL=0） |
| 官方 step3 38 | `../tests/step3_env.mal` | POLL（首轮 600s 超时 @on；off 对照后台待验） |
| deferrable 分块 | `_t4_defer.mal` | POLL |

脚注：RCMODE=off 基线 step4 A = 421.05s 43/43（路由零回归）。

## 三、第二稳定态：RECYCLE=on（槽位复用 + sum2 100 NSP 斜率 ≤+2/轮）

待第一稳定态全绿后开跑。

## 四、提交与交付

- 第一稳定态 1 个 commit（RCMODE 六落点落地 + 第一态验证数据）
- 第二稳定态 1 个 commit（回收入场 + 斜率数据）
- 报告入库 `reports/round6.md` 并推送 batch-ai-dev