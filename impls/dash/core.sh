#!/bin/dash
# core.sh - dash 原生实现的 mal 核心（覆盖 step0~step4）
# 由 stepN_*.sh 设置 STEPNUM 后 source。
#
# 设计要点（沉淀历史踩坑）：
#  1. dash 无数组/关联数组/[[ ]]/${v:o:l}/${v//}/local 数组，全部用「引用字符串 + 动态变量」建模。
#  2. 存取任意内容零 fork：eval "_V_$ref=\$_tmp"。赋值语境不做分词与 pathname 展开，
#     所以内容含空格/换行/引号/反斜杠都安全，比 base64 快一个数量级。
#  3. set -f 全局关闭 pathname 展开：ref 可能是 S* / S? / S[，不关会被当通配符。
#  4. echo 会解释反斜杠 -> 一律 printf '%s\n'。
#  5. 谓词结果走全局 $r，不能用 shell &&/|| 判真假。
#  6. 递归函数的每个临时变量都必须 local，否则内外层互相串味。
#  7. 命令替换 $( ) 会剥尾部换行且开子 shell（副作用丢失）-> 一律不用，靠 $r 回传。
#  8. case 模式里的 * ? [ 必须加引号（'let*' 'fn*'），否则是通配符。
#  9. 单元素剥离：${s#* } 在无空格时原样返回，必须显式判 "$head" = "$s"。

set -f

# ---------------- 全局状态 ----------------
MAL_ERR=0
MAL_ERR_MSG=""
_TK_N=0
_TOK_POS=1
_MAL_NEXT=0
_MAL_NCLOS=0
_MAL_DBG_SEEN=0
REPL_ENV=""
STEPNUM=${STEPNUM:-0}
TAB='	'
NL='
'

# ================= 存储（零 fork，任意内容安全） =================
_set_stored() {  # $1=ref $2=内容
  _ss_tmp="$2"
  eval "_V_$1=\$_ss_tmp"
}
_get_stored() {  # $1=ref -> r
  eval "r=\$_V_$1"
}
new_id() { _MAL_NEXT=$((_MAL_NEXT+1)); r=$_MAL_NEXT; }

# ================= 值模型 =================
# Z=nil Y=true F=false N<数字> S<符号> K<关键字>
# G<id>=字符串 L<id>=list V<id>=vector H<id>=hash-map C<id>=函数 A<id>=atom
mal_type() {  # $1=ref -> r=类型名
  case "$1" in
    Z) r=__nil ;;
    Y) r=__true ;;
    F) r=__false ;;
    N*) r=__num ;;
    S*) r=__sym ;;
    K*) r=__kw ;;
    G*) r=__str ;;
    L*) r=__list ;;
    V*) r=__vec ;;
    H*) r=__map ;;
    C*) r=__fn ;;
    A*) r=__atom ;;
    *) r=__unknown ;;
  esac
}

mal_val() {  # $1=ref -> r=原始内容
  case "$1" in
    Z|Y|F) r="" ;;
    N*) r=${1#N} ;;
    S*) r=${1#S} ;;
    K*) r=${1#K} ;;
    G*|L*|V*|H*|A*) _get_stored "$1" ;;
    *) r="" ;;
  esac
}

# -------- 构造器 --------
mal_num() { r="N$1"; }
mal_sym() { r="S$1"; }
mal_kw()  { r="K$1"; }
mal_str() {
  local id
  new_id
  id=$r
  _set_stored "G$id" "$1"
  r="G$id"
}
mal_list() {
  local id
  new_id
  id=$r
  _set_stored "L$id" "$*"
  r="L$id"
}
mal_vec() {
  local id
  new_id
  id=$r
  _set_stored "V$id" "$*"
  r="V$id"
}
mal_map() {
  local id
  new_id
  id=$r
  _set_stored "H$id" "$*"
  r="H$id"
}
mal_atom() {
  local id
  new_id
  id=$r
  _set_stored "A$id" "$1"
  r="A$id"
}

# -------- 闭包 --------
mal_closure_native() {  # $1=shell 函数名 -> r=C<id>
  local id
  new_id
  id=$r
  eval "_CK_C$id=native ; _CF_C$id=\$1"
  r="C$id"
}
mal_closure_mal() {  # $1=形参名串 $2=body ref $3=闭包env -> r=C<id>
  local id
  new_id
  id=$r
  # 环境回收的依据：env 只可能经由闭包的 _CE_ 字段逃逸，这里是唯一的捕获点。
  _MAL_NCLOS=$((_MAL_NCLOS+1))
  eval "_CK_C$id=mal ; _CP_C$id=\$1 ; _CB_C$id=\$2 ; _CE_C$id=\$3"
  r="C$id"
}
closure_get() {  # $1=C<id> -> r_kind r_fn r_params r_body r_env
  eval "r_kind=\$_CK_$1 ; r_fn=\$_CF_$1 ; r_params=\$_CP_$1 ; r_body=\$_CB_$1 ; r_env=\$_CE_$1"
}

