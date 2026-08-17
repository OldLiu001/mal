# mal2 GNU m4 Lisp 实现静态分析报告

> 静态分析 + 实测交叉核验 | 2026-08-17 | 只读分析,未改动源码
> 对象:`impls/m4/`(GNU m4 1.4.6)。本文档同时作为 impls/m4 的待办清单(todo)存档。

## 执行摘要

mal2 的 m4 实现是 Make-A-Lisp(MAL)在 GNU m4 宏处理器上的完整移植,数据是字符串、程序是宏、执行是宏展开,由 driver + step 文件 + 全局宏传态构成。整体链路(reader 编码、EVAL 链、环境、quote、宏、try/catch)在实测范围内工作正常:step1 121/121、step9 173/173、stepA 0 硬失败(35 软失败集中在 metadata 相等性)。但静态分析发现三类核心问题:

| 维度 | 核心结论 | 优先级 |
|---|---|---|
| 架构缺陷 | 全局宏 `__F/__A` 命名冲突造成功能错误;无 TCO 且环境查找二次方,`sum 1000` 需 32s;prn/slurp/load-file 三向量可命令注入;try* 吞掉非 throw 错误违反 MAL 语义 | 先修 #3 安全 |
| 内存回收 | m4 1.4.6 重定义同名宏会释放旧值(200K 次重定义 RSS 仅 3.1 MiB),"define 泄漏"不成立;真问题是 env/atom 符号表单调增长 + 每轮 REPL ≥3 个子进程 + 同名重定义疑似 O(n²) 退化(200K 次 7min+ 未完成) | 优化聚焦"少符号+少子进程" |
| 代码质量 | 复制本身符合 mal 官方自包含约定、不是缺陷;但工作树 step4~step8 五文件字节级相同破坏"增量"属性、头部注释全错标 step9,是首要修复项。零风险+低风险改善合计约 1.6 人日;抽公共库/栈帧重写等大重构在 m4 1.4.6 约束下不建议 | 零风险项立即执行 |

**最值得注意的现场事实:** git 提交版 step0~step9 是逐步递增且各自通过官方测试的;当前工作树(12 文件 Modified 未提交、stepA 与自述.md 未跟踪)已被一次未完成的重构同质化——step4 已出现 1 个超时回归,stepA 与 step9 之间还存在修复回退(eq_map/del_keep2/map_dedup)。自述.md 与当前代码有 4 处以上不一致(readline 阻断描述已过时、read -t 修复不存在、repline 改名、PR/NL 顺序)。

---


## 实现概况与实证基线

mal2 的 m4 实现是 Make-A-Lisp（MAL）在 GNU m4 宏处理器上的移植，位于 `/Users/oldliu/Documents/mal2/impls/m4/`：数据是字符串、程序是宏、执行是宏展开。reader 把 `(` `)` `,` `#` 转义为控制字符 `\x0e`–`\x11`（reader.m4 中 `LP/RP/CM/HS`，经 `format(%c,14..17)` 生成）以穿过 m4 的括号解析，EVAL 链、环境、TCO、quote、宏、try/catch 全部以 `define`/`defn` 宏展开实现：EVAL 在编码后的规范打印串上操作（step2/step3/step9 头注释均明确此点），环境为顺序绑定表 `__E<id>_C` + 按 ID 取槽的宏，值传递靠全局宏 `_l` 配合 `defn` 取态。运行环境为 macOS 自带 `/usr/bin/m4`（GNU M4 1.4.6），由 `run` 脚本 `sed` 替换 `driver.m4.in` 中的 `__STEP__` 后 `exec m4 -I "$dir" -L 2000` 驱动——`-I` 使 `include(reader.m4)` 可解析、`-L 2000` 限制嵌套展开深度。以下基线均为 2026-08-17 在该环境实测，后文所有缺陷与改善讨论以此为准。

**表 1-1 文件结构与规模**

| 文件 | 规模 | 职责 |
|---|---|---|
| driver.m4.in | 8 行 | REPL 主循环：`repline` 读行、`mainloop` 裸递归、`NL()`/`PR()` 换行刷新；经 `run` 用 sed 替换 `__STEP__` 后成为驱动 |
| run | 13 行 | 启动脚本：`STEP` 环境变量选步、sed 生成临时文件、`exec m4 -I "$dir" -L 2000` |
| reader.m4 | 90 行 | tokenizer/reader：控制字符编码与 `read_str`/`canon`；被各 step 第 11 行 `include(reader.m4)dnl` 引用 |
| step0_repl.m4 | 16 行 | REPL 骨架（READ/EVAL/PRINT/REP 入口，循环在 driver） |
| step1_read_print.m4 | 11 行 | READ 解析为规范打印串，EVAL/PRINT 恒等 |
| step2_eval.m4 | 121 行 | EVAL 在编码后的规范串上求值 |
| step3_env.m4 | 183 行 | 环境：顺序绑定表 `__E<id>_C` |
| step4~step8 | 各 574 行 / 92094 B | 工作树内五文件 MD5 完全相同（见下），文件头均为「step9」字样，已不体现各自增量职责 |
| step9_try.m4 | 578 行 | try*/catch*/throw + core fn registry |
| stepA_mal.m4 | 592 行 | 完整实现：core 注册（readline/time-ms/seq/conj/atom/with-meta/meta）、`defmacro! cond` bootstrap |
| tests/ | 空目录 | 无本地测试（total 0） |

