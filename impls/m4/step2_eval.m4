dnl mal (M4 Lisp) step2 - eval
dnl EVAL works on the canonical print string produced by read_str,
dnl re-encoded so that structural ( ) become safe control chars
dnl (LP/RP from reader.m4). This keeps every helper macro's expansion
dnl free of raw parens, which would corrupt m4 argument collection.
dnl PRINT decodes the result back.
dnl
dnl KEY PATTERNS:
dnl 1. After sf_* extracts a form into __SF_ELEM/__SF_REST, the values
dnl    are immediately passed (via defn) as arguments to the next macro.
dnl    Argument collection happens before any nested ev_form runs, so
dnl    later global overwrites cannot corrupt the values.
dnl 2. Accumulated results (arithmetic expression, vector body, map body)
dnl    travel as macro ARGUMENTS, never through globals, so nested
dnl    evaluation cannot clobber them.
include(reader.m4)dnl
define(<<<__READ>>>, <<<define(<<<__LAST_AST>>>, ENC(read_str(<<<$1>>>)))>>>)dnl
define(<<<__PRINT>>>, <<<DEC(ev_form(defn(<<<__FORM>>>)))>>>)dnl
define(<<<REP>>>, <<<__READ(<<<$1>>>)define(<<<__FORM>>>, defn(<<<__LAST_AST>>>))define(<<<__RES>>>, __PRINT())ifelse(__ERR, 1, <<<Error: >>>__ERRMSG, <<<defn(<<<__RES>>>)>>>)
>>>)dnl
define(<<<is_number>>>, <<<ifelse(first_char(<<<$1>>>), <<<->>>, <<<is_digits(rest_str(<<<$1>>>))>>>, <<<is_digits(<<<$1>>>)>>>)>>>)dnl
define(<<<is_digit>>>, <<<ifelse(regexp(<<<$1>>>, <<<^[0-9]$>>>), 0, 1, 0)>>>)dnl
define(<<<is_digits>>>, <<<ifelse(len(<<<$1>>>), 0, 1, <<<ifelse(is_digit(first_char(<<<$1>>>)), 1, <<<is_digits(rest_str(<<<$1>>>))>>>, 0)>>>)>>>)dnl
define(<<<inner_of>>>, <<<substr(<<<$1>>>,1,eval(len(<<<$1>>>)-2))>>>)dnl
dnl ---- EVAL dispatch ----
define(<<<ev_form>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<ev_d1(first_char(<<<$1>>>), <<<$1>>>)>>>)>>>)dnl
define(<<<ev_d1>>>, <<<ifelse(<<<$1>>>, LP, <<<ev_list(<<<$2>>>)>>>, <<<ev_d2(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<ev_vector(<<<$2>>>)>>>, <<<ev_d3(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<ev_map(<<<$2>>>)>>>, <<<ev_d4(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<$2>>>, <<<ev_d5(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d5>>>, <<<ifelse(<<<$1>>>, <<<:>>>, <<<$2>>>, <<<ev_d6(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d6>>>, <<<ifelse(is_number(<<<$2>>>), 1, <<<$2>>>, <<<ev_d7(<<<$2>>>)>>>)>>>)dnl
define(<<<ev_d7>>>, <<<ifelse(<<<$1>>>, <<<nil>>>, <<<$1>>>, <<<ev_d8(<<<$1>>>)>>>)>>>)dnl
define(<<<ev_d8>>>, <<<ifelse(<<<$1>>>, <<<true>>>, <<<$1>>>, <<<ev_d9(<<<$1>>>)>>>)>>>)dnl
define(<<<ev_d9>>>, <<<ifelse(<<<$1>>>, <<<false>>>, <<<$1>>>, <<<err_symbol(<<<$1>>>)>>>)>>>)dnl
define(<<<err_symbol>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, <<<'$1' not found>>>)>>>)dnl
dnl ---- list evaluation ----
define(<<<ev_list>>>, <<<define(<<<__LB>>>, inner_of(<<<$1>>>))ev_list_body(defn(<<<__LB>>>))>>>)dnl
define(<<<ev_list_body>>>, <<<ifelse(len(<<<$1>>>), 0, <<<()>>>, <<<ev_lb_scan(skip_ws(<<<$1>>>))>>>)>>>)dnl
define(<<<ev_lb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<ev_lb_d(first_char(<<<$1>>>), <<<$1>>>)>>>)>>>)dnl
define(<<<ev_lb_d>>>, <<<ifelse(<<<$1>>>, RP, __EE, <<<ev_lb1(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>))>>>, <<<ev_lb2(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>))>>>, <<<ev_lb3(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>))>>>, <<<ev_lb4(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>))>>>, <<<ev_lb5(<<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb5>>>, <<<ev_token(__EE, <<<$1>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>))>>>)dnl
define(<<<ev_list_apply>>>, <<<ifelse(<<<$1>>>, <<<+>>>, <<<ev_arith(<<<+>>>, <<<$2>>>)>>>, <<<ev_la2(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_la2>>>, <<<ifelse(<<<$1>>>, <<<->>>, <<<ev_arith(<<<->>>, <<<$2>>>)>>>, <<<ev_la3(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_la3>>>, <<<ifelse(<<<$1>>>, <<<*>>>, <<<ev_arith(<<<*>>>, <<<$2>>>)>>>, <<<ev_la4(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_la4>>>, <<<ifelse(<<<$1>>>, <<</>>>, <<<ev_arith(<<</>>>, <<<$2>>>)>>>, <<<err_fn(<<<$1>>>)>>>)>>>)dnl
define(<<<err_fn>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, <<<'$1' not found>>>)>>>)dnl
dnl ---- arithmetic: scan args, eval each, accumulate acc+op+V as ARGUMENT ----
define(<<<ev_arith>>>, <<<eval(ev_as_scan(skip_ws(<<<$2>>>), <<<$1>>>, __EE))>>>)dnl
define(<<<ev_as_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$3>>>, <<<ev_as_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_as_d>>>, <<<ifelse(<<<$1>>>, RP, <<<$4>>>, <<<ev_as1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_as1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_as2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_as2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_as3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_as3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_as4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_as4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_as5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_as5>>>, <<<ev_token(__EE, <<<$1>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_as_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>))ifelse(len(<<<$4>>>), 0, <<<ev_as_scan(skip_ws(<<<$2>>>), <<<$3>>>, defn(<<<__V>>>))>>>, <<<ev_as_scan(skip_ws(<<<$2>>>), <<<$3>>>, <<<$4>>><<<$3>>>defn(<<<__V>>>))>>>)>>>)dnl
dnl ---- vector evaluation ----
define(<<<ev_vector>>>, <<<[ev_vec_body(inner_of(<<<$1>>>))]>>>)dnl
define(<<<ev_vec_body>>>, <<<ev_vb_scan(skip_ws(<<<$1>>>), __EE)>>>)dnl
define(<<<ev_vb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<ev_vb_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_vb_d>>>, <<<ifelse(<<<$1>>>, <<<]>>>, <<<$3>>>, <<<ev_vb1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_vb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_vb2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_vb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_vb3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_vb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_vb4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_vb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_vb5(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_vb5>>>, <<<ev_token(__EE, <<<$1>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_vb_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>))ifelse(len(<<<$3>>>), 0, <<<ev_vb_scan(skip_ws(<<<$2>>>), defn(<<<__V>>>))>>>, <<<ev_vb_scan(skip_ws(<<<$2>>>), <<<$3>>>SP()defn(<<<__V>>>))>>>)>>>)dnl
dnl ---- map evaluation ----
define(<<<ev_map>>>, <<<{ev_map_body(inner_of(<<<$1>>>))}>>>)dnl
define(<<<ev_map_body>>>, <<<ev_mb_scan(skip_ws(<<<$1>>>), __EE)>>>)dnl
define(<<<ev_mb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<ev_mb_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_mb_d>>>, <<<ifelse(<<<$1>>>, <<<}>>>, <<<$3>>>, <<<ev_mb1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_mb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_mb2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_mb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_mb3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_mb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_mb4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_mb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_mb5(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_mb5>>>, <<<ev_token(__EE, <<<$1>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_mb_k>>>, <<<ev_mb_v(skip_ws(<<<$2>>>), <<<$3>>>, <<<$1>>>)>>>)dnl
define(<<<ev_mb_v>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, __EE, <<<ev_mv_d(first_char(skip_ws(<<<$1>>>)), skip_ws(<<<$1>>>), <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_mv_d>>>, <<<ifelse(<<<$1>>>, <<<}>>>, __EE, <<<ev_mv1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mv1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_mv2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mv2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_mv3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mv3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_mv4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mv4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_mv5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mv5>>>, <<<ev_token(__EE, <<<$1>>>)ev_mb_join(<<<$3>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_mb_join>>>, <<<define(<<<__V>>>, ev_form(<<<$2>>>))ifelse(len(<<<$4>>>), 0, <<<ev_mb_scan(skip_ws(<<<$3>>>), <<<$1>>>SP()defn(<<<__V>>>))>>>, <<<ev_mb_scan(skip_ws(<<<$3>>>), <<<$4>>>SP()<<<$1>>>SP()defn(<<<__V>>>))>>>)>>>)dnl
dnl ---- token scan: accumulate until whitespace / RP ----
define(<<<ev_token>>>, <<<ifelse(len(<<<$2>>>), 0, <<<sf_done(<<<$1>>>, __EE)>>>, <<<ev_tk1(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_tk1>>>, <<<ifelse(is_ws(first_char(<<<$2>>>)), 1, <<<sf_done(<<<$1>>>, skip_ws(<<<$2>>>))>>>, <<<ev_tk2(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_tk2>>>, <<<ifelse(first_char(<<<$2>>>), RP, <<<sf_done(<<<$1>>>, <<<$2>>>)>>>, <<<ev_token(<<<$1>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>)>>>)dnl
dnl ---- split_first: extract first form from re-encoded canonical string ----
define(<<<split_first>>>, <<<sf_scan(__EE, skip_ws(<<<$1>>>))>>>)dnl
define(<<<sf_scan>>>, <<<ifelse(len(<<<$2>>>), 0, <<<sf_done(<<<$1>>>, __EE)>>>, <<<sf_s0(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s0>>>, <<<ifelse(is_ws(first_char(<<<$2>>>)), 1, <<<sf_done(<<<$1>>>, skip_ws(<<<$2>>>))>>>, <<<sf_s1(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s1>>>, <<<ifelse(first_char(<<<$2>>>), RP, <<<sf_done(<<<$1>>>, <<<$2>>>)>>>, <<<sf_s2(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s2>>>, <<<ifelse(first_char(<<<$2>>>), LP, <<<sf_paren(<<<$2>>>)>>>, <<<sf_s3(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s3>>>, <<<ifelse(first_char(<<<$2>>>), <<<[>>>, <<<sf_bracket(<<<$2>>>)>>>, <<<sf_s4(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s4>>>, <<<ifelse(first_char(<<<$2>>>), <<<{>>>, <<<sf_brace(<<<$2>>>)>>>, <<<sf_s5(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s5>>>, <<<ifelse(first_char(<<<$2>>>), <<<">>>, <<<sf_string(<<<$2>>>)>>>, <<<sf_scan(<<<$1>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>)>>>)dnl
define(<<<sf_done>>>, <<<define(<<<__SF_ELEM>>>, <<<$1>>>)define(<<<__SF_REST>>>, <<<$2>>>)>>>)dnl
dnl ---- balanced groups (LP/RP control chars) ----
define(<<<sf_paren>>>, <<<sf_group(1, rest_str(<<<$1>>>), LP)>>>)dnl
define(<<<sf_bracket>>>, <<<sf_group(1, rest_str(<<<$1>>>), <<<[>>>)>>>)dnl
define(<<<sf_brace>>>, <<<sf_group(1, rest_str(<<<$1>>>), <<<{>>>)>>>)dnl
define(<<<sf_group>>>, <<<ifelse(len(<<<$2>>>), 0, <<<sf_done(<<<$3>>>, __EE)>>>, <<<sf_g1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g1>>>, <<<ifelse(first_char(<<<$2>>>), LP, <<<sf_group(eval(<<<$1>>>+1), rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>, <<<sf_g2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g2>>>, <<<ifelse(first_char(<<<$2>>>), <<<[>>>, <<<sf_group(eval(<<<$1>>>+1), rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>, <<<sf_g3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g3>>>, <<<ifelse(first_char(<<<$2>>>), <<<{>>>, <<<sf_group(eval(<<<$1>>>+1), rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>, <<<sf_g4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g4>>>, <<<ifelse(first_char(<<<$2>>>), RP, <<<sf_group_close(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<sf_g5(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g5>>>, <<<ifelse(first_char(<<<$2>>>), <<<]>>>, <<<sf_group_close(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<sf_g6(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g6>>>, <<<ifelse(first_char(<<<$2>>>), <<<}>>>, <<<sf_group_close(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<sf_group(<<<$1>>>, rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>)>>>)dnl
define(<<<sf_group_close>>>, <<<ifelse(<<<$1>>>, 1, <<<sf_done(<<<$3>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>, <<<sf_group(eval(<<<$1>>>-1), rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>)>>>)dnl
dnl ---- string literal ----
define(<<<sf_string>>>, <<<sf_str_scan(rest_str(<<<$1>>>), <<<">>>)>>>)dnl
define(<<<sf_str_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<sf_done(<<<$2>>>, __EE)>>>, <<<sf_str1(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_str1>>>, <<<ifelse(first_char(<<<$1>>>), <<<">>>, <<<sf_done(<<<$2>>>first_char(<<<$1>>>), rest_str(<<<$1>>>))>>>, <<<sf_str_scan(rest_str(<<<$1>>>), <<<$2>>>first_char(<<<$1>>>))>>>)>>>)dnl
