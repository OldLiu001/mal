# 批处理 MAL 实现 — 进度追踪

> 路径：`d:\_PubCodes\mal\impls\batch`
> 策略：`每一步 soft/可选 都实现 → 继续 → 推到 stepA 后再做优化（#3/#4）`
> 当前推进：step5_tco.bat（尾调用优化）

---

## 0. 当前主线状态

- [x] step0_repl.bat / step1_read_print.bat（含 step2 的向量/哈希求值等软特性）
- [x] step3_env.bat（环境、def!/let*/闭包基础，官方用例已验证通过）
- [x] **step4_if_fn_do.bat（2026-08-26 完成）** — let* 闭包环境捕获 bug 已修复（MLet 绑定与 RawKeyCount 全走 SetDirect，COW-free）；deferrable 全部实现（pr-str/str/println、prn/REPL 可读打印、变参 &、字符串转义、列表/向量序列相等）。**官方 step4_if_fn_do.mal 179/179 全通过**（分块 fresh 进程回归：强制段 87/87 + deferrable 92/92）。已提交推送（cda4f29）。
- [ ] **step5_tco.bat（阻塞：架构性内存限制）** — 尾调用优化。官方测试含 `(sum2 10000 0)`（10000 层尾递归）。**2026-08-26 深入调查结论：当前内存模型下不可行**（详见 §1.7/§1.8），需先做 #4 内存模型重构。TCO 跳板机制本身已验证可用（直接尾调用可无限循环），但 if 分支路径有 marker 生命周期 bug（未定位到根因，被架构性阻塞盖过）。

---

## 1. 关键发现（先记录，避免重复踩坑）

### 1.7 层级 GC 与内存生命周期实况（2026-08-26 修正定论）
- **更正**：早前"枚举重定向被 `2>nul` 吞掉、GC 静默 no-op"的结论**作废**——那批微测试被 python 字符串转义污染（`%TEMP%\xxx.log` 里的 `\x` 组合、f-string 的 `\v` 等）。干净复测 + 删除 mal_*.txt 后重跑验证：**util.bat 层级 GC、_L 清理、nsutil CloneBody/FreeNSBody 字段枚举在真实运行时全部正常工作**（mal_gc_*.txt 有内容）。
- **两个关键认知（#4 设计必读）**：
  1. **mal 层的"类型"是 body 字段**（`Data.Value[Type]=MalFn`），meta 自身的 `.Type` 只是结构标记（NSMeta/NSBody）。因此 `UTIL_SetRet` 的 `Type==NSMeta` promote 分支**对所有 mal 对象都命中**——返回值的层级注册本来就随调用链上移（所有权转移链完整、闭包跨表单存活实测成立）。
  2. `_T.<FN>.*` 临时域**函数级共享、非再入安全**：在 FreeNSBody 里递归释放字段 meta（→再入 Free→再入 FreeNSBody）会覆写外层 `%~1`/`_T.FR.NSBody`/`_T.FB.*` → 嵌套结构（列表的列表）释放必错。递归 teardown 前必须解决再入安全（独立槽位/显式工作队列）。
- **踩坑记录（工具层）**：给批次写探针 .cmd 必须 CRLF；python 字符串里 `%TEMP%\nsp.log` 的 `\n` 会被转义（用 raw string）；Bash 工具会把脚本内容里的 `>nul` 重写为 `>/dev/null`（构造含 nul 的批处理文本需用 `'2'+chr(62)+'nul'` 拼接）；块内 `>&2 echo` 会解析崩 rc=255，用 `>>file echo` 子程序形式。