**测试与运行基线（实测）**

官方 runtest.py 回归：step1_read_print 121/121 通过；step4_if_fn_do 141 通过 / 1 超时失败（line 366 `(pr-str (list 1 2 "abc" "\\"") "def")`，嵌套引号转义场景，根因未定位）/ 57 跳过；step9_try 173/173；stepA_mal 0 硬失败 / 35 软失败（集中在 metadata/`with-meta` 相等性）/ 78 通过 / 0 跳过。step2/3/5/6/7/8 未跑回归（状态未核实；因工作树五文件相同，step5~step8 结果可能接近 step4，属推断）。

启动基线：`/usr/bin/time -l` 3 次取中位数，real ≈ 1.00 s、user ≈ 0.21 s、sys ≈ 0.38 s、max RSS ≈ 2543616 B（≈ 2.43 MiB），启动后立即 EOF 退出。

**三个必须讲清的事实**

1. **工作树 step4~step8 同质化**：五文件 MD5 完全相同（`9f68dba4f31e714018d75dcc6b4b0301`），step4 文件头注释已写成「step9 - try*/catch*/throw + core fn registry」；而 git 提交记录中五步为逐步递增、MD5 各异（committed step5 无 TCO 相关宏）。「每步最小增量」的官方组织方式在工作树中被破坏，step4 回归（1 个超时）正发生在这一重写之后。
2. **git 状态未收尾**：impls/m4 下 12 个已跟踪文件全部 Modified（1919+/520-），stepA_mal.m4 与 自述.md 未跟踪；自述 §8 所述收尾动作（add/commit/push）未发生。
3. **自述.md 与当前代码多处不一致**：§8「readline 阻塞 → 111 个雪崩跳过」「已改 `read -t 1`」不成立——全仓库 grep `read -t` 零命中，stepA 的 `ev_readline` 仍是阻塞 `if IFS= read -r line`，但实测 stepA readline 测试通过、0 跳过，即 §8 描述的阻断在当前工作树不复现；§5.2 称「PR() 后紧跟 NL()」，实际 driver 中 `NL()` 在 `PR()` 之前（`...NL()PR<<<>>>mainloop`）；§3.1 所附 driver 代码的宏名 `readline` 已改名 `repline`（git diff 证实）。此外 reader.m4:8 注释仍写 `\x01 \x02 \x03`，与代码实际的 `\x0e`–`\x11` 不符；stepA 的 `ev_timems` 经 `esyscmd` 调用 perl（Time::HiRes），自述 §7.6 未记录这一外部依赖。


---

## 架构缺陷分析

本章对工作树实现（`impls/m4/`，GNU m4 1.4.6）做静态缺陷梳理，共 15 条：高 4、中 5、低 6。文中所引行号均指工作树文件；凡"复现"仅为静态推演而非实测的，标注"预期复现"；可直接执行的复现命令保留素材原文。核验口径说明：git 提交版与工作树存在差异（如提交版 step5 与 step4 MD5 不同、工作树五文件相同），相关表述均按工作树现状给出并注明差异。

### 2.1 缺陷总表

表 2-1 按严重度排序（编号沿用素材 #1–#15，低严重度条目详见 2.2/2.3 之后的说明）。