# ================= 环境 =================
# _EB_<env> = " =名1 值1 =名2 值2 ... "（始终以空格开头结尾，新绑定前插）
# _EO_<env> = 外层 env ref（空串表示到顶，遍历必然终止，不会成环）
#
# 键带 '=' 前缀是关键：值一律是 ref，而 ref 的首字符必然属于 ZYFNSKGLVHCAE，
# 绝不会是 '='。于是子串 " =名 " 只可能匹配到键的位置，不会误命中某个值。
# 查找因此退化成一次 ${kv#*" =名 "} —— C 层的单趟扫描，比 shell 循环逐个
# 剥离键快一到两个数量级（这是 TCO 之后最主要的热点）。
# 前插 + `#` 最短匹配 => 命中的必然是最新绑定，shadowing 自动成立。
env_new() {  # $1=外层env ref -> r=E<id>
  local id
  new_id
  id=$r
  eval "_EB_E$id=' ' ; _EO_E$id=\$1"
  r="E$id"
}
env_set() {  # $1=env $2=名 $3=值ref
  _es_k="$2"
  _es_v="$3"
  # 只有真的绑过 DEBUG-EVAL 才让 EVAL 每轮去查环境链，避免常态下的性能损耗
  if [ "$_es_k" = 'DEBUG-EVAL' ]; then _MAL_DBG_SEEN=1; fi
  eval "_EB_$1=\" =\$_es_k \$_es_v\$_EB_$1\""
}
env_get() {  # $1=env $2=名 -> r=值ref（空串=未找到）
  local e="$1" name=" =$2 " kv rest
  while [ -n "$e" ]; do
    eval "kv=\$_EB_$e"
    # "$name" 必须加引号：符号名可以是 * ? [，不引会被当模式
    rest=${kv#*"$name"}
    if [ "$rest" != "$kv" ]; then r=${rest%% *}; return; fi
    eval "e=\$_EO_$e"
  done
  r=""
}

# ================= 错误 =================
mal_error() { MAL_ERR=1; MAL_ERR_MSG="$1"; }

# ================= 字符串转义（纯 dash，零 fork） =================
unescape_str() {  # $1=带转义内容 -> r=原始内容
  local s="$1" out="" c d
  while [ -n "$s" ]; do
    c=${s%"${s#?}"}
    s=${s#?}
    if [ "$c" = '\' ] && [ -n "$s" ]; then
      d=${s%"${s#?}"}
      s=${s#?}
      case "$d" in
        n) out="$out$NL" ;;
        t) out="$out$TAB" ;;
        '"') out="$out\"" ;;
        '\') out="$out\\" ;;
        *) out="$out$d" ;;
      esac
    else
      out="$out$c"
    fi
  done
  r="$out"
}
escape_str() {  # $1=原始内容 -> r=可读转义串
  local s="$1" out="" c
  while [ -n "$s" ]; do
    c=${s%"${s#?}"}
    s=${s#?}
    case "$c" in
      '\') out="$out\\\\" ;;
      '"') out="$out\\\"" ;;
      "$NL") out="$out\\n" ;;
      *) out="$out$c" ;;
    esac
  done
  r="$out"
}

# ================= Tokenizer（纯 dash 字符剥离，零 fork） =================
emit_token() {
  _et_t="$1"
  _TK_N=$((_TK_N+1))
  eval "_TK_$_TK_N=\$_et_t"
}
get_tok() { eval "r=\$_TK_$1"; }

TOKENIZE() {
  local s="$1" c nxt tok c2 closed rest
  _TK_N=0
  while [ -n "$s" ]; do
    c=${s%"${s#?}"}
    s=${s#?}
    case "$c" in
      ' '|"$TAB"|"$NL"|',')
        continue
        ;;
      ';')
        # 注释到行尾为止。load-file 会把整个文件当作一次输入喂进来，
        # 所以这里绝不能像单行 REPL 那样直接清空 s —— 那会吞掉后面所有行。
        rest=${s#*"$NL"}
        if [ "$rest" = "$s" ]; then s=""; else s="$rest"; fi
        continue
        ;;
      '"')
        # 字符串：原样保留转义，含首尾引号。
        # closed 标志必须在扫描中显式记录 —— 事后靠「是否以 " 结尾」判断会被
        # 奇数个反斜杠（如 "\\\\\" ）骗过去。未闭合时只 emit 裸 " ，由 reader 报错。
        tok='"'
        closed=0
        while [ -n "$s" ]; do
          c=${s%"${s#?}"}
          s=${s#?}
          if [ "$c" = '\' ]; then
            tok="$tok$c"
            if [ -n "$s" ]; then
              c2=${s%"${s#?}"}
              s=${s#?}
              tok="$tok$c2"
            fi
          elif [ "$c" = '"' ]; then
            tok="$tok$c"
            closed=1
            break
          else
            tok="$tok$c"
          fi
        done
        if [ $closed -eq 1 ]; then emit_token "$tok"; else emit_token '"'; fi
        continue
        ;;
      '('|')'|'['|']'|'{'|'}'|"'"|'`'|'^'|'@')
        emit_token "$c"
        continue
        ;;
      '~')
        if [ -n "$s" ]; then
          nxt=${s%"${s#?}"}
          if [ "$nxt" = '@' ]; then
            s=${s#?}
            emit_token '~@'
            continue
          fi
        fi
        emit_token '~'
        continue
        ;;
      *)
        # 符号/数字/关键字：只在空白、, ; ( ) [ ] { } ' " ` 处断开
        tok="$c"
        while [ -n "$s" ]; do
          nxt=${s%"${s#?}"}
          case "$nxt" in
            ' '|"$TAB"|"$NL"|','|';'|'('|')'|'['|']'|'{'|'}'|"'"|'"'|'`') break ;;
            *) s=${s#?}; tok="$tok$nxt" ;;
          esac
        done
        emit_token "$tok"
        continue
        ;;
    esac
  done
}