### 1.9 #4 设计蓝图（下次会话可直接实施）
- **目标**：NSP 有界 → 深递归可行 + 环境表不膨胀（顺带解锁性能——当前 set 变慢的根因是单调膨胀的环境表）。
- **完整方案（引用计数）**：meta 加 `.RC`（NSUTIL_New/Clone/CloneMeta 初始 1=层级注册引用）；Set/SetDirect 存 meta 句柄时字段引用 `RC+1`（CloneMeta 包裹路径天然由 wrapper 承载）；覆盖旧值 / FreeNSBody 死体 / 层级 GC 释放时 `RC-1`；`RC==0` 才真正清 meta + 回收 (meta,body) 槽位对（空闲链表 `_G.NXFREE/_G.NSFREENEXT[]`，New 优先弹出、NSMAX 检查移入新分配分支）；SetRet promote=注册上移（RC 不变）。递归 teardown 需先解决 §1.7-2 的再入安全。**验证门槛**：step1→step2→step3→step4 分块全绿（~1.5h 回归/轮）。
- **低风险替代（step5 优先走这条）**：**循环局部回收**——TCO 循环在循环点显式 Free 本轮 env/keys/args/参数值（死亡由循环构造保证：仅被 env+args 引用），且**仅此显式路径**推空闲链表（全局 GC/Set 行为完全不变→step1-4 零风险）。每轮净增≈内层帧临时对象，若仍超限再扩到"水位+同形复用"。已知限制：参数值逃逸（循环体 `(def! saved n)` 跨轮读）会悬垂——官方 step5 用例不涉及，文档标注即可。
- 全量槽位复用曾实测破坏 step1（GC/Set 旧值释放的槽位仍被引用），印证完整方案必须先有正确 RC 与再入安全。

### 1.8 【step5 阻塞】NSMAX 单调上限 vs 10000 层尾递归（2026-08-26 实测）
- **每层递归调用消耗 ≈ 60 NS 槽位**（实测：`(sumdown 1)` NSP +126、`(sumdown 2)` +189 → 每多一层 +63；含 eager 实参求值、EnvCopyOuter 复制全局环境 ~30 键、`>`/`-`/`+` 各建结果 meta）。
- **NSMAX=8000 → 单进程最多 ~130 层尾递归**。`(sum2 10000 0)` 需 ~120K 槽位（即使 TCO 循环内复用 env/args，仅算术结果 meta 就 6 槽/层 = 60K）→ **架构性不可行**。
- 槽位复用（New/Free 加空闲链表，未配 RC 时）**实测破坏现有代码**（step1 立即崩）：GC/Set 旧值释放的槽位仍可能被其它层局部变量引用，复用槽位即改值 → 污染。**必须先做 #4**（见 §1.9 蓝图），这是 step5 的前置，工作量大且需全量回归。
- TCO 跳板机制验证：Eval 加 Tail 参数 + 尾位置 closure 调用改"登记全局 _G.TCO.* + 返回 marker" + ApplyClosure 循环驱动，**直接尾调用（函数体最后表单即自调用）可无限循环**（TCO 生效，无栈增长）；但 **if 分支路径的 marker 生命周期有 bug**（尾 Args 列表的 Target 在返回路径中被清空，禁用 promotion 与清理后仍复现——根因未定位，怀疑与 invoke 退出的 `_T` 清理/SetRet 交互有关）。step5_tco.bat WIP 已移入 .trash 备查。

### 1.6 step4 完成记录（2026-08-26）
- **let* 闭包 bug 根因（最终版）**：fn 的 Env 字段存的是 CloneMeta 包装器（冻结指向创建时 body）。let* 环境中 fn 被绑定后，环境因 RefCnt>1 被 COW 克隆（Target 105→142），包装器仍指向旧 body（无 f/x）→ 闭包读不到绑定。**修复 = MLet 绑定与 RawKeyCount 全走 SetDirect（COW-free）**：环境不再被克隆，包装器保持有效；同时保留包装器（GC 保活逃逸闭包）。已验证：let* 三用例（3/nil/0）、逃逸闭包（plus5→12、plus7→15）、递归（sumdown、fib）全过。
- **stderr 噪音「贝。Free」**（§1.4 旧案）：_runall.py 已 stderr 分离；**勿改 nsutil.bat:437 注释**（改注释文本无效，会执行新文本）。
- **回归必须串行**：`%TEMP%\mal_f_!_G.LEVEL!.txt` 等临时文件跨进程共享，**两个批次进程并行会互踩导致假 FAIL/断流**（实测 Block B 并行跑 PASS=10/44）。readme §6 已列为已知缺陷（"临时文件加进程唯一后缀"是 #4 期优化项）。
- **性能现状**：step4 单表单 ≈ 10-25s（首表单 47-60s），递归表单固有极慢（fib4≈205s、sumdown6≈154s）；92 表单 deferrable ≈ 886s、44 表单 ≈ 935s（含递归）。分块 fresh 进程回归是唯一可行姿势。