| 编号 | 缺陷 | 严重度 | 一句话影响 | 代码位置 |
|---|---|---|---|---|
| #1 | 全局宏 `__F`/`__A` 命名冲突 | 高 | 嵌套函数调用重定义共享全局寄存器，`cons`/`map` 等产生错误结果 | step4:116 ev_la47、step4:147 ev_cons2、step4:433 ev_map2 |
| #2 | 无 TCO + 二次方环境查找 | 高 | 尾递归 1000 次需 32s，深度受 `-L 2000` 制约，远超此层报错 | step4:373-378 apply_closure、step3:29-31 env_gs |
| #3 | syscmd/esyscmd 命令注入 | 高 | 经 prn/slurp/load-file 三个向量执行任意 shell 命令 | step4:281 ev_prn、step4:316 ev_slurp2、step4:319 ev_load_file2 |
| #4 | try* 捕获所有错误（非只 throw） | 高 | 符号未找到等非 throw 错误被吞掉，违反 MAL 语义 | step4:425-430 ev_try/ev_try2、step4:50 err_symbol |
| #5 | stepA 回归 step9 修复 | 中 | eq_map/map_dedup 等修复被回退，with-meta 硬编码 REPL_ENV 破坏词法作用域 | stepA:246 eq_map、stepA:518-534 ev_withmeta |
| #6 | esyscmd 重扫破坏 slurp/load-file | 中 | 文件含 `)` `(` `,` 时 define 参数收集损坏，ERROR 退出 | step4:316 |
| #7 | load-file 注释剥离侵入字符串 | 中 | 字符串内 `;` 及之后内容被删，文件损坏 | step4:320 ev_load_file2 |
| #8 | 错误全局态保存/恢复不全 | 中 | `__ERRMSG` 未保存恢复；ev_*_elem 循环遇错不自停、静默丢元素 | step4:425-426 ev_try2、step4:189 ev_as_elem |
| #9 | 环境 ID 无限增长（无回收） | 中 | 每次函数调用/atom 新建永久宏，长期 REPL 宏表泄漏 | step4:27 env_new、step4:334 __ATM_CTR |
| #10 | 控制字符编码方案脆弱 | 低 | 用户数据含 \x0e-\x11 时与结构编码冲突，round-trip 损坏 | reader.m4 ENC/DEC、step4:424 ev_throw_val |
| #11 | 单文件 92KB 自包含 + 5 份 MD5 相同副本 | 低 | 修改需同步 6 文件；step9/stepA 已各自分叉 | step4-8 五文件（MD5 9f68dba4…） |
| #12 | EOF 哨兵碰撞 | 低 | 用户输入 `EOF` 触发 REPL 退出 | driver.m4.in:2 repline、driver.m4.in:5 mainloop |
| #13 | ev_mal_eval 使用 __ROOT_ENV | 低 | `(eval ast)` 在 root 环境而非当前环境评估 | step4:313 ev_mal_eval |
| #14 | -L 2000 递归深度限制 | 低 | 长字符串/深层嵌套解析/深递归中止（m4 报错后 REPL 继续） | run 脚本、step4 pa_scan/ev_token 逐字符递归 |
| #15 | 重复绑定 `throw`/`>`/`>=` | 低 | REP 初始化同一符号 env_set 两次，冗余无害 | step4:26 REP 定义行 |

### 2.2 高严重度缺陷

**#1 全局宏 `__F`/`__A` 命名冲突（功能错误）。** ev_la47（step4:116）在每次普通函数调用时执行 `define(<<<__F>>>, ev_form(<<<$1>>>, <<<$3>>>))`。这一"define → 立即 defn"惯用法依赖一条不变量：define 右侧的嵌套 ev_form 执行期间不得重定义同一个全局——单层调用下成立，因为 define 最终把正确值写回。但 ev_cons2（step4:147）与 ev_map2（step4:433）采用 `define(__A) → define(__B, ev_form(...)) → defn(__A)` 的串联模式：第二个 define 内的嵌套 ev_form 若走 ev_la47/ev_bp2 路径，会重定义 `__A`/`__F`，而外层 define 不再写回，之后的 `defn` 读到被覆盖的值。预期复现（需先定义辅助符号）：

```
(cons 1 (f 7 8))  →  (8) 而非 (1 7)   # __A 被 f 的参数绑定覆盖为 8
(map inc1 (mk))   →  ((1 2 3) (1 2 3) (1 2 3)) 而非 (2 3 4)  # __F 被 (mk) 的 ev_la47 覆盖
```

**#2 无 TCO + 二次方环境查找（性能）。** 口径（经交叉核验修正）：工作树 step5_tco.m4 与 step4 字节相同（MD5 `9f68dba4f31e714018d75dcc6b4b0301`）；git 提交版 step5 与 step4 虽 MD5 不同，但提交版同样不含任何 TCO 相关宏（grep tco/trampoline 零命中），apply_c6 仍是裸递归 `ev_form`。因此无论提交版还是工作树版，TCO 均未实现。step4:373-378 apply_closure 走 `apply_c6 → env_new → bind_params → ev_form(body, newenv)`，无 trampoline 循环；step3:29-31 env_gs 从 `C-1` 向下扫描到 0 再递归外层，深度 d 的环境每次查找 O(d)，函数调用整体呈二次方。素材实测：`sum 1000 0` 返回 500500 但耗时 32s（`sum 100` 已需 4.7s），`sum 3000 0` 超 40s 被 SIGTERM；每个 MAL 调用约消耗 10–15 层 m4 宏展开，按每个 MAL 调用消耗 10–15 层 m4 展开推算，`-L 2000` 约只对应 150–200 次 MAL 递归。

（口径补充：step2/3/5/6/7/8 未跑回归测试，本章缺陷定位均基于静态分析，不依赖回归状态。）