# ================= Reader =================
READ() {  # $1=一行源码 -> r=AST ref
  TOKENIZE "$1"
  _TOK_POS=1
  if [ "$_TK_N" -eq 0 ]; then r=Z; MAL_BLANK=1; return; fi
  MAL_BLANK=0
  READ_FORM
}

READ_FORM() {  # -> r
  local tok inner esc q qs meta
  if [ "$_TOK_POS" -gt "$_TK_N" ]; then
    mal_error "unbalanced: unexpected end of input"
    return
  fi
  get_tok "$_TOK_POS"
  tok="$r"
  case "$tok" in
    '(')
      _TOK_POS=$((_TOK_POS+1))
      READ_SEQ ')' list
      return ;;
    '[')
      _TOK_POS=$((_TOK_POS+1))
      READ_SEQ ']' vec
      return ;;
    '{')
      _TOK_POS=$((_TOK_POS+1))
      READ_MAP
      return ;;
    ')'|']'|'}')
      mal_error "unbalanced: unexpected '$tok'"
      return ;;
    "'")  _TOK_POS=$((_TOK_POS+1)); READ_WRAP quote ; return ;;
    '`')  _TOK_POS=$((_TOK_POS+1)); READ_WRAP quasiquote ; return ;;
    '~')  _TOK_POS=$((_TOK_POS+1)); READ_WRAP unquote ; return ;;
    '~@') _TOK_POS=$((_TOK_POS+1)); READ_WRAP splice-unquote ; return ;;
    '@')  _TOK_POS=$((_TOK_POS+1)); READ_WRAP deref ; return ;;
    '^')
      _TOK_POS=$((_TOK_POS+1))
      READ_FORM
      if [ "$MAL_ERR" = 1 ]; then return; fi
      meta="$r"
      READ_FORM
      if [ "$MAL_ERR" = 1 ]; then return; fi
      q="$r"
      mal_sym with-meta
      qs="$r"
      mal_list "$qs" "$q" "$meta"
      return ;;
    '"'*)
      _TOK_POS=$((_TOK_POS+1))
      # tokenizer 保证：裸 " 代表未闭合，其余必然是完整的 "..." 形式
      if [ "$tok" = '"' ]; then
        mal_error "unbalanced: unexpected end of input in string"
        return
      fi
      inner=${tok#?}
      inner=${inner%?}
      unescape_str "$inner"
      esc="$r"
      mal_str "$esc"
      return ;;
    *)
      _TOK_POS=$((_TOK_POS+1))
      classify_atom "$tok"
      return ;;
  esac
}

READ_WRAP() {  # $1=符号名，把下一个 form 包成 (符号 form)
  local sym="$1" inner symref
  READ_FORM
  if [ "$MAL_ERR" = 1 ]; then return; fi
  inner="$r"
  mal_sym "$sym"
  symref="$r"
  mal_list "$symref" "$inner"
}

READ_SEQ() {  # $1=结束符 $2=list|vec
  local close="$1" kind="$2" elems="" tok el
  while true; do
    if [ "$_TOK_POS" -gt "$_TK_N" ]; then
      mal_error "unbalanced: unexpected end of input"
      return
    fi
    get_tok "$_TOK_POS"
    tok="$r"
    if [ "$tok" = "$close" ]; then
      _TOK_POS=$((_TOK_POS+1))
      break
    fi
    READ_FORM
    if [ "$MAL_ERR" = 1 ]; then return; fi
    el="$r"
    elems="$elems $el"
  done
  elems=${elems# }
  if [ "$kind" = vec ]; then mal_vec $elems; else mal_list $elems; fi
}

READ_MAP() {
  local pairs="" tok kref vref
  while true; do
    if [ "$_TOK_POS" -gt "$_TK_N" ]; then
      mal_error "unbalanced: unexpected end of input"
      return
    fi
    get_tok "$_TOK_POS"
    tok="$r"
    if [ "$tok" = '}' ]; then
      _TOK_POS=$((_TOK_POS+1))
      break
    fi
    READ_FORM
    if [ "$MAL_ERR" = 1 ]; then return; fi
    kref="$r"
    if [ "$_TOK_POS" -gt "$_TK_N" ]; then
      mal_error "unbalanced: unexpected end of input"
      return
    fi
    get_tok "$_TOK_POS"
    tok="$r"
    if [ "$tok" = '}' ]; then
      mal_error "map literal must contain an even number of forms"
      return
    fi
    READ_FORM
    if [ "$MAL_ERR" = 1 ]; then return; fi
    vref="$r"
    pairs="$pairs $kref $vref"
  done
  pairs=${pairs# }
  mal_map $pairs
}

classify_atom() {  # $1=token -> r
  local tok="$1" body
  case "$tok" in
    nil) r=Z; return ;;
    true) r=Y; return ;;
    false) r=F; return ;;
    ':'*) mal_kw "${tok#:}"; return ;;
  esac
  body=${tok#-}
  case "$body" in
    ''|*[!0-9]*) ;;
    *) mal_num "$tok"; return ;;
  esac
  mal_sym "$tok"
}

