#!/bin/dash
# zsh 兼容：默认不分词（SH_WORD_SPLIT 未开），与 POSIX sh/dash/bash 的
# 字段分割行为对齐。实现依赖未加引号 $var 分词（ref 串遍历）。
if [ -n "$ZSH_VERSION" ]; then setopt SH_WORD_SPLIT; fi
# ============================================================
# step6_file —— 官方 step6
# 文件（load-file / read-string / eval / atom）
# 官方模块化架构：本文件 = step 主文件（主逻辑 + 启动），
# source 共享模块（types/reader/printer/env/core）。
# ============================================================
set -f
STEPNUM=6
. "$(dirname "$0")/types.sh"
. "$(dirname "$0")/reader.sh"
. "$(dirname "$0")/printer.sh"
. "$(dirname "$0")/env.sh"
. "$(dirname "$0")/core.sh"

EVAL() {  # $1=ast ref $2=env -> r
  local ast="$1" env="$2"
  local t first elems e evaled f fname kname val nenv
  local bindrefs kref vref cond p params pnames pairs k v kk vv
  local kind fnname clparams clbody clenv
  local pend="" pendclos=$_MAL_NCLOS
  while true; do
  if [ "$MAL_ERR" = 1 ]; then return; fi

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

  esac


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
    mal_closure_native fn_vector_p;env_set "$e" 'vector?' "$r"
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
    mal_closure_native fn_nil_p;   env_set "$e" 'nil?' "$r"
    mal_closure_native fn_true_p;  env_set "$e" 'true?' "$r"
    mal_closure_native fn_false_p; env_set "$e" 'false?' "$r"
    mal_closure_native fn_hash_map; env_set "$e" 'hash-map' "$r"
    mal_closure_native fn_assoc;    env_set "$e" 'assoc' "$r"
    mal_closure_native fn_get;      env_set "$e" 'get' "$r"
    mal_closure_native fn_contains_p; env_set "$e" 'contains?' "$r"
    mal_closure_native fn_keys;     env_set "$e" 'keys' "$r"
    mal_closure_native fn_vals;     env_set "$e" 'vals' "$r"
    mal_closure_native fn_dissoc;   env_set "$e" 'dissoc' "$r"
    mal_closure_native fn_map_p;    env_set "$e" 'map?' "$r"
    rep_silent '(def! not (fn* (a) (if a false true)))'
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
  # 文件参数（官方 step6 要求）：有参数时加载第一个文件并退出；
  # *ARGV* = 其余参数。加载的文件本身可启动自己的 REPL 循环
  # （自托管时 mal 写的解释器文件最后会进入 repl-loop 从 stdin 读）。
  if [ $# -ge 1 ] && [ "$STEPNUM" -ge 6 ]; then
    local argrefs="" a file="$1"
    shift
    for a in "$@"; do
      mal_str "$a"
      argrefs="$argrefs $r"
    done
    if [ -n "$argrefs" ]; then
      mal_list $argrefs
    else
      mal_list
    fi
    env_set "$REPL_ENV" '*ARGV*' "$r"
    MAL_ERR=0; MAL_ERR_MSG=""; MAL_BLANK=0
    rep_silent "(load-file \"$file\")"
    gc_maybe
    exit 0
  fi
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
      if [ -n "$MAL_ERR_VAL" ]; then
        pr_str "$MAL_ERR_VAL" 1
        printf 'Error: %s\n' "$r_str"
        MAL_ERR_VAL=""
      else
        printf '%s\n' "$MAL_ERR_MSG"
      fi
      continue
    fi
    PRINT "$r"
    printf '%s\n' "$r_str"
    gc_maybe
  done
}


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


# ---- 启动 ----
init_repl_env
mal_repl "$@"