**#3 syscmd/esyscmd 命令注入（安全）。** 三个注入向量均为 shell 字符串拼接，值/文件名以单引号包裹且不做任何转义：ev_prn（step4:281）`syscmd(<<<printf '%s\n' '>>>DEC(defn(<<<__PO>>>))<<<'>>>)`；ev_slurp2（step4:316）与 ev_load_file2（step4:319）`esyscmd(<<<cat '>>>__SLF<<<'>>>)`。值内嵌 `'` 即可闭合引号注入命令。复现（素材原文）：

```
(prn "'; touch /tmp/M4PWN; echo '")     → 文件 /tmp/M4PWN 被创建
(slurp "'; touch /tmp/M4PWN2; echo '")  → 文件 /tmp/M4PWN2 被创建
```

**#4 try* 捕获所有错误（语义偏离 MAL 规范）。** ev_try2（step4:425-426）以 `__ERR` 是否为 1 判定捕获，而 `__ERR` 同时被 err_symbol（step4:50，"符号未找到"）与 ev_throw_val（step4:424，throw）置 1——错误通道不区分来源。MAL 规范要求 try* 只捕获 throw 抛出的异常，其余错误应传播。复现：

```
(try* abc (catch* exc (prn "exc is:" exc)))
→ 打印 "exc is:" "abc not found" 并返回 nil（正确行为：应报错 "'abc' not found"）
```

### 2.3 中严重度缺陷

**#5 stepA 回归 step9 修复。** step9→stepA 的 diff 显示：eq_map 的 strip_meta 修复被回退（step9:246 有，stepA:246 无）、del_keep2 分解与 map_dedup 定义被删除；ev_withmeta 完全重写（stepA:518-534），以 `defn(<<<__REPL_ENV>>>)` 硬编码替代 `$3` 词法环境参数，另有 8+ 处同样替换（ev_read_string2、ev_slurp2、ev_load_file2、ev_atom2 等）。预期复现：`(let* [v [1 2]] (meta (with-meta v {:a 1})))` 在 stepA 返回空（v 在 REPL_ENV 中找不到）。此与交叉核验实测"stepA 35 个软失败集中于 metadata/with-meta 相等性"相互印证。

**#6 esyscmd 重扫损坏 slurp。** GNU m4 1.4.6 在 define 参数收集期间会重扫 esyscmd 输出（自述.md §4.8 确认），slurp/load-file 直接把输出当 define 参数且未防御。复现：`echo "abc)def(ghi" > /tmp/t.txt` 后 `(slurp "/tmp/t.txt")` → `ERROR: end of file in argument list`。

**#7 load-file 注释剥离侵入字符串。** step4:320 用 `patsubst(__LFB, <<<;.*>>>, <<<>>>)` 剥离注释，正则不区分 `;` 在字符串内外。复现：`echo '(def! x "a;b")' > /tmp/t.mal` 后 `(load-file "/tmp/t.mal")` → `ERROR: end of file in argument list`。

**#8 错误全局态保存不全。** ev_try2（step4:425-426）只保存/恢复 `__ERR` 与 `__ERRVAL`，不保存 `__ERRMSG`，恢复后残留 try 体内旧值；ev_as_elem（step4:189）、ev_vb_elem（step4:200）、ev_mb_join（step4:219）的循环中 `__ERR=1` 时不中止，静默丢弃出错元素。

**#9 环境 ID 无限增长。** env_new（step4:27）每次调用令 `__ENV_CTR` 只增不减，每次函数调用创建 4 个永久宏（`__E<id>_C/_N/_V/_O`）；`__ATM_CTR`（step4:334）同理。全代码 0 处 undefine，长期 REPL 会话宏表持续增长、无回收（内存回收可行性详见第 3 章）。

低严重度条目补充说明：#10 控制字符编码（reader.m4:36-41）把 `(` `)` `,` `#` 编码为 \x0e-\x11，用户数据若含这些字节会被 DEC 误解码，且 reader.m4:8 注释仍写 \x01-\x03、与代码不符；#11 step4-8 工作树五文件字节相同（MD5 `9f68dba4…`，交叉核验实测成立），step9 与 stepA 各自独立修改，维护者需同步 6 份文件或接受分叉；#12 driver.m4.in:2 repline 在 stdin 读到 EOF 时返回字符串 `EOF`，mainloop（driver.m4.in:5）据此判定退出，用户输入 `EOF` 被误判为退出；#13 ev_mal_eval（step4:313）将 AST 在 `__ROOT_ENV` 中二次评估而非当前环境，多数场景无可见差异，但依赖环境绑定的宏定义场景可能出错；#14 run 脚本 `-L 2000`，reader 的 pa_scan 与 ev_token 逐字符递归，约 2500 字符的字符串解析即触发 `ERROR: recursion limit of 2000 exceeded`；#15 step4:26 REP 初始化中 `throw`、`>`、`>=` 各 env_set 两次，第二次覆盖同值，冗余无害。

### 2.4 根源性诊断