# ================= Printer =================
pr_str() {  # $1=ref $2=readable(0/1) -> r_str
  local ref="$1" readable="$2"
  local t inner first e result pairs k v kp vp content elems num
  mal_type "$ref"
  t="$r"
  case "$t" in
    __nil) r_str="nil"; return ;;
    __true) r_str="true"; return ;;
    __false) r_str="false"; return ;;
    __num)
      mal_val "$ref"
      num="$r"
      r_str="$num"
      return ;;
    __sym)
      mal_val "$ref"
      r_str="$r"
      return ;;
    __kw)
      mal_val "$ref"
      r_str=":$r"
      return ;;
    __str)
      mal_val "$ref"
      content="$r"
      if [ "$readable" = 1 ]; then
        escape_str "$content"
        inner="$r"
        r_str="\"$inner\""
      else
        r_str="$content"
      fi
      return ;;
    __list|__vec)
      mal_val "$ref"
      elems="$r"
      if [ "$t" = __list ]; then result="("; else result="["; fi
      first=1
      for e in $elems; do
        pr_str "$e" "$readable"
        inner="$r_str"
        if [ $first -eq 1 ]; then first=0; else result="$result "; fi
        result="$result$inner"
      done
      if [ "$t" = __list ]; then r_str="$result)"; else r_str="$result]"; fi
      return ;;
    __map)
      mal_val "$ref"
      pairs="$r"
      result="{"
      first=1
      while [ -n "$pairs" ]; do
        k=${pairs%% *}
        if [ "$k" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
        v=${pairs%% *}
        if [ "$v" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
        pr_str "$k" "$readable"
        kp="$r_str"
        pr_str "$v" "$readable"
        vp="$r_str"
        if [ $first -eq 1 ]; then first=0; else result="$result "; fi
        result="$result$kp $vp"
      done
      r_str="$result}"
      return ;;
    __atom)
      mal_val "$ref"
      inner="$r"
      pr_str "$inner" "$readable"
      r_str="(atom $r_str)"
      return ;;
    __fn) r_str="#<function>"; return ;;
    *) r_str="" ;;
  esac
}
PRINT() { pr_str "$1" 1; }

# ================= EVAL =================
# 叶子快速求值。
#
# 存在的理由纯粹是性能：EVAL 顶部有 20+ 个 local 声明，而 dash 的变量表是
# 固定桶数的哈希表 —— 解释器跑起来之后表里塞满了 _V_/_EB_/_EO_，每个 local
# 都要在退化的桶链表里线性查找。实测 20000 次「25 个 local 的函数调用」，
# 变量表干净时 0.7s，表里有 20000 个残留变量时 85s。
#
# 而真实程序里绝大多数求值对象是符号和字面量（(+ n acc) 的三个子项全是叶子）。
# 本函数只用位置参数、零 local，把这些叶子挡在 EVAL 之外，只把容器转交过去。
# DEBUG-EVAL 打开时一律退回完整 EVAL，保证追踪输出不缺项。
_ev1() {  # $1=ast $2=env -> r
  case "$1" in
    L*|V*|H*) EVAL "$1" "$2"; return ;;
    S*)
      if [ "$_MAL_DBG_SEEN" = 1 ]; then EVAL "$1" "$2"; return; fi
      env_get "$2" "${1#S}"
      if [ -z "$r" ]; then mal_error "'${1#S}' not found"; fi
      return ;;
    *)
      if [ "$_MAL_DBG_SEEN" = 1 ]; then EVAL "$1" "$2"; return; fi
      r="$1"
      return ;;
  esac
}

