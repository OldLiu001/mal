#!/bin/dash
# zsh 兼容：默认不分词（SH_WORD_SPLIT 未开），与 POSIX sh/dash/bash 的
# 字段分割行为对齐。实现依赖未加引号 $var 分词（ref 串遍历）。
if [ -n "$ZSH_VERSION" ]; then setopt SH_WORD_SPLIT; fi
# ============================================================
# step2_eval —— 官方 step2
# eval（符号查找 + 算术调用；引入 env 模块）
# 官方模块化架构：本文件 = step 主文件（主逻辑 + 启动），
# source 共享模块（types/reader/printer/env/core）。
# ============================================================
set -f
STEPNUM=2
. "$(dirname "$0")/types.sh"
. "$(dirname "$0")/reader.sh"
. "$(dirname "$0")/printer.sh"
. "$(dirname "$0")/env.sh"

EVAL() {  # $1=ast ref $2=env -> r
  local ast="$1" env="$2"
  local t first elems e evaled f fname kname val nenv
  local bindrefs kref vref cond p params pnames pairs k v kk vv
  local kind fnname clparams clbody clenv
  local pend="" pendclos=$_MAL_NCLOS
  while true; do
  if [ "$MAL_ERR" = 1 ]; then return; fi


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
  esac


  case "$fname" in
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

init_repl_env() {
  local e
  env_new ""
  REPL_ENV="$r"
  e="$REPL_ENV"
  mal_closure_native fn_add; env_set "$e" '+' "$r"
  mal_closure_native fn_sub; env_set "$e" '-' "$r"
  mal_closure_native fn_mul; env_set "$e" '*' "$r"
  mal_closure_native fn_div; env_set "$e" '/' "$r"
}


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