| 根源 | 关键证据 | 根本解方向 |
|---|---|---|
| 1. 全局态是 m4 图灵完备用法的必然，但缺约束机制 | m4 1.4.6 在 changequote(<<<,>>>) 下递归无法传参（自述.md §4.6），EVAL 链被迫用全局宏当寄存器（`__F`/`__A`/`__V`/`__C` 等）；header 注释"Accumulated results travel as macro ARGUMENTS, never through globals"仅在 define→立即 defn 单层模式下成立，ev_cons2/ev_map2 的串联模式破坏该不变量（#1） | 为每个需跨嵌套 eval 保持值的全局分配唯一名（如 `__CONS_A` 独立于 `__BP_A`），或用 `indir` + 动态名实现寄存器重命名 |
| 2. esyscmd 重扫未防御 | m4 1.4.6 的 esyscmd 输出在参数收集期间被重扫是已知行为（自述.md §4.8），slurp/load-file 未做任何转义（#6、#7） | esyscmd 内对输出做 base64 编码、m4 侧解码；或改用 syscmd + 临时文件规避重扫 |
| 3. 单文件推到底的演进遗迹 | step2(121 行)→step3(183 行) 渐进构建后，step4 一次性吸收 step5–A 全部功能（try*/macroexpand/readline/time-ms/conj/seq/metadata 均在 step4），step5–8 纯复制（工作树五文件 MD5 相同）；step9 与 stepA 各自独立修改形成分叉并发生修复回退（#5） | 抽共享代码为 common.m4，step 文件只 include 并定义增量 |
| 4. 错误通道是带外全局变量，无栈帧 | `__ERR`/`__ERRMSG`/`__ERRVAL` 靠 try* 手动保存/恢复模拟栈帧，但保存不全（缺 `__ERRMSG`，#8）且来源不分（throw 与符号错误共用 `__ERR`，#4） | 每个 may-error 宏返回带错误标志的复合值（`OK:value` / `ERR:msg`），调用方显式检查 |

综上：四大高严重度缺陷分别对应功能正确性（#1）、性能（#2）、安全（#3）、语义（#4），均可追溯到"全局寄存器 + 带外错误通道 + shell 字符串拼接"这一以 m4 宏展开模拟解释器时的底层架构选择；修复优先级建议为 #3 > #1 > #4 > #2，具体路线见第 4 章。


---

## 内存回收与优化可行性

### 3.1 核心判断

先明确"回收"在本实现语境下的三层含义:宏值内存、符号表条目、子进程资源。三者的现状截然不同:

- **宏值内存:不存在传统泄漏。** m4 1.4.6 重定义同名宏会释放/复用旧值存储,实测 200K 次同名重定义 RSS 仅 3.1 MiB(接近基线量级),"define 泄漏"不成立。
- **符号表条目:单调增长。** env_new 每次调用分配 `__E<id>_C/_N/_V/_O` 四个新名符号,`__ATM_CTR` 每个 atom 一个,两个计数器只增不减;全代码 0 处 undefine、无 pushdef/popdef。长会话下符号表只进不出:RSS 线性增长,桶链查找随符号数变慢。
- **子进程资源:每轮 REPL 的真实成本大头。** 结果输出走 syscmd(printf),提示符走 esyscmd,每轮 ≥3 次 sh fork。

另有第三类问题——**同名重定义疑似 O(n²) 退化**:实测 200K 次同名重定义 7min12s 未完成被 kill,对比 100K 独立名仅 9.48s。推断(待核实)机制为 1.4.6 符号表在 redefine 时把旧值压入 shadowed 链、查找链单调变长(与 pushdef 同机制)【待核实:未读 m4 1.4.6 symtab.c 源码】。本项目 REP 每轮重定义 ~20 个全局宏(`__LAST_AST/__FORM/__RES` 等),正是该场景的微观版,长会话下查找可能逐渐退化。

因此核心判断:**优化应聚焦"少生成新符号 + 少起子进程",而不是 undefine。** undefine 只能删除符号条目,但动态名符号承载环境链语义——环境号 id 一旦回收复用,旧闭包引用将错指,不能贸然清理;宏值本身又无需干预。

### 3.2 实测数据

| 场景 | 命令 | 结果 |
|---|---|---|
| 基线:空输入 | `/usr/bin/time -l m4 -L 2000 /dev/null` | 未记录(进程被提前终止)【待核实】 |
| 100K 独立宏定义 | `m4 -L 2000 /tmp/mem_distinct.m4`(100000 行 `define(Xi, value_i)dnl`) | real 9.48s;RSS 8,925,184 B(≈8.5 MiB) |
| 200K 同宏重定义 | `m4 -L 2000 /tmp/mem_redefine.m4`(200000 行 `define(X, value_i_...)dnl`) | 7min12s 未完成被 kill;RSS 仅 3.1 MiB |
| stepA 启动即退 | `echo "(exit)" \| ./run`,`/usr/bin/time -l` ×3 | 中位 real≈1.00s;RSS≈2,543,616 B(≈2.43 MiB);user≈0.21s、sys≈0.38s |