# 尾调用优化（TCO）：本函数是一个 while 循环，不是递归。
# 处于尾位置的求值（let*/do 的最后一个表达式、if 选中的分支、mal 闭包的 body）
# 不递归调用自己，而是改写 ast/env 后 continue。这样 (sum2 10000 0) 这类
# 尾递归只占一个 shell 栈帧。非尾位置（参数、绑定值、条件）仍然递归。
EVAL() {  # $1=ast ref $2=env -> r
  local ast="$1" env="$2"
  local t first elems e evaled f fname kname val nenv
  local bindrefs kref vref cond p params pnames pairs k v kk vv
  local kind fnname clparams clbody clenv
  local pend="" pendclos=$_MAL_NCLOS
  while true; do
  if [ "$MAL_ERR" = 1 ]; then return; fi
  if [ "$STEPNUM" -le 1 ]; then r="$ast"; return; fi

  # DEBUG-EVAL：环境中该符号为真值时，求值前打印形式（nil/false 之外都算真，含 () 0 ""）
  if [ "$_MAL_DBG_SEEN" = 1 ]; then
    env_get "$env" 'DEBUG-EVAL'
    if [ -n "$r" ] && [ "$r" != Z ] && [ "$r" != F ]; then
      pr_str "$ast" 1
      printf 'EVAL: %s\n' "$r_str"
    fi
  fi

  mal_type "$ast"
  t="$r"
  case "$t" in
    __sym)
      mal_val "$ast"
      fname="$r"
      env_get "$env" "$fname"
      if [ -z "$r" ]; then mal_error "'$fname' not found"; return; fi
      return ;;

    __vec)
      mal_val "$ast"
      elems="$r"
      evaled=""
      for e in $elems; do
        _ev1 "$e" "$env"
        if [ "$MAL_ERR" = 1 ]; then return; fi
        evaled="$evaled $r"
      done
      mal_vec $evaled
      return ;;

    __map)
      mal_val "$ast"
      pairs="$r"
      evaled=""
      while [ -n "$pairs" ]; do
        k=${pairs%% *}
        if [ "$k" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
        v=${pairs%% *}
        if [ "$v" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
        _ev1 "$k" "$env"
        if [ "$MAL_ERR" = 1 ]; then return; fi
        kk="$r"
        _ev1 "$v" "$env"
        if [ "$MAL_ERR" = 1 ]; then return; fi
        vv="$r"
        evaled="$evaled $kk $vv"
      done
      mal_map $evaled
      return ;;

    __list) ;;
    *) r="$ast"; return ;;
  esac

  # ---- 列表 ----
  mal_val "$ast"
  elems="$r"
  if [ -z "$elems" ]; then r="$ast"; return; fi
  first=${elems%% *}

  fname=""
  mal_type "$first"
  if [ "$r" = __sym ]; then
    mal_val "$first"
    fname="$r"
  fi
  if [ "$STEPNUM" -lt 3 ]; then fname=""; fi

  case "$fname" in
    'def!')
      set -- $elems
      mal_type "$2"
      if [ "$r" != __sym ]; then mal_error "def! requires a symbol"; return; fi
      mal_val "$2"
      kname="$r"
      _ev1 "$3" "$env"
      if [ "$MAL_ERR" = 1 ]; then return; fi
      val="$r"
      env_set "$env" "$kname" "$val"
      r="$val"
      return ;;

    'let*')
      set -- $elems
      env_new "$env"
      nenv="$r"
      mal_val "$2"
      bindrefs="$r"
      while [ -n "$bindrefs" ]; do
        kref=${bindrefs%% *}
        if [ "$kref" = "$bindrefs" ]; then bindrefs=""; else bindrefs=${bindrefs#* }; fi
        vref=${bindrefs%% *}
        if [ "$vref" = "$bindrefs" ]; then bindrefs=""; else bindrefs=${bindrefs#* }; fi
        mal_val "$kref"
        kname="$r"
        _ev1 "$vref" "$nenv"
        if [ "$MAL_ERR" = 1 ]; then return; fi
        env_set "$nenv" "$kname" "$r"
      done
      ast="$3"
      env="$nenv"
      pend="$pend $nenv"                            # 外链指向当前 env，只能随当前链一起回收
      continue ;;                                   # TCO：body 在尾位置
  esac

  if [ "$STEPNUM" -lt 4 ]; then fname=""; fi

  case "$fname" in
    'if')
      set -- $elems
      _ev1 "$2" "$env"
      if [ "$MAL_ERR" = 1 ]; then return; fi
      cond="$r"
      if [ "$cond" = Z ] || [ "$cond" = F ]; then
        if [ -n "$4" ]; then ast="$4"; else r=Z; return; fi
      else
        ast="$3"
      fi
      continue ;;                                   # TCO：选中的分支在尾位置

    'fn*')
      set -- $elems
      mal_val "$2"
      params="$r"
      pnames=""
      for p in $params; do
        mal_val "$p"
        pnames="$pnames $r"
      done
      pnames=${pnames# }
      mal_closure_mal "$pnames" "$3" "$env"
      return ;;

    'do')
      set -- $elems
      shift
      if [ $# -eq 0 ]; then r=Z; return; fi
      while [ $# -gt 1 ]; do
        _ev1 "$1" "$env"
        if [ "$MAL_ERR" = 1 ]; then return; fi
        shift
      done
      ast="$1"
      continue ;;                                   # TCO：最后一个表达式在尾位置

    'quote')
      set -- $elems
      r="$2"
      return ;;

    'quasiquote')
      set -- $elems
      _quasiquote "$2" "$env"
      if [ "$MAL_ERR" = 1 ]; then return; fi
      ast="$r"
      continue ;;                                   # 展开结果在尾位置求值
  esac

  if [ "$STEPNUM" -lt 7 ]; then fname=""; fi

  case "$fname" in
    'unquote'|'splice-unquote')
      mal_error "unquote outside of quasiquote"
      return ;;
  esac

  # ---- 通用调用 ----
  evaled=""
  for e in $elems; do
    _ev1 "$e" "$env"
    if [ "$MAL_ERR" = 1 ]; then return; fi
    evaled="$evaled $r"
  done
  set -- $evaled
  f="$1"
  shift
  mal_type "$f"
  if [ "$r" != __fn ]; then mal_error "not a function"; return; fi
  closure_get "$f"
  kind="$r_kind"
  fnname="$r_fn"
  clparams="$r_params"
  clbody="$r_body"
  clenv="$r_env"
  if [ "$kind" = native ]; then
    "$fnname" "$@"
    return
  fi
  env_new "$clenv"
  nenv="$r"
  bind_params "$clparams" "$nenv" "$@"
  if [ "$MAL_ERR" = 1 ]; then return; fi
  # 环境回收：新环境的外链是闭包捕获的 clenv，与当前这条链无关，所以本轮循环
  # 自己造出来的那些 env 到此都成了垃圾 —— 前提是期间没有闭包把它们捕获走。
  # mal_closure_mal 是 env 唯一的逃逸出口，比一下计数即可判定。
  # 不回收的话，深递归会把 dash 那张定长哈希表撑爆，每个 local 都退化成线性搜索。
  if [ -n "$pend" ] && [ "$_MAL_NCLOS" = "$pendclos" ]; then
    for e in $pend; do
      eval "unset _EB_$e _EO_$e"
    done
  fi
  pend="$nenv"
  pendclos=$_MAL_NCLOS
  ast="$clbody"
  env="$nenv"
  continue                                          # TCO：闭包 body 在尾位置
  done
}

