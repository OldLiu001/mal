#!/bin/dash
# ============================================================
# types.sh —— mal 值模型（官方 types.qx）
# 类型标签 ref、构造器、存储、GC、内联小对象、错误机制
# ============================================================
set -f
STEPNUM=10
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
MAL_ERR_VAL=""        # throw 时保存被抛的值 ref；非 throw 错误为空
_TK_N=0
_TOK_POS=1
_MAL_NEXT=0
_MAL_NCLOS=0
_MAL_DBG_SEEN=0
REPL_ENV=""
TAB='	'
NL='
'

# ================= 存储（零 fork，任意内容安全） =================
_set_stored() {  # $1=ref $2=内容（创建：登记 GC 桶）
  _ss_tmp="$2"
  eval "_V_$1=\$_ss_tmp"
  gc_reg "$1"
}

_update_stored() {  # $1=ref $2=内容（更新已有对象：不重复登记）
  _ss_tmp="$2"
  eval "_V_$1=\$_ss_tmp"
}

_get_stored() {  # $1=ref -> r
  eval "r=\$_V_$1"
}

new_id() { _MAL_NEXT=$((_MAL_NEXT+1)); r=$_MAL_NEXT; }

# ================= GC（方案 C：Mark-Sweep） =================
# 只回收存储型对象（L/V/H/G/A 的 _V_、闭包的 _CK_ 六件套），环境由 pend 机制管。
# 登记：对象创建时按 id/256 追加到桶变量 _GC_B<桶>（摊还 O(1)）。
# 标记：从根（REPL_ENV）DFS，_GC_<ref>=1 防重；环境无环不设标记直接展开。
# 清扫：遍历桶，未标记的 unset；触发点在 REPL 顶层等安全点（调用栈为空）。
_GC_LAST=0
_GC_THRESH=${GC_THRESH:-30000}
_GC_BUCKET=256

gc_reg() {  # $1=ref（存储型）-> 登记到桶
  local id=${1#?} b
  b=$((id/_GC_BUCKET))
  eval "_GC_B$b=\"\$_GC_B$b $1\""
}

gc_mark() {  # $1=ref
  local ref="$1" t kv e2
  case "$ref" in
    L'*'*|V'*'*|H'*'*)
      # 内联对象：不占变量表、不可能有 meta，直接展开子元素即可
      mal_val "$ref"
      for e in $r; do gc_mark "$e"; done
      return ;;
    L*|V*|H*|G*|A*)
      eval "if [ \"\${_GC_$ref+x}\" = x ]; then return; fi; _GC_$ref=1"
      mal_type "$ref"
      t="$r"
      case "$t" in
        __list|__vec|__map)
          mal_val "$ref"
          for e in $r; do gc_mark "$e"; done
          ;;
        __atom)
          mal_val "$ref"
          if [ -n "$r" ]; then gc_mark "$r"; fi
          ;;
      esac
      eval "if [ -n \"\$_MM_$ref\" ]; then gc_mark \"\$_MM_$ref\"; fi"
      ;;
    C*)
      eval "if [ \"\${_GC_$ref+x}\" = x ]; then return; fi; _GC_$ref=1"
      # 闭包的可达对象：形参 list、body list、捕获环境、meta
      eval "gc_mark \"\$_CP_$ref\""
      eval "gc_mark \"\$_CB_$ref\""
      eval "gc_mark \"\$_CE_$ref\""
      eval "if [ -n \"\$_MM_$ref\" ]; then gc_mark \"\$_MM_$ref\"; fi"
      ;;
    E*)
      # 环境链无环（_EO_ 只指向更早创建的环境），重复展开只是浪费不算错
      eval "kv=\$_EB_$ref"
      eval "e2=\$_EO_$ref"
      set -- $kv
      if [ $# -ge 1 ]; then
        shift                               # _EB_ 格式 " =名 值 =名 值 ..."
        while [ $# -ge 1 ]; do
          gc_mark "$1"                      # 偶数位是值 ref
          if [ $# -ge 2 ]; then shift 2; else break; fi
        done
      fi
      if [ -n "$e2" ]; then gc_mark "$e2"; fi
      ;;
  esac
}

gc_sweep() {
  local b start end list newlist ref
  gc_mark "$REPL_ENV"                  # 先标记根：REPL_ENV 可达的一切都存活
  b=0
  end=$((_MAL_NEXT/_GC_BUCKET))
  while [ $b -le $end ]; do
    eval "list=\$_GC_B$b"
    if [ -z "$list" ]; then b=$((b+1)); continue; fi
    newlist=""
    for ref in $list; do
      eval "gc_alive=\${_GC_$ref+x}"
      if [ -n "$gc_alive" ]; then
        newlist="$newlist $ref"
        eval "unset _GC_$ref"
      else
        case "$ref" in
          C*) eval "unset _CK_$ref _CF_$ref _CP_$ref _CB_$ref _CE_$ref _CM_$ref" ;;
          *)  eval "unset _V_$ref" ;;
        esac
        eval "if [ -n \"\$_MM_$ref\" ]; then unset _MM_$ref; fi"
      fi
    done
    eval "_GC_B$b=\"${newlist# }\""
    b=$((b+1))
  done
  _GC_LAST=$_MAL_NEXT
}