### 3.3 代码侧热点清单

- 【step4:27】`env_new`:`__ENV_CTR` 只增不减,每个环境 4 个动态名符号,永不释放。
- 【step4:334】`__ATM_CTR`:同上,每个 atom 1 个符号。
- 【grep 证实】step4/step9/stepA/reader 全代码 0 处 undefine,无任何符号级回收机制。
- 【stepA】define 调用 681 次(493 行含 define、111 行"define 后紧跟 defn"的传态惯用法);REP 链每轮重定义 ~20 个全局宏(`__LAST_AST/__FORM/__RES/__PR/__PRS/__PRH` 等)。
- 【driver】REPL 每轮 ≥3 个子进程:结果输出 syscmd(printf) 一次,提示符 PR() 一次 esyscmd。

### 3.4 分级可行性

| # | 措施 | 可行性 | 收益 | 风险 | 一句理由 |
|---|---|---|---|---|---|
| ① | run 脚本加 `-H` 更大哈希表 | 高(一行改动) | 符号查找随符号数增长放缓;启动 ~1s 无显著改善 | 低 | 100K 独立宏 9.5s 主要花在桶链查找(推断)【待核实】 |
| ② | env_new 惰性化 | 中(改 apply_c6/ev_form 路径) | 长期会话宏表增长减 ~3-4 宏/次调用 | 中 | 无捕获的函数调用不必新建环境 |
| ③ | 合并子进程 | 高(局部改动) | 每轮 REPL 少 2-3 次 sh fork | 低 | 启动 real≈1.0s 大头是子进程;合并 printf、复用提示符输出 |
| ④ | undefine 清理临时宏 | 低(需识别安全点) | 仅对启动期一次性大宏(如 boot 宏)有效 | 低 | 重定义本身释放旧值(实测 3.1 MiB),收益小 |
| ⑤ | 给 m4 加 GC / 真正内存回收 | 不现实 | - | - | 需改 m4 解释器本身,1.4.6 无 API,符号表常驻进程生命周期 |
| ⑥ | `-L` 调优 | 已做 | - | - | run 已用 `-L 2000`,调大反而多耗内存 |

### 3.5 落地建议

按"先一行、后局部、再长线"排序:① 立即在 run 脚本加 `-H 4096`(一行改动,降低桶链退化);③ 合并 REPL 每轮子进程(局部改动,砍掉启动与每轮最大成本);② 谨慎评估 env_new 惰性化(收益明确但触及求值主路径,改动后需回归 step9 173/173 与 stepA 测试);④ undefine 仅用于启动期一次性大宏(如 boot 宏),收益小但无风险。长会话场景建议补充 RSS 增长曲线监控,若持续增长则定期重启 REPL 或引入 env 压缩(高风险,暂不建议)。

> 测试方法注:macOS 无 GNU `timeout` 命令,长时测试(sum 3000 等)采用「后台运行 + sleep + kill 守卫」完成,报告中所有"超时/被终止"类数据均由此法获得。


---

## 代码质量改善可行性

本章基于静态度量与实证交叉核验，评估代码质量改善的可行路径。核心结论：在 m4 1.4.6 的表达力约束下，复制本身不是缺陷，但工作树中 step4–step8 五文件字节级相同破坏了"增量提交"的官方组织方式，是首要待修复的质量问题。改善路径分四级，零风险改进可立即执行，高风险大重构不建议在当前约束下推进。

### 4.1 度量快照

表 4.1 给出工作树各文件的规模、重复度、命名与死代码全景。

**表 4.1 代码质量度量快照**

| 维度 | 指标 | 数值 |
|------|------|------|
| 规模 | 合计 | 696,243 字节 / 4,482 行 |
| 规模 | 最大单文件 (stepA) | 93,996 字节 / 592 行 / 493 个 define |
| 规模 | reader.m4 | 8,491 字节 / 90 行 / 50 个 define（独立 include） |
| 规模 | runner (driver + run) | 1,014 字节 / 21 行 |
| 重复度 | step4–step8 五文件 MD5 | 全部相同 (9f68dba4…)，字节级全等 |
| 重复度 | step4 vs stepA 宏体相同率 | 97.1%（471 共同名中 461 体相同，仅 10 个体不同） |
| 重复度 | committed 链 vs working tree | committed 链 29K→29K→39K→48K→57K→82K（递增），working tree 五文件同 92K |
| 命名 | `ev_*` 前缀 | 243 个，约占 define 总数 50%（eval 系列特殊形式与内置函数） |
| 命名 | `__<大写>*` 全局态 | 45 个（__ERR, __REST, __REPL_ENV, __SF_ELEM 等） |
| 命名 | 其他前缀 | mc_* 12, qq_* 10, sf_* 14, apply_* 10, env_* 6 |
| 命名 | 重复定义 | 25 个宏被多次 define（__ERR/__ERRMSG 等全局状态写模式） |
| 死宏 | 确认无引用 | WM_PFX, WM_SEP, ev_deref_sym, qq_build, str_encode（5 个） |
| 死宏 | step9 独有后丢失 | map_dedup（step9 定义无引用，stepA 已删除） |
| 错误信息 | 错误路径数 | 7 条（reader 3 条 + step4 4 条） |
| 错误信息 | 质量特征 | 全部为裸文本，无行号（m4 无此 API）、无输入位置、无调用栈 |
| 可测试性 | tests/ 目录 | 空（仅目录占位，无本实现专有冒烟测试） |
| 可测试性 | run 脚本健壮性 | 无 $step 文件存在性检查，无 m4 未安装报错 |