### 1.5 step4 强制段分块回归结果（已修复，2026-08-25 定位 → 08-26 修复）
- **Block A（_t4_mand_a.mal，43 表单）PASS=43/43**；**Block B（_t4_mand_b*.mal，44 表单）PASS=44/44**（B1 33 + B2 11，B2 含递归慢表单需 3600s 超时）。
- 旧 FAIL（已修复）：`(let* (f (fn* () x) x 3) (f))`→3、`(let* (cst ...)) (cst 1)`→nil、`(let* (f ... g ...)) (f 2)`→0。

### 1.1 「批量测试卡死」真相 = 级联变慢，不是死锁
- step3 单表单 `(+ 1 2)` ≈ 12s；step4 单表单 ≈ 22s（多出的 ~10s 是注册更多内建的初始化开销）。
- step4 首表单 ≈ 47~60s、后续每表单约 +6s，且随表单累积越来越慢 → #4「环境膨胀」在未优化阶段的暴露。
- 结论：靠 READTOEND 一次性读取 + 放宽容超时即可；Python/PS 的"卡死"多靠长超时 + 先写全输入再 `ReadToEnd` 解决。

### 1.2 读取/驱动正确姿势
- PowerShell 用 `ReadToEnd()`（阻塞式一次性读）稳定；逐行 `ReadLine()` 循环有伪超时，不要用。
- 大输入用 `READALL` 模式 + `readall.bat`（临时文件中转，规避管道共享 stdin）。

### 1.3 数值边界探针结论（step4 项，已验证）
- `(+ 1 2)→3` `(if true 7 8)→7` `(= 1 1)→true` `(< 1 2)→true` `(list 1 2 3)→(1 2 3)` `(empty? (list))→true`
- `(let* (a 5) a)→5` `((fn* (a b) (+ b a)) 3 4)→7` `(def! x 5)→5` 后 `x→5`
- `(sumdown 1)→1` `(sumdown 7)→28`（递归/闭包已修复）
- `(do 1 2 3)→3`；`not`：`(not false)→true (not nil)→true (not 0)→false`
- deferrable：`(pr-str "abc")→"abc"` `(str "a" 1 "b")→"a1b"` `(println "hello")→hello` `(prn "x")→"x"`
- `((fn* (& more) (count more)) 1 2 3)→3`；`(= [] (list))→true`

---

## 2. step4 实现现状（已完成，代码已提交）

### 2.1 已注册内置
- 算术：`+ - * /`（MAdd/MSub/MMul/MDiv）；比较：`= < > <= >=`（MEqual/MLess/MGreat/MLE/MGE）
- 集合：`list list? empty? count`（MList/MListQ/MEmptyQ/MCount）
- IO：`prn`（MPrn，可读）；deferrable：`pr-str`（MPrStr）、`str`（MStr）、`println`（MPrintln）、`not`（MNot）
- 特殊形式（参数不求值）：`def! let* fn* if do`（MDef/MLet/MFn/MIf/MDo）

### 2.2 关键机制（已就位）
- `MTruthy`：nil/false → 0，其余（含 `""`、`[]`、`0`）→ 1。
- `SameMal`：MalLst/MalVec 序列相等（类型可互等）+ MalMap 递归相等 + 标量按 Value。
- `ApplyClosure`：变参 `& more` 支持（扫描 binds 找 `&`，固定参数序绑 + 多余实参收集为列表）；参数序绑定 + `EnvCopyOuter` 复制外层。
- COW(NSUTIL_Set) 与直写 `NSUTIL_SetDirect`（def!/let* 绑定，保闭包引用语义）均已就位。
- 大小写敏感：EncKey 小写字母判定用 26 字母枚举 + `==`。
- 特殊字符符号编码（EncKey）：`!`→`$E`、`<`→`LT`、`>`→`GT`、`=`→`EQ`。
- 可读打印：PrintMalType Mode 参数（R=可读），PrintMalStr 剥 `$D` 定界符 + EscapeStr（`$D`→`\"`、`$N`→`\n`、`\`→`\\`）；reader 字符串转义 `\\`→`\`、`\"`→`$D`、`\n`→`$N`、`\X`→`X`；writeall `$N` 换行解码。

