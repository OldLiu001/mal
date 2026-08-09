# mal in dash

用 **POSIX `dash`** 实现的 [mal](https://github.com/kanaka/mal)（Make a Lisp）。

约束是自找的，也是这个实现全部有意思的地方：

* 目标 shell 是 `dash`，**不是** bash。没有数组、没有关联数组、没有 `[[ ]]`、没有 `${v:off:len}`、没有 `${v//a/b}`、没有 `local -n`、没有进程替换。
* **零外部进程**。整个解释器不 fork 任何子进程：不用 `sed`/`awk`/`tr`/`expr`/`cat`/`base64`，甚至不用 `$( )`。所有字符串处理都靠参数展开逐字符剥离。
* 单一 `core.sh` 承载全部逻辑，`stepN_*.sh` 只是设一个 `STEPNUM` 的薄壳。

```
core.sh            解释器全部实现
step0_repl.sh      \
step1_read_print.sh |
step2_eval.sh       > 每个 6~7 行：设 STEPNUM，source core.sh，起 REPL
step3_env.sh        |
step4_if_fn_do.sh  /
run                exec dash "$dir/${STEP:-stepA_mal}.sh"
Makefile           make test^dash^stepN 的胶水
```

跑测试：

```sh
STEP=step4_if_fn_do python3 runtest.py tests/step4_if_fn_do.mal -- impls/dash/run
```

---

# 隐含规则

下面这些是**贯穿全部代码但没有任何一行代码强制**的约定。破坏其中任何一条，代码依然能跑，只是会在某个遥远的地方悄悄错掉。改这份实现之前请先读完。

## 1. 返回值走全局变量，不走 stdout

**所有函数通过全局 `$r` 返回值。函数的 stdout 是留给用户的，不是留给调用者的。**

```sh
mal_num 42        # 不是 x=$(mal_num 42)
x="$r"
```

原因有三个，任何一个都是致命的：

1. `x=$(f)` 在**子 shell**里执行 `f`。我们的对象存储、`_MAL_NEXT` 计数器、环境绑定全是全局变量的副作用，子 shell 一退出全部蒸发。早期版本里 `REPL_ENV=$(env_new "")` 让整个环境系统等于没有实现，而且不报任何错。
2. 命令替换会**剥掉尾部换行**。mal 的字符串可以以 `\n` 结尾，一路传下去就少字节。
3. 每次 fork 两个进程。`step4` 的递归调用量级下，这不是"慢一点"，是跑不完。

副产物：**函数不能靠返回值传递布尔**。谓词把 `Y`/`F`（mal 的 true/false ref）放进 `$r`，绝不用 shell 退出码：

```sh
fn_list_p "$x"
if [ "$r" = Y ]; then ...      # 对
fn_list_p "$x" && ...           # 错，恒真
```

### 有名字的返回槽

`$r` 是通用槽。少数函数需要在自身递归时还持有调用者的 `$r`，于是另开专槽——**这些槽名是全局契约，不能改**：

| 槽 | 归属 |
|---|---|
| `r` | 所有函数的默认返回值 |
| `r_str` | `pr_str` / `PRINT` |
| `r_join` | `_join_args` |
| `r_kind` `r_fn` `r_params` `r_body` `r_env` | `closure_get` 一次返回 5 个字段 |

`pr_str` 用 `r_str` 是因为它内部递归时会调 `mal_val`（写 `$r`），如果它自己也用 `$r` 就会自我覆盖。

## 2. ref 是带类型标签的短字符串

一切 mal 值都是一个**不含空格的 ASCII 字符串**，首字符即类型：

| 前缀 | 类型 | 载荷位置 |
|---|---|---|
| `Z` `Y` `F` | nil / true / false | 无（单例） |
| `N<数字>` | number | ref 自身 |
| `S<名字>` | symbol | ref 自身 |
| `K<名字>` | keyword | ref 自身 |
| `G<id>` | string | `_V_G<id>` |
| `L<id>` | list | `_V_L<id>` |
| `V<id>` | vector | `_V_V<id>` |
| `H<id>` | hash-map | `_V_H<id>` |
| `A<id>` | atom | `_V_A<id>` |
| `C<id>` | function | `_C?_C<id>` 五件套 |
| `E<id>` | environment | `_EK_`/`_EV_`/`_EO_` 三件套 |

**不可变的小值内联进 ref，其余进存储。** 这样 `mal_num`/`mal_sym` 是零分配的纯字符串拼接，而 `=` 比较数字/符号只是 `[ "$a" = "$b" ]`。

### 不变量：ref 里永远不能出现空格

容器的载荷就是**空格分隔的 ref 串**（`L3` 存 `"N1 N2 S+"`，`H7` 存 `"key1 val1 key2 val2"` 的扁平对）。整个实现靠 `for e in $elems` 和 `set -- $elems` 做分词。

所以：`S` 后面跟的符号名一旦含空格，容器就散架。mal 的 tokenizer 保证符号不含空白，这条自然成立——但**任何新增的内联类型都必须遵守**。

## 3. `set -f` 是强制的，不是优化

文件顶部的 `set -f` 关掉 pathname 展开。**它是正确性的一部分。**

mal 程序里合法的符号包括 `*`、`?`、`[`，于是 ref 会长成 `S*`、`S?`、`S[`。一旦 `for e in $elems` 遇到未加引号的 `S*`，shell 会拿它去匹配当前目录的文件名。匹配不到就原样返回（碰巧对了），匹配到了就静默替换成文件名——错误发生在几十层递归之外，且**取决于你在哪个目录跑测试**。

`(* 2 3)` 能不能算对，取决于你 `cd` 到了哪里。这是最难查的一类 bug。

## 4. 存储：`eval` 赋值是唯一安全的零 fork 写法

```sh
_set_stored() { _ss_tmp="$2"; eval "_V_$1=\$_ss_tmp"; }
_get_stored() { eval "r=\$_V_$1"; }
```

关键在于 `eval` 展开后得到的是 `_V_L3=$_ss_tmp`——**变量赋值语境不做分词、不做 pathname 展开**，所以 `$_ss_tmp` 里含空格、换行、引号、反斜杠、`*` 全都原样保存，一个字节不差，也不需要任何引用处理。

反过来，`eval "_V_$1=\"$2\""` 会把 `$2` 的内容拼进 eval 的字符串里，内容里的 `"` 和 `$` 会被二次解析——这是注入，也是数据损坏。**永远先把值放进一个中转变量，再在 eval 里引用它。**

同理，动态变量名必须是先算好的字面量（`_V_$1`），值必须走中转变量（`\$_ss_tmp`，注意反斜杠）。

## 5. 命名空间前缀是私有的

| 前缀 | 用途 |
|---|---|
| `_V_<ref>` | 容器/字符串/atom 的载荷 |
| `_EK_<env>` `_EV_<env>` `_EO_<env>` | 环境的键串、值串、外层链接 |
| `_CK_ _CF_ _CP_ _CB_ _CE_ <fnref>` | 闭包的 kind / native 函数名 / 形参 / body / 定义环境 |
| `_TK_<n>` `_TK_N` | tokenizer 输出的 token 数组模拟 |
| `_MAL_*` | 解释器全局状态 |
| `_xx_*`（如 `_ss_tmp` `_es_k` `_et_t`） | 叶子函数的私有中转变量 |

`_xx_` 那类**故意不加 `local`**：它们要被同函数内的 `eval` 字符串引用，而且只出现在**非递归的叶子函数**里。一旦某个用了 `_xx_` 的函数变成递归的，必须立刻改成 `local`。

## 6. 递归函数的每个临时变量都必须 `local`

`EVAL`、`pr_str`、`fn_equal`、`READ_FORM` 全是递归的。dash 的 `local` 是动态作用域：内层声明会遮蔽外层，退出时恢复。**漏掉一个变量，内外层就共用它。**

曾经因为 `evaled` 忘了 `local`，`(+ 5 (* 2 3))` 求值成了 `(* 2 3 6)`——内层把外层攒到一半的参数列表续写了。这类 bug 不崩溃、不报错，只是算错。

所以 `EVAL` 顶部有那三行长得离谱的 `local` 声明。**新增任何局部变量，第一件事是把它加进去。**

### 附带的 dash 陷阱

`local` 和前置命令写在同一行时，`$r` 会在前置命令执行**之前**展开：

```sh
_first "$x"; local data="$r"     # 错，data 拿到的是旧的 $r
_first "$x"
local data="$r"                  # 对
```

这是 dash 特有的求值顺序（bash 不这样）。规矩很简单：**`local` 单独占一行**。

## 7. 错误靠 `MAL_ERR` 双全局显式传播

没有异常，没有 `set -e`。约定是：

```sh
mal_error "message"              # 置 MAL_ERR=1 和 MAL_ERR_MSG
```

**每一个可能失败的调用之后，必须紧跟一行检查：**

```sh
EVAL "$3" "$env"
if [ "$MAL_ERR" = 1 ]; then return; fi
```

漏掉检查不会崩，只会让错误后的代码继续拿着垃圾 `$r` 往下算，最终以一个风马牛不相及的信息报错。`EVAL` 和 `APPLY` 入口处也各有一次检查，作为兜底的"错误已置位就整体空转到顶"机制。

## 8. 一个 `core.sh`，用 `STEPNUM` 做门控

不给每个 step 拷一份代码。`stepN_*.sh` 只做一件事：

```sh
STEPNUM=4
. "$(dirname "$0")/core.sh"
init_repl_env
mal_repl
```

`core.sh` 内部用 `[ "$STEPNUM" -ge 3 ]` 之类的条件裁剪特殊形式和内建函数。好处是修一处全 step 受益；代价是**新增特性时必须想清楚它属于哪一步**，否则 step2 会意外通过本该失败的测试（官方测试确实会检查"这一步还不该支持什么"）。

`STEPNUM` 语义即 mal 官方步骤号：0=echo、1=read/print、2=最简 eval、3=def!/let*、4=if/fn*/do、……

## 9. 输出一律 `printf '%s\n'`

dash 的 `echo` **会解释反斜杠转义**（`echo 'a\nb'` 打出两行）。mal 的字符串里反斜杠是一等公民，用 `echo` 会静默改写用户数据。

**代码里不允许出现 `echo`。** 调试也不行——调试用 `printf ... >&2`。

## 10. `case` 模式里的 `*` `?` `[` 必须加引号

```sh
case "$fname" in
  'let*') ... ;;      # 对
  let*)   ... ;;      # 错：letfoo、letx 全部命中
esac
```

mal 的特殊形式名字里带 `*`（`let*` `fn*` `try*` `catch*` `defmacro!`），这条踩过一次。

## 11. 单元素剥离必须显式判断

`${s#* }` 在 `s` 不含空格时**原样返回 `s`**，不是返回空。所以遍历空格分隔串的标准写法是：

```sh
k=${ks%% *}
if [ "$k" = "$ks" ]; then ks=""; else ks=${ks#* }; fi
```

省掉那个 `if`，最后一个元素会被无限重复取出——死循环。这段样板在 `env_get`、`pr_str`、`EVAL` 的 map 分支、`fn_equal` 里各出现一次，**照抄，别简化**。

对于确定要按空格切成位置参数的场合，直接 `set -- $elems` 更省事（依赖 `set -f` 的保护）。

## 12. 环境：平行数组 + 显式外链，保证遍历终止

```
_EK_E7 = "b a x"      新绑定前插 → 查到的第一个即最新，天然实现 shadowing
_EV_E7 = "N2 N1 N9"   与 _EK_ 逐位对应
_EO_E7 = "E3"         外层环境；空串表示到顶
```

**`_EO_` 只能指向已经存在的、更早创建的环境。** 环境 id 单调递增且只在创建时写一次外链，因此链一定是有限的、无环的。早期用过一种"按需回填外链"的方案，结果 `(abc)` 这种未定义符号会让链成环，`env_get` 无限循环——表现为进程被 OOM killer 干掉（exit 137），而不是栈溢出。

前插而非覆盖，意味着**同一环境里重复 `def!` 会留下旧条目**。这是有意的空间换时间：`env_set` 是 O(1)，查找总是命中最新的那个。

## 13. 数字只有整数

`$(( ))` 是 dash 唯一的算术，只有整数。mal 规范也只要求整数，所以没问题——但 `/` 是截断除法，`(/ 7 2)` = 3。

## 14. `EVAL` 是循环，尾位置只能 `continue`

`EVAL` 外面套着 `while true`。**处于尾位置的求值一律改写 `ast`/`env` 后 `continue`，绝不递归调用自己**：

| 尾位置 | 处理 |
|---|---|
| `let*` 的 body | `ast=$3; env=$nenv; continue` |
| `do` 的最后一个表达式 | `ast=$1; continue` |
| `if` 选中的那个分支 | `ast=$3`（或 `$4`）`; continue` |
| mal 闭包的 body | `ast=$clbody; env=$nenv; continue` |

非尾位置（函数实参、`let*` 的绑定值、`if` 的条件、`do` 的前 n-1 项）**必须**真递归，它们的结果要被后续代码使用。

新增特殊形式时先问一句：它的最后一个子表达式是不是尾位置？是就 `continue`，否则 `(sum2 10000 0)` 那种尾递归会在几百层深处把 shell 拖死。

## 15. `_ev1` 必须与 `EVAL` 语义一致

`_ev1` 是叶子快速通道：符号查环境、字面量原样返回、容器转交 `EVAL`。它存在的唯一理由是 `EVAL` 顶部那 20+ 个 `local` 太贵（见下一条），而真实代码里绝大多数被求值的东西是叶子。

**它零 `local`，只用位置参数。** 往里加变量之前想清楚：加了就等于取消了它的全部意义。

改动 `EVAL` 里符号或字面量的求值语义时，**`_ev1` 必须同步改**，否则会出现"同一个表达式在参数位置和尾位置行为不同"这种极难查的 bug。`DEBUG-EVAL` 打开时 `_ev1` 一律退回完整 `EVAL`，就是为了不必在追踪逻辑上维护两份。

## 16. 环境回收的安全前提

深递归会创建海量环境。**必须回收**，理由见下条。

回收的判据只有一条：

> **环境只可能通过 `mal_closure_mal` 的 `_CE_` 字段逃逸。**

`def!`、atom、list/vector/map 存的都是**值 ref**，不是环境。所以只要某段执行期间 `mal_closure_mal` 一次都没被调用（`_MAL_NCLOS` 计数没变），期间创建的所有环境就都是垃圾，可以 `unset`。

`EVAL` 在做尾调用时利用了这一点：新环境的外链是闭包捕获的 `clenv`，与当前这条链无关，于是当前链上本轮攒下的环境全部可回收。

**任何新增的、能把 env 存起来的机制都会打破这个前提。** 真要加，就必须同时递增 `_MAL_NCLOS`。

## 17. 为什么必须回收：dash 变量表会二次退化

dash 的变量哈希表是**定长**的。变量一多，每个桶就退化成长链表，而**每一次 `local` 声明都要在链表里线性查找**。

实测「20000 次调用一个含 25 个 `local` 的函数」：

| 变量表里的残留变量 | 耗时 |
|---|---|
| 0 | 0.68 s |
| 5,000 | 5.3 s |
| 20,000 | 85.3 s |

125 倍。这不是常数因子，是复杂度问题：**不回收环境，解释器的速度会随已执行的代码量二次衰减**。任何"往全局塞变量且从不清理"的设计都会踩到这个坑。

## 18. 测试要放宽超时

`runtest.py` 默认每条用例 20 秒。step5 的 `(sum2 10000 0)` 一条就要几十秒（shell 跑解释器，慢是本分）。

`Makefile` 里设了 `TEST_OPTS = --test-timeout 600`。手工跑记得带上：

```sh
STEP=step5_tco python3 runtest.py --test-timeout 600 tests/step5_tco.mal -- impls/dash/run
```

---

# 调试

进程被 kill（exit 137）而非报错，基本只有两个原因：`env_get` 陷入无限循环（外链成环），或某个 `while [ -n "$s" ]` 忘了推进 `s`。

单步冒烟比跑 harness 快得多：

```sh
printf '(+ 1 2)\n(let* (a 1) a)\n' | STEP=step4_if_fn_do dash impls/dash/run
```

`runtest.py` **默认在第一个硬失败之后跳过剩余全部测试**。看到 "1 failing, 55 skipped" 不是 56 个问题，是 1 个。
