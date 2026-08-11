#!/bin/dash
# zsh 兼容：默认不分词（SH_WORD_SPLIT 未开），与 POSIX sh/dash/bash 的
# 字段分割行为对齐。实现依赖未加引号 $var 分词（ref 串遍历）。
if [ -n "$ZSH_VERSION" ]; then setopt SH_WORD_SPLIT; fi
# ============================================================
# core.sh —— 核心函数库（官方 core.qx）
# fn_* 全部 + key_equal + _join_args
# ============================================================
fn_list() { mal_list "$@"; }

fn_list_p() { mal_type "$1"; if [ "$r" = __list ]; then r=Y; else r=F; fi; }

fn_vector_p() { mal_type "$1"; if [ "$r" = __vec ]; then r=Y; else r=F; fi; }

fn_map_p() { mal_type "$1"; if [ "$r" = __map ]; then r=Y; else r=F; fi; }
fn_nil_p()  { mal_type "$1"; if [ "$r" = __nil ]; then r=Y; else r=F; fi; }

fn_true_p() { mal_type "$1"; if [ "$r" = __true ]; then r=Y; else r=F; fi; }
fn_false_p(){ mal_type "$1"; if [ "$r" = __false ]; then r=Y; else r=F; fi; }

# ---- hash-map 核心操作（键按值相等比较） ----
# map 载荷："k1 v1 k2 v2 ..."，k/v 都是 ref（无空格）

key_equal() {  # $1=键1 ref $2=键2 ref -> r=Y/F
  local t1 t2 v1 v2
  mal_type "$1"; t1="$r"
  mal_type "$2"; t2="$r"
  if [ "$t1" != "$t2" ]; then r=F; return; fi
  case "$t1" in
    __num|__sym|__kw|__str)
      mal_val "$1"; v1="$r"
      mal_val "$2"; v2="$r"
      if [ "$v1" = "$v2" ]; then r=Y; else r=F; fi ;;
    *) if [ "$1" = "$2" ]; then r=Y; else r=F; fi ;;
  esac
}

fn_hash_map() {  # 偶数个参数 -> H<id>
  mal_map "$@"
}