APPLY() {  # $1=函数ref 其余=实参ref
  local f="$1"
  shift
  local t kind fnname params body clenv nenv
  if [ "$MAL_ERR" = 1 ]; then return; fi
  mal_type "$f"
  t="$r"
  if [ "$t" != __fn ]; then mal_error "not a function"; return; fi
  closure_get "$f"
  kind="$r_kind"
  fnname="$r_fn"
  params="$r_params"
  body="$r_body"
  clenv="$r_env"
  if [ "$kind" = native ]; then
    "$fnname" "$@"
    return
  fi
  env_new "$clenv"
  nenv="$r"
  bind_params "$params" "$nenv" "$@"
  if [ "$MAL_ERR" = 1 ]; then return; fi
  EVAL "$body" "$nenv"
}

# -------- step7：quasiquote 展开 --------
# 与参考实现一致：返回一段“代码”（cons 链 + quote 包装），由调用方 eval。
# dash 没有动态作用域，env 必须显式传递。
_quasiquote() {  # $1=ast ref $2=env -> r=展开后的代码 AST（由调用方 eval）
  local ast="$1" env="$2"
  local t elems first rest fname arg
  # 中间值全部 local 化：dash 的 local 在函数退出时恢复外层值，
  # 所以递归层之间同名也不会互相污染。
  local qq_sym qq_rest_ref qq_head qq_tail
  mal_type "$ast"
  t="$r"
  case "$t" in
    __list|__vec)
      mal_val "$ast"
      elems="$r"
      if [ -z "$elems" ]; then
        # 空序列：包 (quote ()) / (quote [])
        mal_sym quote; qq_sym="$r"
        mal_list "$qq_sym" "$ast"
        return
      fi
      # 拆 head / tail（tail 重新包成 list ref 递归）
      first=${elems%% *}
      if [ "$elems" = "$first" ]; then rest=""; else rest=${elems#* }; fi
      if [ -n "$rest" ]; then mal_list $rest; else mal_list; fi
      qq_rest_ref="$r"
      # head 是否为 unquote / splice-unquote（符号形式，整个列表就是 (unquote x)）
      # 或列表形式 ((unquote x) ...)（元素级，由递归处理）
      fname=""; arg=""; qq_whole=""
      mal_type "$first"
      if [ "$r" = __sym ]; then
        mal_val "$first"; fname="$r"
        # (unquote x) 整个：fname=unquote，arg 是 $2，且列表只有两个元素
        set -- $elems
        arg="$2"
        if [ $# -eq 2 ]; then qq_whole=1; fi
      elif [ "$r" = __list ]; then
        mal_val "$first"
        if [ -n "$r" ]; then
          set -- $r
          mal_type "$1"
          if [ "$r" = __sym ]; then
            mal_val "$1"; fname="$r"
          fi
          arg="$2"
        fi
      fi
      if [ "$fname" = unquote ] && [ -n "$qq_whole" ]; then
        r="$arg"
        return
      fi
      if [ "$fname" = splice-unquote ]; then
        # (concat x (quasiquote tail))
        _quasiquote "$qq_rest_ref" "$env"
        if [ "$MAL_ERR" = 1 ]; then return; fi
        qq_tail="$r"
        mal_sym concat; qq_sym="$r"
        mal_list "$qq_sym" "$arg" "$qq_tail"
        return
      fi
      # 普通： (cons (quasiquote head) (quasiquote tail))
      _quasiquote "$first" "$env"
      if [ "$MAL_ERR" = 1 ]; then return; fi
      qq_head="$r"
      _quasiquote "$qq_rest_ref" "$env"
      if [ "$MAL_ERR" = 1 ]; then return; fi
      qq_tail="$r"
      mal_sym cons; qq_sym="$r"
      mal_list "$qq_sym" "$qq_head" "$qq_tail"
      if [ "$t" = __vec ]; then
        # 向量整体包 (vec ...)
        mal_sym vec; qq_sym="$r"
        mal_list "$qq_sym" "$r"
      fi
      return ;;
    *)
      # 非序列：包 (quote ast) 防止被外层 eval
      mal_sym quote; qq_sym="$r"
      mal_list "$qq_sym" "$ast"
      return ;;
  esac
}