gc_maybe() {  # 安全点：REPL 顶层 / load-file 后调用
  if [ $((_MAL_NEXT - _GC_LAST)) -ge $_GC_THRESH ]; then
    gc_sweep
  fi
}



# ---- 内联小对象（方案 E）----
# list/vector/hash-map 的载荷若较短且不含 US（\x1f），直接编码进 ref：
#   L*<空格->\x1f>  V*<...>  H*<...>
# 不占变量表，缓解 dash 定长哈希表退化。存储型仍是 L<id>/V<id>/H<id>。
US=$(printf '\037')
_MAL_INLINE_MAX=40

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
    G*|A*) _get_stored "$1" ;;
    L*|V*|H*)
      case "$1" in
        L'*'*|V'*'*|H'*'*)
          r=${1#??}
          # 解码：US -> 空格（IFS 分词重连）
          local _oldifs="$IFS"
          IFS="$US"
          set -- $r
          IFS="$_oldifs"
          r="$*"
          ;;
        *) _get_stored "$1" ;;
      esac ;;
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
  local payload="$*"
  if [ "${#payload}" -le "$_MAL_INLINE_MAX" ] && [ "${payload#*"$US"}" = "$payload" ]; then
    local _oldifs="$IFS"
    IFS=' '
    set -- $payload
    IFS="$US"
    r="$*"
    IFS="$_oldifs"
    r="L*$r"
  else
    local id
    new_id
    id=$r
    _set_stored "L$id" "$payload"
    r="L$id"
  fi
}

mal_vec() {
  local payload="$*"
  if [ "${#payload}" -le "$_MAL_INLINE_MAX" ] && [ "${payload#*"$US"}" = "$payload" ]; then
    local _oldifs="$IFS"
    IFS=' '
    set -- $payload
    IFS="$US"
    r="$*"
    IFS="$_oldifs"
    r="V*$r"
  else
    local id
    new_id
    id=$r
    _set_stored "V$id" "$payload"
    r="V$id"
  fi
}

mal_map() {
  local id input_kv k v pairs="" o k2 v2 newpairs
  input_kv="$*"
  # 去重：重复的 key 保留最后一个
  while [ -n "$input_kv" ]; do
    input_kv=${input_kv# }
    k=${input_kv%% *}
    if [ "$k" = "$input_kv" ]; then input_kv=""; else input_kv=${input_kv#* }; fi
    v=${input_kv%% *}
    if [ "$v" = "$input_kv" ]; then input_kv=""; else input_kv=${input_kv#* }; fi
    # 在已收集的 pairs 中移除旧 k
    o="$pairs"; newpairs=""
    while [ -n "$o" ]; do
      o=${o# }
      k2=${o%% *}; if [ "$k2" = "$o" ]; then o=""; else o=${o#* }; fi
      v2=${o%% *}; if [ "$v2" = "$o" ]; then o=""; else o=${o#* }; fi
      key_equal "$k2" "$k"
      if [ "$r" != Y ]; then newpairs="$newpairs $k2 $v2"; fi
    done
    pairs="${newpairs# } $k $v"
  done
  pairs=${pairs# }
  if [ "${#pairs}" -le "$_MAL_INLINE_MAX" ] && [ "${pairs#*"$US"}" = "$pairs" ]; then
    local _oldifs="$IFS"
    IFS=' '
    set -- $pairs
    IFS="$US"
    r="$*"
    IFS="$_oldifs"
    r="H*$r"
  else
    local id
    new_id
    id=$r
    _set_stored "H$id" "$pairs"
    r="H$id"
  fi
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
  eval "_CK_C$id=native ; _CF_C$id=\$1 ; _CM_C$id=0"
  gc_reg "C$id"
  r="C$id"
}

mal_closure_mal() {  # $1=形参名串 $2=body ref $3=闭包env -> r=C<id>
  local id
  new_id
  id=$r
  # 环境回收的依据：env 只可能经由闭包的 _CE_ 字段逃逸，这里是唯一的捕获点。
  _MAL_NCLOS=$((_MAL_NCLOS+1))
  eval "_CK_C$id=mal ; _CP_C$id=\$1 ; _CB_C$id=\$2 ; _CE_C$id=\$3 ; _CM_C$id=0"
  gc_reg "C$id"
  r="C$id"
}

closure_get() {  # $1=C<id> -> r_kind r_fn r_params r_body r_env r_ismacro
  eval "r_kind=\$_CK_$1 ; r_fn=\$_CF_$1 ; r_params=\$_CP_$1 ; r_body=\$_CB_$1 ; r_env=\$_CE_$1 ; r_ismacro=\$_CM_$1"
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

mal_error() { MAL_ERR=1; MAL_ERR_MSG="$1"; }

# ================= 字符串转义（纯 dash，零 fork） =================