### 4.2 定性结论：复制是否构成缺陷

mal 官方 README 明确要求实现提供"11 个增量、自包含（且可测试）的步骤"。参考实现中，awk 使用 `@include` 共享库 + 每步全量文件，文件大小从 5.4K 逐渐增至 16K，属于"增量复制"模式；bash 使用 `source` 共享库 + 每步小 wrapper，属"模块化"模式。m4 实现的 committed 链（29K→29K→39K→48K→57K→82K 字节）遵循 awk 模式，每个 step 包含完整的解释器逻辑，差异体现在新增功能上。

**结论：复制本身不是缺陷。** mal 官方"self-contained"要求天然排斥模块化拆分，参考实现也以增量复制为常态。但 step4–step8 工作树五文件的**字节级完全相同**（同一 MD5）破坏了"增量"属性——读者无法从文件差异中获知 step5 相比 step4 新增了 TCO、step6 新增了文件 I/O。此外，五文件头部注释全部错误地标注为"step9"，进一步加剧了可读性退化。这一问题是**缺陷**，属于工作树重构过程中未保留增量差异的产物，而非架构固有缺陷。

### 4.3 改善路线图

表 4.2 将改善措施按风险分级，工作量数字来自素材实证，风险判断保留原始结论的强度。

**表 4.2 改善路线图分级清单**

| 等级 | 措施 | 工作量 | 风险 | 收益 | 建议 |
|------|------|--------|------|------|------|
| **① 零风险** | 修复 step4–step8 文件头部注释（step9→正确 step 名） | 0.1 人日 | 零 | 可读性 | **立即执行** |
| ① 零风险 | 删除 5 个死宏（WM_PFX/WM_SEP/ev_deref_sym/qq_build/str_encode） | 0.1 人日 | 零（grep 确认无引用） | 代码清洁 | **立即执行** |
| ① 零风险 | 文档/注释补全（reader.m4 编码注释与代码不一致，补 changelog） | 0.2 人日 | 零 | 可维护性 | **立即执行** |
| ① 零风险 | run 脚本添加 `-L` 文档化 + 错误后文件存在性检查 | 0.1 人日 | 零 | 健壮性 | **立即执行** |
| **② 低风险** | 将 step4–step8 从"全等副本"恢复为"增量提交"（基于 git 历史重建） | 0.5 人日 | 中（需逐 step 跑测试验证） | 可追溯性 | **建议执行** |
| ② 低风险 | step9 变更前向合并到 stepA（del_keep2 修复/map_dedup/eq_map strip_meta） | 0.3 人日 | 中（需确认 step9 修复在 stepA 上下文是否必要） | 回归防护 | **建议执行** |
| ② 低风险 | 为 REP 添加冒烟用例 → 放入 tests/ 目录 | 0.3 人日 | 低 | 可测试性 | **建议执行** |
| **③ 高风险** | 抽公共库（ev_* 核心宏集）→ 减少复制 | 2 人日 | 高（m4 1.4.6 的 include 副作用、inductive 宏展开顺序敏感） | 中等 | **不建议** |
| ③ 高风险 | 引入栈帧模拟/参数绑定重写（替代全局态传值） | 5+ 人日 | 极高（与 §4.6 递归参数绑定失效冲突，极可能引入新 bug） | 理论上的表达力提升 | **不建议** |
| **④ 不建议** | 为 error 消息添加输入位置/上下文 | — | 高（m4 无行号 API，REPL 逐行处理，上下文需全局态传递） | 低（调试友好性提升有限） | **不建议** |
| ④ 不建议 | 修复 `<<<>>>` 空嵌套引号（20 处） | 1 人日 | 极高（自述 §4.7 警告，但当前通过测试，改动可能引入回归） | 理论安全 | **不建议** |

### 4.4 根源分析

代码质量问题的根源可归结为两类因素。