bind_params() {  # $1=形参名串 $2=env 其余=实参ref
  local params="$1" env="$2"
  shift 2
  local p in_more morename
  in_more=0
  morename=""
  for p in $params; do
    if [ "$p" = '&' ]; then in_more=1; continue; fi
    if [ $in_more -eq 1 ]; then morename="$p"; break; fi
    if [ $# -ge 1 ]; then
      env_set "$env" "$p" "$1"
      shift
    else
      env_set "$env" "$p" Z
    fi
  done
  if [ -n "$morename" ]; then
    mal_list "$@"
    env_set "$env" "$morename" "$r"
  fi
}

# ================= 原生函数 =================
fn_add() { local t=0 a n; for a in "$@"; do mal_val "$a"; n="$r"; t=$((t+n)); done; mal_num "$t"; }
fn_sub() {
  local t=0 first=1 a n
  for a in "$@"; do
    mal_val "$a"; n="$r"
    if [ $first -eq 1 ]; then t=$n; first=0; else t=$((t-n)); fi
  done
  mal_num "$t"
}
fn_mul() { local t=1 a n; for a in "$@"; do mal_val "$a"; n="$r"; t=$((t*n)); done; mal_num "$t"; }
fn_div() {
  local t=0 first=1 a n
  for a in "$@"; do
    mal_val "$a"; n="$r"
    if [ $first -eq 1 ]; then t=$n; first=0; else t=$((t/n)); fi
  done
  mal_num "$t"
}

fn_list() { mal_list "$@"; }
fn_list_p() { mal_type "$1"; if [ "$r" = __list ]; then r=Y; else r=F; fi; }
fn_empty_p() {
  local t
  mal_type "$1"
  t="$r"
  case "$t" in
    __nil) r=Y ;;
    __list|__vec|__map)
      mal_val "$1"
      if [ -z "$r" ]; then r=Y; else r=F; fi ;;
    *) r=F ;;
  esac
}
fn_count() {
  local t n
  mal_type "$1"
  t="$r"
  case "$t" in
    __nil) mal_num 0 ;;
    __list|__vec)
      mal_val "$1"
      set -- $r
      n=$#
      mal_num "$n" ;;
    __map)
      mal_val "$1"
      set -- $r
      n=$(( $# / 2 ))
      mal_num "$n" ;;
    *) mal_error "count: not a sequence"; r=Z ;;
  esac
}

fn_cons() {  # $1=元素 $2=list/vector -> 新 list
  local l
  mal_val "$2"
  l="$r"
  mal_list "$1" $l
}

fn_vec() {  # 参数为元素 -> 新 vector（不改原 list）
  mal_vec "$@"
}

fn_concat() {  # 参数均为 list/vector，按顺序拼接
  local out="" a
  for a in "$@"; do
    mal_val "$a"
    out="$out $r"
  done
  out=${out# }
  mal_list $out
}
fn_equal() {
  local a="$1" b="$2" ta tb ae be ax bx
  mal_type "$a"; ta="$r"
  mal_type "$b"; tb="$r"
  case "$ta" in __vec) ta=__list ;; esac
  case "$tb" in __vec) tb=__list ;; esac
  if [ "$ta" != "$tb" ]; then r=F; return; fi
  case "$ta" in
    __nil|__true|__false) r=Y ;;
    __num|__sym|__kw|__str)
      mal_val "$a"; ae="$r"
      mal_val "$b"; be="$r"
      if [ "$ae" = "$be" ]; then r=Y; else r=F; fi ;;
    __list)
      mal_val "$a"; ae="$r"
      mal_val "$b"; be="$r"
      while [ -n "$ae" ] && [ -n "$be" ]; do
        ax=${ae%% *}
        if [ "$ax" = "$ae" ]; then ae=""; else ae=${ae#* }; fi
        bx=${be%% *}
        if [ "$bx" = "$be" ]; then be=""; else be=${be#* }; fi
        fn_equal "$ax" "$bx"
        if [ "$r" = F ]; then return; fi
      done
      if [ -n "$ae" ] || [ -n "$be" ]; then r=F; else r=Y; fi ;;
    *)
      if [ "$a" = "$b" ]; then r=Y; else r=F; fi ;;
  esac
}
fn_lt() { local a b; mal_val "$1"; a="$r"; mal_val "$2"; b="$r"; if [ "$a" -lt "$b" ]; then r=Y; else r=F; fi; }
fn_gt() { local a b; mal_val "$1"; a="$r"; mal_val "$2"; b="$r"; if [ "$a" -gt "$b" ]; then r=Y; else r=F; fi; }
fn_le() { local a b; mal_val "$1"; a="$r"; mal_val "$2"; b="$r"; if [ "$a" -le "$b" ]; then r=Y; else r=F; fi; }
fn_ge() { local a b; mal_val "$1"; a="$r"; mal_val "$2"; b="$r"; if [ "$a" -ge "$b" ]; then r=Y; else r=F; fi; }

_join_args() {  # $1=readable $2=分隔符 其余=refs -> r_join
  local readable="$1" sep="$2"
  shift 2
  local out="" first=1 a s
  for a in "$@"; do
    pr_str "$a" "$readable"
    s="$r_str"
    if [ $first -eq 1 ]; then first=0; else out="$out$sep"; fi
    out="$out$s"
  done
  r_join="$out"
}
fn_pr_str() { _join_args 1 ' ' "$@"; mal_str "$r_join"; }
fn_str()    { _join_args 0 ''  "$@"; mal_str "$r_join"; }
fn_prn()    { _join_args 1 ' ' "$@"; printf '%s\n' "$r_join"; r=Z; }
fn_println(){ _join_args 0 ' ' "$@"; printf '%s\n' "$r_join"; r=Z; }

# -------- step6：文件与求值 --------
fn_read_string() {
  local s
  mal_val "$1"
  s="$r"
  READ "$s"
  # 整串都是注释/空白时 READ 置 MAL_BLANK，按 nil 处理而不是报错
  if [ "$MAL_BLANK" = 1 ]; then r=Z; fi
}

