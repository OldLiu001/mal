# M4 实现「自述」（供后续 agent 接手参考）

> 本文档由 WorkBuddy 汇总 **本软件（WorkBuddy）**、**QClaw**、**AutoClaw** 三个 AI 助手在
> `mal`（Make a Lisp）项目 **m4 语言实现**上的全部对话沉淀而成。
> 目标：把踩过的坑、隐性规定、经验、教训一次性写清楚，让下一个接手的 agent 不再重蹈覆辙。

---

## 0. 一句话定位

这是 [kanaka/mal](https://github.com/kanaka/mal) 项目的 **GNU m4 宏处理器实现**：用 m4 宏写一个
Lisp 解释器。仓库本地路径 `/Users/oldliu/Documents/mal2`，工作分支 **`m4-ai-dev`**，实现目录
`impls/m4/`。核心思想：**数据是字符串，程序是宏，执行是一次巨大的宏展开**。

- step0~step9 已全部 `git commit` 通过官方 `runtest.py`；
- **`stepA_mal.m4` 目前仍是「未跟踪」文件**（最后一块拼图，卡在 `readline` 修复，见 §8）。

---

## 1. 三个软件的接力关系（溯源）

mal 的 m4 实现是**跨三个 AI 助手接力**完成的，谁都不是从零开始：

| 软件 | 角色与贡献 | 关键记录位置 |
|---|---|---|
| **QClaw** | 2026-08-11 在 `mal2` 从 `master` 开分支 `m4-ai-dev`，探索 m4 能力、设计架构（driver+step 文件）、实现并提交 **step0（REPL，24/24 通过）**。后续主要转向 csh/dash/applescript 实现，但 #14 会话含 1604 处 m4 讨论（含大量隐性规定）。 | `~/.qclaw/memory/lossless/lcm.db`（14 会话 / 8062 消息）；`~/.qclaw/qmemory/c27fc2e2-*.json`（m4 任务，157 步） |
| **AutoClaw** | 接手把 step1→stepA 一路推完。**`4bef8f44…` 会话是 m4 主战场**（m4 出现 1133 次），解决了 m4 1.4.6 几乎全部坑；`c581d249…` 修过死循环与 quasiquote 编码；`e07c2eda…` 写过架构讲解。 | `~/.openclaw-autoclaw/agents/main/sessions/*.jsonl` |
| **WorkBuddy（本软件）** | 两个独立 m4 会话：`dcf72cf0`（08-11「查看qclaw记录并继续m4实现」）、`9d2d00a6`（08-14「查看qclaw聊天记录并继续实现m4」）。**后者贡献了最完整的 REPL/IO 机制攻坚记录**（syscmd vs esyscmd、changequote 陷阱、readline fd0 争用、runtest 雪崩跳过）。 | `~/.workbuddy/projects/.../9d2d00a6-*.jsonl`、`dcf72cf0-*.jsonl` |

> ⚠️ **隐性规定（来自用户，务必遵守，见 §7）**：用户曾严厉纠正「不要另起炉灶」——
> 已存在的实现在 **`/Users/oldliu/Documents/mal2`**，不要在 `/Users/oldliu/Documents/mal` 从零重写。

---

## 2. 文件结构与测试框架

```
impls/m4/
├── driver.m4.in     # REPL 循环模板（含 __STEP__ 占位符），由 run 脚本 sed 替换
├── run              # 驱动脚本：sed 替换 __STEP__ → 生成临时 driver → exec m4
├── reader.m4        # 阅读器（已被 step1~step9 共用），含编码方案与 canonical 输出
├── step0_repl.m4    # REPL（回显）
├── step1_read_print.m4
├── step2_eval.m4  …  step9_try.m4
├── stepA_mal.m4     # ★ 未跟踪，最后一块（meta/self-host）
└── tests/           # 本目录的步进测试（官方 tests/ 在仓库根 tests/）
```

**跑测试（模板，务必照此，参数顺序有坑）**：

```bash
cd /Users/oldliu/Documents/mal2/impls/m4
STEP=step2_eval python3 /Users/oldliu/Documents/mal2/runtest.py \
    /Users/oldliu/Documents/mal2/tests/step2_eval.mal -- ./run
```

- `runtest.py` 通过 **pty** 拉起 `./run`，等待 prompt 正则 `[^\s()<>]+> `（如 `user> `），
  喂入 form，匹配 `;=>` 后的期望值。
- **`STEP` 用环境变量传入**（`run` 脚本 `step="${STEP:-stepA_mal}"`）。
- **`runtest.py` 的第一个硬失败后会 `continue` 跳过后续所有测试**——除非加 `--continue-after-fail`。
  所以「111 个被跳过」往往只是第一个失败引发的雪崩，先修第一个硬失败即可。
- **测试文件里的 `;=>` 只是期望标记，不是字面输出**！参考实现（bash/awk）是**直接 `echo` 值**，
  不带 `;=>` 前缀。m4 这边只要把结果作为自然输出流打印即可。

---

## 3. 核心架构（driver + step 文件 + 全局宏传态）

### 3.1 REPL 循环（driver.m4.in，已验证可工作）

```m4
changequote(<<<, >>>)dnl
define(<<<readline>>>, <<<esyscmd(<<<if IFS= read -r line; then printf "<<<%s>>>" "$line"; else printf "EOF"; fi>>>)>>>)dnl
define(<<<NL>>>, <<<esyscmd(<<<printf "\n">>>)>>>)dnl
define(<<<PR>>>, <<<esyscmd(<<<printf "user> ">>>)>>>)dnl
include(__STEP__)dnl
PR()dnl
define(<<<mainloop>>>, <<<define(<<<_l>>>, readline)ifelse(defn(<<<_l>>>), EOF, <<<>>>, <<<indir(<<<REP>>>, defn(<<<_l>>>))<<<>>>NL()PR<<<>>>mainloop>>>)>>>)dnl
mainloop
```

要点（这是踩了无数坑后定下的，别改）：

1. **`changequote(<<<, >>>)`** 全局生效。所有宏名用纯文本（反引号引号已被禁用）。
2. **递归靠全局宏 + `defn` 传态，不靠参数绑定**。
   `mainloop` 把读到的行存进全局 `_l`，用 `defn(<<<_l>>>` 取出传给 `REP`，再裸递归 `mainloop`。
   原因是 `<<< >>>` 引号体系下**宏自调用的参数 `$1` 绑定会失效**（见 §4.6），裸递归 + 全局态可绕开。
3. **`readline` 用 `esyscmd` 在顶层读取**——`esyscmd` 只有在**顶层**调用才能正常读 stdin；
   一旦嵌套进 `define`/`ifelse` 的参数里就返回空/EOF（见 §4.8）。`mainloop` 里 `readline` 是顶层调用，所以可用。
4. `run` 脚本：`m4 -I "$dir" -L 2000 "$tmp"`。**`-L 2000` 是递归层数上限**，m4 默认 1024 会不够；
   若某步（尤其 step8 宏展开）报 recursion limit，调大 `-L`（如 4000/8000）而非改逻辑。

### 3.2 EVAL 链（step2+）的拆链写法

AutoClaw 在 step2 把 EVAL 按首字符分派拆成 **`ev_d1`~`ev_d9` 每层一个 ifelse**，避免单层
ifelse 嵌套过深导致 `>>>` 配平失控。递归求值的结果都是原子，唯一含括号的结果是空列表 `()`
且只在顶层出现，故可安全走顶层输出。这个值传递/累积模式（`__REST`/`__ARGV`/`__EXPR` 等全局宏
+ `defn` 传值）是 **m4 实现能在 `<<< >>>` 下跑递归的根本解法**。

---

## 4. GNU M4 1.4.6 关键特性与坑（汇总三处对话，按致命度排序）

环境：**macOS 自带 `/usr/bin/m4` 是 GNU M4 1.4.6**（带 `esyscmd`/`indir`/`format`/`changequote` 多字符引号）。
`substr`/`len`/`index`/`format`/`ifelse`/`defn`/`indir`/`esyscmd`/`translit` 均可用；
**`concat`、`revstr`、`decr` 不是内建**，不能调用。

### 4.1 编码方案（最致命，reader.m4 地基）
m4 收集宏参数时，展开结果里的未加引号 `)` 会**提前关闭外层参数列表**、`\``,`` 会**分割参数**、
`#` 会让同行后续 `<<< >>>` 引号失效。

**解法**：`read_str` 入口用 `translit` 把 `(`,`,,`#` 编码成**非空白控制字符**，内部全在编码文本上
解析/求值，`PRINT` 时 `DEC` 解码回括号：

```
LP = \x0e (14)   ←  (
RP = \x0f (15)   ←  )
CM = \x10 (16)   ←  ,
HS = \x11 (17)   ←  #
ENC = translit($1, "(),#", LP()RP()CM()HS())
DEC = translit($1, LP()RP()CM()HS(), "(),#")
```

> ⚠️ **历史坑（已修，记住别回退）**：LP/CM 最初用 `\x0b/\x0c`（VT/FF），但 GNU m4 在参数收集时
> 会把 VT/FF 当**空白剥离**，静默切分宏参数 → 改成 `\x0e/\x10`（非空白控制字符）。
> 另外 **`\x01`–`\x03` 被 m4 内部占用，绝不能用作编码字符**。

### 4.2 `ifelse` 急切展开所有参数 → 递归/含宏分支必须惰性引号
`ifelse` 在判定前会**展开全部参数**（含未选中分支）。把递归调用直接放进「否则」分支会无限递归。
**所有含宏调用的分支必须用 `<<< >>>` 包裹成惰性文本**，rescan 时才展开。
> 注：早期误判「此 m4 的 ifelse 急切」其实是用 `bomb()` 自包含宏测出来的假象；**ifelse 本身是惰性的**，
> 真正失效的是「`<<< >>>` 内递归自调用」（见 4.6）。结论不变：分支要引号保护。

### 4.3 宏展开结果的「重扫」灾难
- **用户宏**展开出的结果会**重新参与外层扫描**：结果里的 `)` 提前关闭外层参数列表 → 破坏调用。
- **builtin**（如 `substr`/`len`）的展开结果作为值**不会重扫**，安全。
- **`defn()` 展开结果自带引号保护**（安全），所以跨宏的值传递统一走「全局宏 + `defn`」。
- **参数副作用顺序**：`pl_join(A, B)` 中 A 的副作用对 B 不可见；需先 `define(<<<__ELEM>>>, canon(...))`
  再用 `defn` 取值传递（AutoClaw 因此把「参数传递累积模式」定为全局规范）。

### 4.4 参数收集细节
- `$1`/`$2` 等**必须写成 `<<<$1>>>` / `<<<$2>>>`**——值替换后会再被扫描，裸括号/逗号/首部空白会破坏收集。
- **宏名必须引号化**：`define(__REST, ...)` 中 `__REST` 是空宏会被展开成空；
  必须 `define(<<<__REST>>>, ...)`。
- **`$@` 展开自带引号包裹** → 双重引号；REP/READ 改用 `$1`。
- 宏展开结果作为 ifelse 参数时，若展开结果含逗号会分割外层 → 让所有嵌套 ifelse 分支惰性化。

### 4.5 输出必须换行结尾（否则泄漏）
`REP` 输出若在 `>>>)dnl` 内放 `\n` 结尾——否则含 `#`/`"` 的输出会影响 driver `mainloop`
后续 `<<<>>>PR<<<>>>mainloop` 的引号识别（泄漏字面 `<<<>>>PR<<<>>>mainloop`）。
`err_string`/`errset` 必须重置 `__REST` 为空，否则字符串解析失败后 `parse_list_body2(defn(__REST))`
用旧值无限递归。

### 4.6 递归在 `<<< >>>` 引号下「参数绑定失效」→ 用全局态绕开
决定性验证（`deep(abc)`）：
- `<<< >>>` 模式 + 递归调用用 `<<< >>>` 包裹 → **无限递归**（`$1` 首层即变空）。
- 默认反引号模式 + 递归调用用反引号包裹 → 正常（`DONE`）。
- `indir(<<<deep>>>, ...)` 按名调用 → 仍失败。
- **唯一可靠姿势**：裸递归 + **全局宏传态**（正是 `mainloop` 的做法，step0 已验证通过）。
  reader/ev_* 一律用 `__REST`/`__EXPR` 等全局宏承载状态，不依赖递归参数绑定。

### 4.7 `<<<>>>` 空嵌套引号是坏构造
`<<<>>>`（无内容）和仅含空格的 `<<< >>>` 会**发射一个游离反引号**，破坏后续解析、引发 ifelse
参数计数告警/递归。表示空格请用 `define(<<<SP>>>, format(%c,32))`；空串用 `define(<<<E>>>, )`
（无空格）。**绝不要用 `<<<>>>` 当「返回空」**。

### 4.8 `esyscmd` vs `syscmd`（IO 机制的命门，见 §5）
- `esyscmd(cmd)`：**捕获**子进程 stdout 作为返回值插入输出流，会被**重扫/重放**——
  捕获到的文本若含宏触发子串会被反复展开（WB 0814 曾因此 `;=>` 被打印十几遍）。
- `syscmd(cmd)`：子进程 stdout **直接写进 m4 的 stdout 流**，立即刷新、不捕获、不重扫。
  打印结果/提示符优先用 `syscmd`；**只有「读 stdin 拿返回值」才用 `esyscmd`**，且必须在顶层。

### 4.9 其它零散坑
- **`is_number` 不能用 `+`/`?` 量词**（m4 1.4.6 的 `regexp` 是 POSIX BRE）→ 逐字符 `is_digit`
  （`regexp(x, ^[0-9]$)`）+ 递归 + 处理 `-` 前缀。
- **`patsubst`/`regexp` 行为不稳** → 优先 `index` 在分隔符集合里判定，手写自增递归替代正则。
- **空格字符比较不可靠**：`ifelse(is_ws( ), 1, ...)` 可能返回 NO；改用 `index(DELM, $1)`。
- **m4 的「身份」取决于调用方式**：传**文件参数**（`m4 file.m4`）→ GNU m4（esyscmd 正常）；
  传命令行字符串/stdin → 退回 **BSD gm4**（esyscmd 报错）。`run` 脚本用文件参数 + `-L`，正确。
- **macOS 沙箱会误杀 m4**（退出码 137，伪装成「无限递归」）→ 跑 `m4` 的命令需关沙箱
  （WorkBuddy 的 Bash 工具用 `dangerouslyDisableSandbox: true`）。

---

## 5. REPL / IO 机制（WorkBuddy 0814 会话的攻坚结论，最高价值）

这是整个实现里最难的部分，WB 0814 会话用几十轮实验才定下来，务必照做：

1. **`changequote([,])` 能让递归 syscmd REPL 循环存活；`changequote(<<<,>>>)` 在 driver 里也可用**
   （driver 不用递归 syscmd，用裸递归 + 全局态，故无冲突）。**避免使用 `<,>`/`</>/@<@>` 这类引号集**——
   这些会让 m4 在递归循环里**直接退出（EIO）**。
2. **提示符必须有换行才能刷新**：m4 stdout 全缓冲，不带换行的 `user> ` 会卡在缓冲区，
   而 `esyscmd`/`syscmd` 在阻塞读前不一定刷新 → 测试台等不到 prompt 就死锁。
   driver 里 `PR()` 输出 `user> ` 后紧跟 `NL()` 换行刷新，故可用。
3. **`readline` 内部用 `read -u 0 -r line` 读 fd0**；**stepA 的 `ev_readline` 也读 fd0 会争用**
   → 见 §8。
4. **不要用 `divert(文件名)` 写文件**：GNU M4 1.4.x 不支持（那是 1.4.17+ 特性），此路不通。
5. **`script -q` pty 包装反而让 m4 变全缓冲管道、连换行都不刷** → 别用；让 m4 直接在 runtest
   提供的真实 pty（tty）里跑，靠 `syscmd` 直接输出 + 换行刷新。

---

## 6. runtest 框架注意事项（再强调）

- 调用：`cd impls/m4 && STEP=<step> python3 ../../runtest.py ../tests/<step>.mal -- ./run`
  （`runtest.py` 的位置参数用绝对路径；`nargs="*"` 会吞掉后续选项，注意顺序）。
- 第一个硬失败 → 后续全跳过（除非 `--continue-after-fail`）。先修第一个。
- `;=>` 是测试文件里的**期望标记**，不是输出格式；实现**直接打印值**。
- 手动单测可用：写 `/tmp/zt.m4` 含 `changequote(<<<,>>>)dnl include(<step>.m4)dnl define(<<<INP>>>,<<<输入>>>)dnl REP(defn(<<<INP>>>))dnl`，
  再 `m4 -I <dir> -L 3000 /tmp/zt.m4`。

---

## 7. 用户隐性规定 / 偏好（用户原话反复强调，务必遵守）

这些**不会写在代码注释里，但用户极其在意**：

1. **「让用户看起来正确」**：纠正用户/前序 agent 的错误时，保全用户面子，**不要直接打脸/硬怼**。
   用户曾明确说「当时我要求的是让用户看起来正确，你先去看聊天记录！」。
2. **「完成 stepA 再停 / 不要突然停下来」**：尤其**不要在测试之前停下**，
   一路推到 stepA 再停。原话：「你能不能不要突然停下来？完成stepa再停」「你继续不要老是在测试之前停下来！」。
3. **「历史对话丢失就直接进行」**：若上下文/记忆丢失，不要反复追问，直接基于当前文件状态推进。
4. **「从 WorkBuddy 聊天记录同步最新进展」**：接手前先读本软件（WorkBuddy）的对话记录，
   不要凭空重写。
5. **「复用现有 mal2，别另起炉灶」**：已实现的 m4 在 `/Users/oldliu/Documents/mal2`，
   用户原话纠正过「你怎么重新写了一个，去看mal2，里面的m4已经实现的差不多了，继续并实现完」。
6. **最小外部依赖 / 按官方仓库要求拆文件**（源自 csh 实现的那条线，同样适用）。
7. **回复用中文**（技术术语/代码标识符保留原文）。

---

## 8. 当前进度与最后一块拼图（stepA）

- step0~step9 已 `git commit` 并通过 runtest。
- **`stepA_mal.m4` 已写到 86KB、功能基本齐（REP 注册全套 core、`load-file`、atom、`conj`/`seq`/
  `readline`/`time-ms`、metadata 都齐），但仍是「未跟踪」文件**——最后要 `git add` + `commit`。
- **已知阻断（stepA readline 测试）**：`ev_readline` 用 `read -u 0 -r line` **阻塞**读 fd0，
  把 runtest 作为 form2 发来的 `"hello"` 当成 readline 输入 → form1 求值失控报错，
  后续 111 个测试被雪崩跳过。正确语义（参考实现一致）：readline 在没有立即可用输入时应
  **非阻塞返回空串**。
  - ⚠️ macOS `/bin/sh` 下 `read -t 0.01`（**小数超时非法**，只接受整数）→ 改 `read -t 1`
    （整数超时，1 秒内无输入即返回空串 `""`）。`read -t 0` 不可靠。
  - pty / nopty 两种模式表现一致，差异不在 pty，而在 fd0 争用。
- **收尾动作**：修好 `ev_readline` 的阻塞读 → 后台跑 `stepA` 全量（带 `--continue-after-fail`）
  确认失败面 → `git add impls/m4/stepA_mal.m4 && git commit` → push 到 `origin/m4-ai-dev`。

---

## 9. 给后续 agent 的速查清单（Do / Don't）

**Do**
- 改/写任何 `.m4` 前，先 `Read` 当前 `reader.m4` 与对应 step 文件，别凭记忆重写。
- 参数写 `<<<$1>>>`；宏名写 `<<<__X>>>`；分支含宏必用 `<<< >>>` 惰性包裹。
- 跨宏传值走「全局宏 + `defn`」；递归用全局态 + 裸递归（学 `mainloop`）。
- 编码 `()` `,` `#` → `\x0e \x0f \x10 \x11`（绝不用 VT/FF/\x01-\x03）。
- 打印/提示符用 `syscmd`（直接输出、不重扫）；只读 stdin 才用顶层 `esyscmd`。
- 跑测试用 §2 的模板；第一个失败先修，再决定要不要 `--continue-after-fail`。
- 收尾记得 `git commit` + push。

**Don't**
- 别在 `/Users/oldliu/Documents/mal` 从零重写（实现在 `mal2`）。
- 别用 `concat`/`revstr`/`decr`（非内建）；别用 `<<<>>>` 空嵌套引号（发射游离反引号）。
- 别把递归调用塞进 `<<< >>>` 当字面（参数绑定会失效）；别依赖递归参数 `$1`。
- 别用 `divert(文件名)` 写文件；别用 `read -t 0.01` 小数超时；别用 `script` 包 m4。
- 别在测试前/中途停下；别直接打脸用户的纠正；别忽略 §7 的隐性规定。

---

*整理来源：WorkBuddy 会话 `9d2d00a6`、`dcf72cf0`；QClaw 聊天导出 `chat.txt`（#7–#14）；
AutoClaw 会话 `4bef8f44`、`c581d249`、`e07c2eda`；以及 `impls/m4/` 现有源码。*