**其一，AI 接力开发模式导致的文档滞后。** 该实现由三个 AI 助手（QClaw→AutoClaw→WorkBuddy）接力完成，每次交接基于"当前文件状态"而非完整设计文档，导致多处代码与文档不一致：自述.md 中 driver 示例使用宏名 `readline`，实际文件已改为 `repline`；reader.m4 第 8 行注释称编码控制字符为 `\x01-\x03`，实际代码使用 `\x0e-\x11`（代码与自述 §4.1 均正确，仅注释未同步）；step4–step8 头部注释全部错误标注为"step9"。这些不一致是典型的"代码先行、文档追赶"的 AI 接力产物。

**其二，m4 语言的表达力硬约束。** m4 1.4.6 的宏系统并非为编写解释器设计：无模块系统，文件间只能通过 `include` 全量文本包含；无命名空间，所有宏全局污染；递归参数绑定在 `<<< >>>` 引号下失效（自述 §4.6），迫使大部分递归走全局态 + `defn` 传值模式（define→立即 defn 的单层模式下可局部传参，但跨嵌套 eval 的串联场景不成立）。这些约束直接导致代码无法按功能模块拆分（拆开即破坏宏展开顺序和全局态依赖），`__ERR`/`__ERRMSG` 等全局状态宏被 10 余个宏重定义，耦合度极高——而这并非实现者疏忽，而是 m4 在该场景下的物理极限。

综上，改善应聚焦于**零风险与低风险措施**（合计约 1.6 人日），修复文档不一致、恢复 step 增量、补冒烟测试，使代码库回归可维护状态。step9→stepA 的前向合并完成后，还应验证 stepA 的 35 个 metadata/with-meta 软失败是否随之减少。高风险大重构在当前 m4 1.4.6 约束下得不偿失，不建议推进。

---

## 风险与待办(Open Items)

| # | 事项 | 状态 | 建议 |
|---|---|---|---|
| 1 | step4 官方测试 1 个 TIMED OUT(line 366,嵌套引号转义场景),引发 57 个连锁跳过 | 未修复 | 先单用例复现 `(pr-str (list 1 2 "abc" "\\"") "def")`,判断是死循环、-L 2000 不够还是编码问题 |
| 2 | step2/3/5/6/7/8 未跑回归;工作树五文件相同,step5~8 状态大概率接近 step4 | 未核实 | 恢复 step 增量后逐步跑官方测试 |
| 3 | stepA 35 个软失败集中于 metadata/with-meta 相等性,与 step9→stepA 的 ev_withmeta 重写(#5)相互印证 | 未修复 | 前向合并 step9 修复后验证软失败是否减少 |
| 4 | git 状态未收尾:12 文件 Modified(1919+/520-),stepA_mal.m4 与 自述.md 未跟踪 | 未提交 | 修复回归后 git add + commit + push origin/m4-ai-dev |
| 5 | ev_timems 依赖 perl(Time::HiRes),自述未记录,与"最小外部依赖"目标有张力 | 记录 | 文档化或换 shell 方案 |
| 6 | macOS 无 GNU timeout 命令,长时测试需后台+kill 守卫 | 工具 | 自动化脚本自带守卫 |

**修复优先级:** 安全(#3 命令注入) > 正确性(#1 全局宏冲突、#4 try* 语义) > 性能(#2 TCO/二次方查找) > 维护性(step 增量恢复、stepA 回退合并)。零风险质量项(死宏清理、注释修正、run 健壮性)可随时执行,合计约 0.5 人日。

## 附录 · 自述.md 勘误清单

| 自述.md 位置 | 原文论断 | 实测结论 |
|---|---|---|
| §8 | stepA 卡在 readline 阻塞,"111 个雪崩跳过";"已改 read -t 1" | **过时**:全仓库 grep `read -t` 零命中,ev_readline 仍是阻塞读,但 stepA 实测 0 硬失败 0 跳过、readline 测试通过 |
| §2 | step0~step9 全部通过 runtest | 仅对 git 提交版成立;工作树 step4 已回归(1 超时+57 跳过) |
| §5.2 | "PR() 输出 user> 后紧跟 NL()" | 顺序相反:实际 `NL()` 在 `PR()` 之前(`...NL()PR<<<>>>mainloop`) |
| §3.1 | driver 宏名 `readline` | 已改名 `repline`(git diff 证实) |
| reader.m4:8 | 注释写编码为 \x01 \x02 \x03 | 代码实际用 \x0e \x0f \x10 \x11(代码正确、注释过时) |
| §7.6 | 最小外部依赖 | 未记录 ev_timems 依赖 perl(Time::HiRes) |

## 关键测试命令

```bash
# 官方测试回归
cd /Users/oldliu/Documents/mal2/impls/m4
STEP=step9_try python3 /Users/oldliu/Documents/mal2/runtest.py \
  /Users/oldliu/Documents/mal2/tests/step9_try.mal -- ./run

# 启动基线测量
/usr/bin/time -l bash -c 'echo "(exit)" | STEP=stepA_mal ./run'
```