---

## 3. 官方测试对照

### 3.1 step4（step4_if_fn_do.mal）
- **179/179 全通过**（2026-08-26）：强制段 87/87（A 43 + B1 33 + B2 11）+ deferrable 92/92。
- 回归姿势：`python _runall.py step4_if_fn_do.bat _t4_mand_a.mal 2400 --readall`（A/B1/B2/defer 分块，**串行**跑，勿并行）。
- ⚠️ 正式测试运行期间不要 `Stop-Process cmd`（会误杀），等自然结束。

### 3.2 step5（step5_tco.mal，待实现）
- 尾调用：`(def! sum2 (fn* (n acc) (if (= n 0) acc (sum2 (- n 1) (+ n acc)))))`；`(sum2 10 0)→55`、`(sum2 10000 0)→50005000`。
- 互递归：`(def! foo (fn* (n) (if (= n 0) 0 (bar (- n 1)))))` + `bar` 类似；`(foo 10000)→0`。
- 深递归 10000 层：当前 `call :label` 递归链会爆（每层 ApplyClosure + EnvCopyOuter 复制外层环境），**必须实现 TCO**（尾位置自调用改循环）或等效方案（如 trampoline/循环化）。同时需要性能优化配合（否则 10000 层即使 TCO 也可能超时）。

---

## 4. 已知问题 / 阻塞

- **【step5 前置】深递归性能**：step4 递归表单 ~150-350s（fib4/sumdown6），step5 要跑 10000 层 → 必须先解决调用链成本（TCO 循环化 + 减少每层 EnvCopyOuter 复制）。这可能要提前做 #3/#4 的局部优化（见 §8 readme）。
- **临时文件跨进程冲突**（readme §6 已知）：回归必须串行；#4 期加进程唯一后缀修复。
- **stderr 噪音「贝。Free」**：_runall.py 已分离，勿改 nsutil.bat:437。
- step3 老实现 26/35（含 4 non-optional + 5 optional DEBUG-EVAL）→ 新实现（本目录）已超越，step3_dbg.bat 保留 DEBUG-EVAL。

## 5. 待办清单（按优先级）

- [x] **修复 let* 闭包环境捕获 bug**（2026-08-26：MLet 绑定/RawKeyCount 全走 SetDirect，COW-free）
- [x] **step4 强制段**：Block A 43/43 + Block B 44/44 = 87/87
- [x] **step4 deferrable**：pr-str/str/println + prn 引号 + 变参 & + 向量参数/字符串真值相等回归，92/92
- [x] **官方 step4 全量**：179/179（分块）
- [x] **提交并推送 step4**（cda4f29，batch-ai-dev → origin）
- [ ] **#4 内存模型重构（step5 前置，2026-08-26 判定为必需）**：修层级 GC 枚举的 `2>nul` 怪癖 + 真实引用计数/槽位回收（详见 §1.7/§1.8）。工作量大，需全量回归（step1-4）。
- [ ] **step5_tco**：TCO 跳板机制已验证可用（直接尾调用无栈增长）；#4 完成后修复 if 路径 marker 生命周期 bug，使 `(sum2 10000 0)`、`(foo 10000)` 通过。官方 step5 全量回归后提交。
- [ ] 继续 step6_file/step7_quote/step8_macros/step9_try/stepA_self-host，每级诚实回归后提交。
- [ ] 推达 stepA 后再做 #3（写时复制已知索引直写 / 内联 / 紧凑回收）、#5（reader 去 goto，高风险构造器重写）。（#4 已提前到 step5 前置。）

---

## 6. 涉及文件

- `step4_if_fn_do.bat` — step4 实现（1337 行）：内置注册、Eval 分发、ApplyClosure（变参）、SameMal、MLet/MDef（SetDirect）、可读打印。
- `reader.bat` / `printer.bat` / `str.bat` / `writeall.bat` / `io.bat` / `readall.bat` — 转义/可读打印/换行解码管线。
- `nsutil.bat` — NSUTIL_Set/SetDirect/CloneBody；`types.bat` — 类型构造。
- 测试：`_runall.py`（官方驱动，stderr 分离 + 提示符分组）、`_t4_mand_a/b1/b2/defer.mal`（分块回归夹具，串行跑）。
