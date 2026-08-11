# mal in csh

用 **csh（tcsh）** 实现的 [mal](https://github.com/kanaka/mal)（Make a Lisp）。

这个实现的核心约束是自找的：**不用任何非标准外部程序，也不用 tcsh 对
csh 的语法扩展**——全部语法特性（`@ x++`、`:as`、`=~`、`${name}`、`else if`、
`$var:h` 等）在 OpenBSD/FreeBSD 的经典 csh 手册中均有据可查。awk 是唯一的
重型外部依赖，而且 18 个辅助脚本已合成为**单个 `mal.awk`**（`-v mode=`
分发），只用于 csh 无法完成的字符级 I/O 工作（词法分析、集合切分、
打印解码）——每次输入一行至多几次 fork，而不是每个操作一次。EVAL 热路径
（元素访问、分类、环境查找、闭包应用、算术）全部是纯 csh 数组操作，零 fork。

```
step0_repl.csh     REPL
step1_read_print.csh  读取 + 打印
step2_eval.csh     求值
step3_env.csh      环境
step4_if_fn_do.csh if / fn* / do + 核心库
step5_tco.csh      尾调用优化
step6_file.csh     文件 / read-string / slurp / atom 族
step7_quote.csh    quote / quasiquote / cons / concat / vec
step8_macros.csh   defmacro! / macroexpand / cond 宏
step9_try.csh      try* / catch* / throw / hash-map 族 / apply / map
stepA_mal.csh      metadata / readline / time-ms / seq / conj / 类型谓词
run                STEP 环境变量选择步骤文件（默认 stepA_mal）
mal.awk           全部 awk 辅助逻辑（按 -v mode= 分发，唯一外部依赖）
```

跑测试：

```sh
STEP=step6_file python3 runtest.py tests/step6_file.mal -- impls/csh/run
```

---

# 隐含规则

下面是**贯穿全部代码但没有任何一行代码强制**的约定。改这份实现之前请先读完。

## 1. 值表示：单行安全字符串

所有 mal 值都是**不含换行**的字符串：

| 类型 | 表示 |
|---|---|
| nil / true / false | 字面量 |
| 数字 / 符号 / 关键字 | 字面文本（关键字以 `:` 开头） |
| 字符串 | `ZZQ<转义体>ZZQ`（`"`→ZZQ，`\`→ZZB，`` ` ``→ZZT，换行→ZZBn） |
| 集合 | `(a b c)` / `[a b c]` / `{k v}` |
| 内建函数 | `__CORE_<name>__` |
| 闭包 | `__FNC_<n>__`，参数/体/环境在 `FNPAR/FNBODY/FNENV[n]` |
| atom | `__ATM_<n>__`，值在 `ATMV[n]` |

**值里永远不能出现空格分隔的结构歧义**：集合内的空格是元素分隔符，字符串
内部的空格靠 ZZQ 包裹保持完整。打印前用 `dec.awk` 还原（ZZT→`、ZZB→\、
ZZQ→"），打印后的字符串会带上引号。

## 2. 数组：预分配 + 扁平下标

csh 数组**不能动态扩展下标赋值**（越界赋值报 `Subscript out of range` 且
静默失败），**下标里不能写算术表达式**（`$A[$D-1]` 静默返回空！），但**下标
可以是变量**。因此：

- 所有数组启动时用「加倍展开」预分配：`set A = ($A:q $A:q ...)`，零 fork。
- 深度索引的集合元素存在扁平数组里：`SPA[(D-1)*256 + k]`，下标先算进变量：
  `@ idx = ($D - 1) * 256 + $k`，再 `$SPA[$idx]`。
- 深度上限 128（`SPN/EVN/COLL_*` 等 512 槽），每层集合元素上限 256，
  闭包上限 256，环境绑定上限 4096。超出会下标越界——测试套件内不会。

## 3. goto 子程序 + 每深度状态

EVAL 是 goto 构成的子程序：`CALLER` 保存返回标签，递归状态按深度 D 存数组。
**不要试图在这里引入真正的 csh 函数**——csh 没有函数，而 `goto` 在 tcsh 里
每次都要线性搜索脚本文本找标签，这是解释器慢的主要来源之一（见第 8 节）。

标签子程序（`ATOM_DUMP`、`SPLIT_SCRATCH`、QQ 状态机等）**必须放在主流程
之后**——放在中间会被顺序执行。

## 4. 反引号的三个雷区

csh 的反引号替换在**双引号内再嵌双引号**会直接解析失败（`Unmatched '`'`）。
三处都踩过：

- 需要把变量内容解码后当整行用的地方（read-string / slurp / load-file 的
  路径），先写临时文件再 `set x = "`cat $T.raw`"`（cat 在反引号里不带引号）。
- 反引号结果会**通配展开**：`set TKA = (`awk ...`)` 输出含 `*` 会变成文件
  列表。文件开头 `set noglob` 全局关掉（`=~` 模式匹配不受影响）。
- 反引号结果会按空白分词：所以 `split2.awk` / `seq.awk` 把元素里的空格
  编码成 `ZZSP`，csh 端用 `:as/ZZSP/ /` 还原。

## 5. 集合切分：快慢两条路

`EVAL_COLL_SETUP` 先剥掉外层定界符（`:s` 只剥第一个，**不能用 `:as`**——
`:as` 会连嵌套括号一起剥掉，嵌套检测就失效了），检查中间是否还有括号或
ZZQ：都没有（扁平集合）就用纯 csh 分词；否则走 `split2.awk`（一个 fork）。
闭包参数和函数体在 `fn*` 定义时切分并缓存（`FNA_P/FNA_B`），闭包调用
不再重复切分。

## 6. 环境与闭包

环境是扁平绑定表 `BKEY/BVAL/BENV`，查找是线性扫描（从 BN 往下，最近绑定
先命中）。TCO 复用环境时用「绑定或覆盖」，避免绑定表无限增长。闭包的词法
环境存 `FNENV[n]`；尾调用时（`COLL_CALLER[$D] == "EVAL_RET"`）复用当前帧
和当前环境，这是 step5 的 10000 次递归能跑完（虽然慢）的关键。

## 7. 错误与 try/catch

错误通过 `ERR=1` + `E_RESULT` 传播；`EVAL_ABORT` 在有 try* 帧时恢复帧、
绑定 catch 变量、求值 catch 体，否则重置 D 并跳 `ERRTARGET`（通常是
REPL_PRINT，打印前补 `Error: ` 前缀）。符号未找到的错误值是字符串
`ZZQ'<key>' not foundZZQ`——**不带** "Error: " 前缀，前缀只在 REPL 显示
未捕获错误时加。

## 8. 性能：tcsh 就是慢

tcsh 每条语句约 0.2ms，`goto` 还要全文搜标签。step5 测试里的
`(sum2 10000 0)` 需要约 40 分钟，`(foo 10000)` 同理——这是 tcsh 的固有限制，
所以 `Makefile.impls` 里 `step5_EXCLUDES += csh`（和 bash 同一待遇：
"never completes at 10,000"）。其余所有 step 的测试都能通过，套件整体跑完
约 10-20 分钟，建议用 `--test-timeout 120`。

## 8.5 外部依赖

| 程序 | 调用点 | 用途 | 状态 |
|---|---|---|---|
| `awk` | ~250（调用点） | 单文件 mal.awk，18 种模式 | 唯一重型依赖，POSIX 标准 |
| `cat` | 42 | 反引号读临时文件（`$<` 重定向不可用） | 必需 |
| `python3` | 2 | time-ms 毫秒时间戳 | macOS/Linux 自带 |
| `echo` | 管道内 | csh 内建（管道中 fork 一次） | 内建 |
| `/bin/csh` | — | 解释器 | 目标语言 |

启动时不再调用 `dirname`（改用内建 `$0:h`，无斜杠时回退 `.`）。
**已知陷阱**：反引号内 `"$var"` 双引号变量展开会压缩连续空格，awk 路径
参数在反引号内必须无引号（`-f $awkprog`）；路径含空格的部署需自行调整。

## 9. 已知取舍

- `ZZSP` 编码意味着用户写出的字面量 `ZZSP` 会被还原成空格（测试套件不含）。
- slurp 的文件末尾换行会保留（`test.txt` 依赖这一点）；文件没有结尾换行时
  会多出一个 `ZZBn`。
- `*ARGV*` 的元素用 `:as` 编码，只处理常见字符。
- atom 打印为 `(atom <值>)`（atomprint.awk 查表渲染）。
- 用户写出的字面量 `ZZWM<数字>` 会被当作 with-meta 标记剥离（同 ZZSP 的
  取舍，测试套件不含）。
- 被 with-meta 标记的集合值在求值/切分时标记会被剥离，结果值不再携带
  元数据（`(eval ^2 [1])` 会丢 meta；测试套件不依赖这一点）。

## 10. 可选（soft/deferrable）测试也全部通过

- **DEBUG-EVAL**：EVAL 前打印 `EVAL: <ast pr-str>`，与参考实现一致。
- **quasiquote 展开结构**：与参考一致——构建表达式树
  `(cons ...)`/`(concat ...)`/`(vec ...)`，顶层整体 EVAL 一次；原子
  （nil/true/false/数字/字符串/关键字）原样返回，符号与 hash-map 用
  `(quote ...)` 包裹。
- **hash-map 重复键**：字面量和 `hash-map` 构造器都去重（后值生效）。
- **hash-map 相等**：顺序无关的键值配对比较，嵌套向量/列表等价
  （`{:a [11 22]}` 等于 `{:a (11 22)}`），map 与 list/vector 不相等。
- **try* 无 catch**：body 普通求值，错误正常传播。
- **with-meta 非突变**：闭包克隆；内建函数包装成变参闭包
  `(apply (quote <fn>) args)`；其他值（集合/atom 除外）加 `ZZWM<id>`
  身份标记，打印/相等/切分时剥离。`defmacro!` 同样克隆闭包，原函数
  不被突变成宏。
