#!/bin/dash
# ============================================================
# reader.sh —— tokenizer + reader（官方 reader.qx）
# TOKENIZE / READ / READ_FORM / READ_SEQ / READ_MAP
# ============================================================
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