fn_slurp() {
  local path content line
  mal_val "$1"
  path="$r"
  if [ ! -f "$path" ]; then mal_error "slurp: cannot open '$path'"; return; fi
  content=""
  line=""
  # 重定向不 fork。read 每次剥掉换行符，所以要手工补回去。
  while IFS= read -r line; do
    content="$content$line$NL"
  done < "$path"
  # 最后一行没有换行符时 read 返回非零，但 line 里已有内容
  if [ -n "$line" ]; then content="$content$line"; fi
  mal_str "$content"
}

fn_eval() { EVAL "$1" "$REPL_ENV"; }   # 一律在根环境求值，不看调用点的局部环境

# -------- step6：atom --------
fn_atom()   { mal_atom "$1"; }
fn_atom_p() { case "$1" in A*) r=Y ;; *) r=F ;; esac; }
fn_deref()  {
  mal_type "$1"
  if [ "$r" != __atom ]; then mal_error "deref: not an atom"; return; fi
  mal_val "$1"
}
fn_reset()  {
  mal_type "$1"
  if [ "$r" != __atom ]; then mal_error "reset!: not an atom"; return; fi
  _set_stored "$1" "$2"
  r="$2"
}
fn_swap() {
  local a="$1" f="$2" cur
  shift 2
  mal_type "$a"
  if [ "$r" != __atom ]; then mal_error "swap!: not an atom"; return; fi
  mal_val "$a"
  cur="$r"
  APPLY "$f" "$cur" "$@"
  if [ "$MAL_ERR" = 1 ]; then return; fi
  _set_stored "$a" "$r"
}

# ================= REPL 环境 =================
init_repl_env() {
  local e
  env_new ""
  REPL_ENV="$r"
  e="$REPL_ENV"
  mal_closure_native fn_add; env_set "$e" '+' "$r"
  mal_closure_native fn_sub; env_set "$e" '-' "$r"
  mal_closure_native fn_mul; env_set "$e" '*' "$r"
  mal_closure_native fn_div; env_set "$e" '/' "$r"
  if [ "$STEPNUM" -ge 4 ]; then
    mal_closure_native fn_list;    env_set "$e" 'list' "$r"
    mal_closure_native fn_list_p;  env_set "$e" 'list?' "$r"
    mal_closure_native fn_empty_p; env_set "$e" 'empty?' "$r"
    mal_closure_native fn_count;   env_set "$e" 'count' "$r"
    mal_closure_native fn_equal;   env_set "$e" '=' "$r"
    mal_closure_native fn_lt;      env_set "$e" '<' "$r"
    mal_closure_native fn_le;      env_set "$e" '<=' "$r"
    mal_closure_native fn_gt;      env_set "$e" '>' "$r"
    mal_closure_native fn_ge;      env_set "$e" '>=' "$r"
    mal_closure_native fn_pr_str;  env_set "$e" 'pr-str' "$r"
    mal_closure_native fn_str;     env_set "$e" 'str' "$r"
    mal_closure_native fn_prn;     env_set "$e" 'prn' "$r"
    mal_closure_native fn_println; env_set "$e" 'println' "$r"
    rep_silent '(def! not (fn* (a) (if a false true)))'
  fi
  if [ "$STEPNUM" -ge 7 ]; then
    mal_closure_native fn_cons;   env_set "$e" 'cons' "$r"
    mal_closure_native fn_concat; env_set "$e" 'concat' "$r"
    mal_closure_native fn_vec;    env_set "$e" 'vec' "$r"
  fi
  if [ "$STEPNUM" -ge 6 ]; then
    mal_closure_native fn_read_string; env_set "$e" 'read-string' "$r"
    mal_closure_native fn_slurp;       env_set "$e" 'slurp' "$r"
    mal_closure_native fn_eval;        env_set "$e" 'eval' "$r"
    mal_closure_native fn_atom;        env_set "$e" 'atom' "$r"
    mal_closure_native fn_atom_p;      env_set "$e" 'atom?' "$r"
    mal_closure_native fn_deref;       env_set "$e" 'deref' "$r"
    mal_closure_native fn_reset;       env_set "$e" 'reset!' "$r"
    mal_closure_native fn_swap;        env_set "$e" 'swap!' "$r"
    mal_list
    env_set "$e" '*ARGV*' "$r"
    # 尾部的 \nnil 有两个作用：让最后一行的注释不吞掉收尾括号，以及让返回值恒为 nil
    rep_silent '(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))'
  fi
}

rep_silent() {
  MAL_ERR=0
  MAL_ERR_MSG=""
  READ "$1"
  if [ "$MAL_ERR" = 1 ]; then return; fi
  EVAL "$r" "$REPL_ENV"
}

# ================= REPL 主循环 =================
mal_repl() {
  local line
  while true; do
    printf 'user> '
    IFS= read -r line || break
    if [ "$STEPNUM" = 0 ]; then
      printf '%s\n' "$line"
      continue
    fi
    MAL_ERR=0
    MAL_ERR_MSG=""
    MAL_BLANK=0
    READ "$line"
    if [ "$MAL_ERR" = 1 ]; then
      printf '%s\n' "$MAL_ERR_MSG"
      continue
    fi
    if [ "$MAL_BLANK" = 1 ]; then continue; fi
    EVAL "$r" "$REPL_ENV"
    if [ "$MAL_ERR" = 1 ]; then
      printf '%s\n' "$MAL_ERR_MSG"
      continue
    fi
    PRINT "$r"
    printf '%s\n' "$r_str"
  done
}
