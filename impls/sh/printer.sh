#!/bin/dash
# zsh 兼容：默认不分词（SH_WORD_SPLIT 未开），与 POSIX sh/dash/bash 的
# 字段分割行为对齐。实现依赖未加引号 $var 分词（ref 串遍历）。
if [ -n "$ZSH_VERSION" ]; then setopt SH_WORD_SPLIT; fi
# ============================================================
# printer.sh —— 打印（官方 printer.qx）
# escape / pr_str / PRINT
# ============================================================
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