fn_assoc() {  # $1=map $2=键 $3=值 ... -> 新 map（不修改原 map）
  local m="$1" pairs k v found kk vv out=""
  shift
  mal_type "$m"
  if [ "$r" = __nil ]; then m=""; else
    mal_val "$m"; pairs="$r"
  fi
  # 先复制原键值对
  while [ -n "$pairs" ]; do
    k=${pairs%% *}
    if [ "$k" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
    v=${pairs%% *}
    if [ "$v" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
    out="$out $k $v"
  done
  # 逐个 assoc（新键追加，已存在键覆盖：先删旧再追加）
  while [ $# -ge 2 ]; do
    kk="$1"; vv="$2"; shift 2
    found=""
    # 重建 out，跳过与 kk 相等的旧键（out 前可能有前导空格，解析前先剥离）
    newout=""; k2=""; v2=""
    while [ -n "$out" ]; do
      out=${out# }
      k2=${out%% *}
      if [ "$k2" = "$out" ]; then out=""; else out=${out#* }; fi
      v2=${out%% *}
      if [ "$v2" = "$out" ]; then out=""; else out=${out#* }; fi
      key_equal "$k2" "$kk"
      if [ "$r" != Y ]; then newout="$newout $k2 $v2"; fi
    done
    out="$newout $kk $vv"
  done
  mal_map ${out# }
}

fn_get() {  # $1=map/vector/nil $2=键/索引
  local m="$1" k="$2" t pairs kk vv
  mal_type "$m"
  t="$r"
  case "$t" in
    __nil) r=Z; return ;;
    __map)
      mal_val "$m"; pairs="$r"
      while [ -n "$pairs" ]; do
        kk=${pairs%% *}
        if [ "$kk" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
        vv=${pairs%% *}
        if [ "$vv" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
        key_equal "$kk" "$k"
        if [ "$r" = Y ]; then r="$vv"; return; fi
      done
      r=Z ;;
    __vec)
      mal_val "$m"; pairs="$r"
      mal_val "$k"; kk="$r"
      local i=1 e
      for e in $pairs; do
        if [ $i -eq $kk ]; then r="$e"; return; fi
        i=$((i+1))
      done
      r=Z ;;
    *) r=Z ;;
  esac
}

fn_contains_p() {  # $1=map $2=键 -> true/false
  local m="$1" k="$2" t pairs kk vv
  mal_type "$m"
  t="$r"
  case "$t" in
    __nil) r=F; return ;;
    __map)
      mal_val "$m"; pairs="$r"
      while [ -n "$pairs" ]; do
        kk=${pairs%% *}
        if [ "$kk" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
        vv=${pairs%% *}
        if [ "$vv" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
        key_equal "$kk" "$k"
        if [ "$r" = Y ]; then r=Y; return; fi
      done
      r=F ;;
    *) r=F ;;
  esac
}

fn_keys() {  # $1=map -> list of keys
  local m="$1" pairs k v out=""
  mal_type "$m"
  if [ "$r" = __nil ]; then mal_list; return; fi
  mal_val "$m"; pairs="$r"
  while [ -n "$pairs" ]; do
    k=${pairs%% *}
    if [ "$k" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
    v=${pairs%% *}
    if [ "$v" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
    out="$out $k"
  done
  mal_list ${out# }
}

fn_vals() {  # $1=map -> list of values
  local m="$1" pairs k v out=""
  mal_type "$m"
  if [ "$r" = __nil ]; then mal_list; return; fi
  mal_val "$m"; pairs="$r"
  while [ -n "$pairs" ]; do
    k=${pairs%% *}
    if [ "$k" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
    v=${pairs%% *}
    if [ "$v" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
    out="$out $v"
  done
  mal_list ${out# }
}

fn_dissoc() {  # $1=map $2=键... -> 新 map
  local m="$1" pairs k v out="" kk
  shift
  mal_type "$m"
  if [ "$r" = __nil ]; then mal_map; return; fi
  mal_val "$m"; pairs="$r"
  while [ -n "$pairs" ]; do
    k=${pairs%% *}
    if [ "$k" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
    v=${pairs%% *}
    if [ "$v" = "$pairs" ]; then pairs=""; else pairs=${pairs#* }; fi
    # 检查 k 是否在删除列表里
    local drop="" kk
    for kk in "$@"; do
      key_equal "$k" "$kk"
      if [ "$r" = Y ]; then drop=1; break; fi
    done
    if [ -z "$drop" ]; then out="$out $k $v"; fi
  done
  mal_map ${out# }
}

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

fn_vec() {  # $1=序列 -> 提取元素组装为新 vector
  local ref="$1" elems
  mal_val "$ref"
  elems="$r"
  mal_vec $elems
}

fn_vector() {  # 可变参数 -> 新 vector
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

fn_nth() {  # $1=list/vector $2=索引 -> 元素
  local t elems i e n
  mal_type "$1"
  t="$r"
  case "$t" in
    __list|__vec)
      mal_val "$1"
      elems="$r"
      mal_val "$2"
      i=$r
      n=0
      for e in $elems; do
        if [ "$n" = "$i" ]; then r="$e"; return; fi
        n=$((n+1))
      done
      mal_error "nth: index out of range"
      r=Z ;;
    __nil)
      mal_error "nth: nil"
      r=Z ;;
    *) mal_error "nth: not a sequence"; r=Z ;;
  esac
}

fn_first() {  # $1=list/vector/nil -> 首元素或 nil
  local t elems
  mal_type "$1"
  t="$r"
  case "$t" in
    __nil) r=Z ;;
    __list|__vec)
      mal_val "$1"
      elems="$r"
      if [ -z "$elems" ]; then r=Z; else r=${elems%% *}; fi ;;
    *) mal_error "first: not a sequence"; r=Z ;;
  esac
}

fn_rest() {  # $1=list/vector/nil -> 去掉首元素后的新 list
  local t elems rest
  mal_type "$1"
  t="$r"
  case "$t" in
    __nil) mal_list ;;
    __list|__vec)
      mal_val "$1"
      elems="$r"
      rest=${elems#* }
      if [ "$rest" = "$elems" ]; then rest=""; fi
      mal_list $rest ;;
    *) mal_error "rest: not a sequence"; r=Z ;;
  esac
}

fn_macro_p() {  # $1=函数 -> 是否为宏
  local t
  mal_type "$1"
  t="$r"
  if [ "$t" = __fn ]; then
    closure_get "$1"
    if [ "$r_ismacro" = 1 ]; then r=Y; else r=F; fi
  else
    r=F
  fi
}

fn_macroexpand() {  # $1=AST -> 若首元素是宏则展开一次（可多次），否则原样
  local ast="$1" t elems first fref
  while true; do
    mal_type "$ast"
    t="$r"
    if [ "$t" != __list ]; then r="$ast"; return; fi
    mal_val "$ast"
    elems="$r"
    if [ -z "$elems" ]; then r="$ast"; return; fi
    first=${elems%% *}
    mal_type "$first"
    if [ "$r" = __sym ]; then
      mal_val "$first"
      env_get "$REPL_ENV" "$r"
      fref="$r"
      if [ -z "$fref" ]; then r="$ast"; return; fi
      mal_type "$fref"
      if [ "$r" != __fn ]; then r="$ast"; return; fi
    else
      fref="$first"
      if [ "$r" != __fn ]; then r="$ast"; return; fi
    fi
    closure_get "$fref"
    if [ "$r_ismacro" != 1 ]; then r="$ast"; return; fi
    set -- $elems
    shift
    APPLY "$fref" "$@"
    if [ "$MAL_ERR" = 1 ]; then return; fi
    ast="$r"
  done
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
    __map)
      # 键值对集合相等（顺序无关）：a 的每个键在 b 中能找到且值相等
      mal_val "$a"; ae="$r"
      mal_val "$b"; be="$r"
      if [ -z "$ae" ] && [ -z "$be" ]; then r=Y; return; fi
      # 逐键检查
      while [ -n "$ae" ]; do
        ax=${ae%% *}
        if [ "$ax" = "$ae" ]; then ae=""; else ae=${ae#* }; fi
        local av bscan bk bv found=""
        av=${ae%% *}
        if [ "$av" = "$ae" ]; then ae=""; else ae=${ae#* }; fi
        bscan="$be"
        while [ -n "$bscan" ]; do
          bk=${bscan%% *}
          if [ "$bk" = "$bscan" ]; then bscan=""; else bscan=${bscan#* }; fi
          bv=${bscan%% *}
          if [ "$bv" = "$bscan" ]; then bscan=""; else bscan=${bscan#* }; fi
          key_equal "$ax" "$bk"
          if [ "$r" = Y ]; then
            fn_equal "$av" "$bv"
            if [ "$r" = Y ]; then found=1; else r=F; return; fi
            break
          fi
        done
        if [ -z "$found" ]; then r=F; return; fi
      done
      r=Y ;;
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

# -------- stepA：metadata --------

fn_meta() {  # $1=对象 -> meta（无则 nil）
  local ref="$1" v
  case "$ref" in
    L'*'*|V'*'*|H'*'*) r=Z; return ;;   # 内联对象不可能有 meta（with-meta 时已物化）
  esac
  if eval "[ "\$_MM_$ref" ]"; then
    eval "v=\$_MM_$ref"
    r="$v"
  else
    r=Z
  fi
}

fn_with_meta() {  # $1=对象 $2=meta -> 新对象（不突变）
  local obj="$1" meta="$2" t v
  mal_type "$obj"
  t="$r"
  case "$t" in
    __list)
      # 物化为存储型：内联 ref 不是合法动态变量名，meta 必须挂在 L<id> 上
      mal_val "$obj"; v="$r"
      new_id; id="$r"
      _set_stored "L$id" "$v"
      eval "_MM_L$id=$meta"
      r="L$id"
      ;;
    __vec)
      mal_val "$obj"; v="$r"
      new_id; id="$r"
      _set_stored "V$id" "$v"
      eval "_MM_V$id=$meta"
      r="V$id"
      ;;
    __map)
      mal_val "$obj"; v="$r"
      new_id; id="$r"
      _set_stored "H$id" "$v"
      eval "_MM_H$id=$meta"
      r="H$id"
      ;;
    __fn)
      # 闭包：复制字段 + 设 meta
      local kind fn params body env ismacro
      closure_get "$obj"
      kind="$r_kind"; fn="$r_fn"; params="$r_params"; body="$r_body"; env="$r_env"; ismacro="$r_ismacro"
      if [ "$kind" = mal ]; then
        mal_closure_mal "$params" "$body" "$env"
      else
        mal_closure_native "$fn"
      fi
      if [ "$ismacro" = 1 ]; then eval "_CM_$r=1"; fi
      eval "_MM_$r=$meta"
      ;;
    __atom)
      # atom：复制内容 + 设 meta
      local aval
      mal_val "$obj"; aval="$r"
      mal_atom "$aval"
      eval "_MM_$r=$meta"
      ;;
    *) r="$obj" ;;
  esac
}

fn_string_p()  { mal_type "$1"; if [ "$r" = __str ]; then r=Y; else r=F; fi; }
fn_number_p()  { mal_type "$1"; if [ "$r" = __num ]; then r=Y; else r=F; fi; }
fn_fn_p()      { mal_type "$1"; if [ "$r" = __fn ]; then
                    closure_get "$1"; if [ "$r_ismacro" = 1 ]; then r=F; else r=Y; fi
                  else r=F; fi; }
fn_macro_p()   { mal_type "$1"; if [ "$r" = __fn ]; then
                    closure_get "$1"; if [ "$r_ismacro" = 1 ]; then r=Y; else r=F; fi
                  else r=F; fi; }

fn_conj() {  # $1=list/vec 其余=元素
  local t v new
  mal_type "$1"
  t="$r"
  mal_val "$1"
  v="$r"
  shift
  if [ "$t" = __list ]; then
    # list：元素逐个前插
    local acc="$v" x
    while [ $# -gt 0 ]; do
      x="$1"; shift
      acc="$x $acc"
    done
    mal_list $acc
  else
    # vec：元素按序后插
    local acc="$v" x
    while [ $# -gt 0 ]; do
      x="$1"; shift
      acc="$acc $x"
    done
    mal_vec $acc
  fi
}

fn_seq() {  # $1=字符串/list/vec/nil -> list 或 nil
  local t v
  mal_type "$1"
  t="$r"
  case "$t" in
    __nil|__false) r=Z ;;
    __list)
      mal_val "$1"; v="$r"
      if [ -z "$v" ]; then r=Z; else r="$1"; fi ;;
    __vec)
      mal_val "$1"; v="$r"
      if [ -z "$v" ]; then r=Z; else mal_list $v; fi ;;
    __str)
      mal_val "$1"; v="$r"
      if [ -z "$v" ]; then r=Z; else
        # 每个字符转字符串，特殊字符也要（字符串可含任意内容）
        # ${v#?} 剥首字符、${v%"${v#?}"} 取首字符，纯内建零 fork。
        # 注意：按字节取，多字节 UTF-8 字符会被截断（mal 无多字节保证）
        local acc="" c
        while [ -n "$v" ]; do
          c="${v%"${v#?}"}"
          mal_str "$c"
          acc="$acc $r"
          v="${v#?}"
        done
        mal_list $acc
      fi ;;
    *) mal_error "seq: unsupported type"; return ;;
  esac
}

fn_time_ms() {  # 毫秒时间戳（macOS date 无 %N，用 python）
  mal_num "$(python3 -c 'import time; print(int(time.time()*1000))')"
}

# -------- step6：文件与求值 --------

fn_read_string() {
  local s
  mal_val "$1"
  s="$r"
  READ "$s"
  # 整串都是注释/空白时 READ 置 MAL_BLANK，按 nil 处理而不是报错
  if [ "$MAL_BLANK" = 1 ]; then r=Z; fi
}

fn_readline() {  # $1=prompt 字符串 -> 读一行（EOF 返回 nil）
  local prompt line
  mal_val "$1"
  prompt="$r"
  printf '%s' "$prompt"
  if IFS= read -r line; then
    mal_str "$line"
  else
    r=Z
  fi
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
  _update_stored "$1" "$2"
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
  _update_stored "$a" "$r"
}

# -------- step9：throw / 类型谓词 / apply / map --------

fn_throw() { MAL_ERR=1; MAL_ERR_MSG=""; MAL_ERR_VAL="$1"; r=Z; }

fn_symbol_p() { mal_type "$1"; if [ "$r" = __sym ]; then r=Y; else r=F; fi; }
fn_symbol()   { mal_val "$1"; mal_sym "$r"; }
fn_keyword_p(){ mal_type "$1"; if [ "$r" = __kw ]; then r=Y; else r=F; fi; }
fn_keyword()  { mal_val "$1"; mal_kw "$r"; }

fn_sequential_p() { mal_type "$1"; if [ "$r" = __list ] || [ "$r" = __vec ]; then r=Y; else r=F; fi; }

fn_apply() {  # $1=函数 中间参数... 最后一个=list/vector
  local f="$1" last t elems a
  shift
  for last in "$@"; do :; done              # last = 最后一个实参 ref
  mal_type "$last"
  t="$r"
  if [ "$t" != __list ] && [ "$t" != __vec ]; then
    mal_error "apply: last argument must be a sequence"; return
  fi
  mal_val "$last"
  elems="$r"
  # 重建：f + 前 $#-1 个中间参数 + 展开的序列元素（ref 均无空格，空格拼接安全）
  local args="$f" i=1 n=$(( $# - 1 ))
  while [ $i -le $n ]; do
    eval 'args="$args $'$i'"'
    i=$((i+1))
  done
  for a in $elems; do
    args="$args $a"
  done
  # 一次性重建位置参数再 APPLY
  set --
  for a in $args; do
    set -- "$@" "$a"
  done
  APPLY "$@"
}

fn_map() {  # $1=函数 $2=list/vector -> 结果 list
  local f="$1" seq="$2" t elems e result=""
  mal_type "$seq"
  t="$r"
  if [ "$t" != __list ] && [ "$t" != __vec ]; then
    mal_error "map: second argument must be a sequence"; return
  fi
  mal_val "$seq"
  elems="$r"
  for e in $elems; do
    APPLY "$f" "$e"
    if [ "$MAL_ERR" = 1 ]; then return; fi
    result="$result $r"
  done
  result=${result# }
  mal_list $result
}

# ================= REPL 环境 =================

