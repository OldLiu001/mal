dnl mal (M4 Lisp) step5 - TCO (tail-call optimization)
dnl Builds on step2: EVAL works on the encoded canonical string.
dnl Environments are sequential binding tables:
dnl   __E<id>_C   = number of bindings
dnl   __E<id>_N<k> = k-th binding name (0-based)
dnl   __E<id>_V<k> = k-th binding value
dnl   __E<id>_O   = outer env id (empty if none)
dnl Dynamic macro names are built by concatenation + indir.
dnl The current env id travels as an ARGUMENT through the whole EVAL
dnl chain (never a global), so nested let*/def! cannot clobber it.
include(reader.m4)dnl
define(<<<__ENV_CTR>>>, 0)dnl
define(<<<__REPL_ENV>>>, )dnl
define(<<<READ>>>, <<<define(<<<__LAST_AST>>>, ENC(read_str(<<<$1>>>)))>>>)dnl
define(<<<PRINT>>>, <<<DEC(ev_form(defn(<<<__FORM>>>), defn(<<<__REPL_ENV>>>)))>>>)dnl
define(<<<REP>>>, <<<ifelse(defn(<<<__REPL_ENV>>>), E, <<<define(<<<__REPL_ENV>>>, env_new(E))>>>)READ(<<<$1>>>)define(<<<__FORM>>>, defn(<<<__LAST_AST>>>))define(<<<__RES>>>, PRINT())ifelse(__ERR, 1, <<<Error: >>>__ERRMSG, <<<defn(<<<__RES>>>)>>>)
>>>)dnl
define(<<<env_new>>>, <<<define(<<<__ENV_CTR>>>, eval(defn(<<<__ENV_CTR>>>)+1))indir(<<<define>>>, <<<__E>>>defn(<<<__ENV_CTR>>>)<<<_C>>>, 0)ifelse(<<<$1>>>, E, E, <<<indir(<<<define>>>, <<<__E>>>defn(<<<__ENV_CTR>>>)<<<_O>>>, <<<$1>>>)>>>)defn(<<<__ENV_CTR>>>)>>>)dnl
define(<<<env_set>>>, <<<define(<<<__EI>>>, indir(<<<__E>>>$1<<<_C>>>))indir(<<<define>>>, <<<__E>>>$1<<<_N>>>defn(<<<__EI>>>), <<<$2>>>)indir(<<<define>>>, <<<__E>>>$1<<<_V>>>defn(<<<__EI>>>), <<<$3>>>)indir(<<<define>>>, <<<__E>>>$1<<<_C>>>, eval(defn(<<<__EI>>>)+1))>>>)dnl
define(<<<env_get>>>, <<<ifelse(<<<$1>>>, E, <<<err_symbol(<<<$2>>>)E>>>, <<<env_gs(<<<$1>>>, <<<$2>>>, eval(indir(<<<__E>>>$1<<<_C>>>)-1))>>>)>>>)dnl
define(<<<env_gs>>>, <<<ifelse(eval($3<0), 1, <<<env_gs_outer(<<<$1>>>, <<<$2>>>)>>>, <<<ifdef(<<<__E>>>$1<<<_N>>>$3, <<<env_gs1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<env_gs_outer(<<<$1>>>, <<<$2>>>)>>>)>>>)>>>)dnl
define(<<<env_gs1>>>, <<<ifelse(indir(<<<__E>>>$1<<<_N>>>$3), <<<$2>>>, <<<defn(<<<__E>>>$1<<<_V>>>$3)>>>, <<<env_gs(<<<$1>>>, <<<$2>>>, eval($3-1))>>>)>>>)dnl
define(<<<env_gs_outer>>>, <<<ifdef(<<<__E>>>$1<<<_O>>>, <<<env_get(indir(<<<__E>>>$1<<<_O>>>), <<<$2>>>)>>>, <<<err_symbol(<<<$2>>>)E>>>)>>>)dnl
dnl ---- helpers ----
define(<<<is_number>>>, <<<ifelse(first_char(<<<$1>>>), <<<->>>, <<<is_digits(rest_str(<<<$1>>>))>>>, <<<is_digits(<<<$1>>>)>>>)>>>)dnl
define(<<<is_digit>>>, <<<ifelse(regexp(<<<$1>>>, <<<^[0-9]$>>>), 0, 1, 0)>>>)dnl
define(<<<is_digits>>>, <<<ifelse(len(<<<$1>>>), 0, 1, <<<ifelse(is_digit(first_char(<<<$1>>>)), 1, <<<is_digits(rest_str(<<<$1>>>))>>>, 0)>>>)>>>)dnl
define(<<<inner_of>>>, <<<substr(<<<$1>>>,1,eval(len(<<<$1>>>)-2))>>>)dnl
dnl ---- EVAL dispatch (env travels as last argument) ----
define(<<<ev_form>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<ev_d0(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d0>>>, <<<ifelse(<<<$1>>>, <<<@>>>, <<<$2>>>, <<<ev_d1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_d1>>>, <<<ifelse(<<<$1>>>, LP, <<<ev_list(<<<$2>>>, <<<$3>>>)>>>, <<<ev_d2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_d2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<ev_vector(<<<$2>>>, <<<$3>>>)>>>, <<<ev_d3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_d3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<ev_map(<<<$2>>>, <<<$3>>>)>>>, <<<ev_d4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_d4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<$2>>>, <<<ev_d5(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_d5>>>, <<<ifelse(<<<$1>>>, <<<:>>>, <<<$2>>>, <<<ev_d6(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_d6>>>, <<<ifelse(is_number(<<<$2>>>), 1, <<<$2>>>, <<<ev_d7(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_d7>>>, <<<ifelse(<<<$1>>>, <<<nil>>>, <<<$1>>>, <<<ev_d8(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d8>>>, <<<ifelse(<<<$1>>>, <<<true>>>, <<<$1>>>, <<<ev_d9(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d9>>>, <<<ifelse(<<<$1>>>, <<<false>>>, <<<$1>>>, <<<env_get(<<<$2>>>, <<<$1>>>)>>>)>>>)dnl
define(<<<err_symbol>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, <<<'$1' not found>>>)>>>)dnl
dnl ---- list evaluation ----
define(<<<ev_list>>>, <<<define(<<<__LB>>>, inner_of(<<<$1>>>))ev_list_body(defn(<<<__LB>>>), <<<$2>>>)>>>)dnl
define(<<<ev_list_body>>>, <<<ifelse(len(<<<$1>>>), 0, <<<()>>>, <<<ev_lb_scan(skip_ws(<<<$1>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<ev_lb_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb_d>>>, <<<ifelse(<<<$1>>>, RP, E, <<<ev_lb1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lb2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lb3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lb4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lb5(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb5>>>, <<<ev_token(E, <<<$1>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
dnl ---- function application / special forms ----
define(<<<ev_list_apply>>>, <<<ifelse(<<<$1>>>, <<<+>>>, <<<ev_arith(<<<+>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ev_la2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la2>>>, <<<ifelse(<<<$1>>>, <<<->>>, <<<ev_arith(<<<->>>, <<<$2>>>, <<<$3>>>)>>>, <<<ev_la3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la3>>>, <<<ifelse(<<<$1>>>, <<<*>>>, <<<ev_arith(<<<*>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ev_la4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la4>>>, <<<ifelse(<<<$1>>>, <<</>>>, <<<ev_arith(<<</>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ev_la5(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la5>>>, <<<ifelse(<<<$1>>>, <<<def!>>>, <<<ev_def(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la6(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la6>>>, <<<ifelse(<<<$1>>>, <<<let*>>>, <<<ev_let(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la7(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la7>>>, <<<ifelse(<<<$1>>>, <<<if>>>, <<<ev_if(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la8(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la8>>>, <<<ifelse(<<<$1>>>, <<<fn*>>>, <<<ev_fn(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la9(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la9>>>, <<<ifelse(<<<$1>>>, <<<do>>>, <<<ev_do(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la10(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la10>>>, <<<ifelse(<<<$1>>>, <<<list>>>, <<<ev_list_fn(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la11(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la11>>>, <<<ifelse(<<<$1>>>, <<<list?>>>, <<<ev_listq(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la12(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la12>>>, <<<ifelse(<<<$1>>>, <<<empty?>>>, <<<ev_emptyq(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la13(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la13>>>, <<<ifelse(<<<$1>>>, <<<count>>>, <<<ev_count(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la14(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la14>>>, <<<ifelse(<<<$1>>>, <<<=>>>, <<<ev_eq(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la15(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la15>>>, <<<ifelse(<<<$1>>>, <<<<>>>, <<<ev_lt(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la16(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la16>>>, <<<ifelse(<<<$1>>>, <<<<=>>>, <<<ev_le(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la17(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la17>>>, <<<ifelse(<<<$1>>>, <<<>>>>, <<<ev_gt(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la18(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la18>>>, <<<ifelse(<<<$1>>>, <<<>=>>>, <<<ev_ge(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la19(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la19>>>, <<<ifelse(<<<$1>>>, <<<prn>>>, <<<ev_prn(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la20(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la20>>>, <<<ifelse(<<<$1>>>, <<<not>>>, <<<ev_not(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la21(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la21>>>, <<<define(<<<__F>>>, ev_form(<<<$1>>>, <<<$3>>>))ifelse(__ERR, 1, E, <<<apply_fn(defn(<<<__F>>>), <<<$2>>>, <<<$3>>>, <<<$1>>>)>>>)>>>)dnl
dnl ---- def! ----
define(<<<ev_def>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<split_first(<<<$1>>>)ev_def2(defn(<<<__SF_REST>>>), defn(<<<__SF_ELEM>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_def2>>>, <<<define(<<<__DV>>>, ev_form(skip_ws(<<<$1>>>), <<<$3>>>))ifelse(__ERR, 1, E, <<<env_set(<<<$3>>>, <<<$2>>>, defn(<<<__DV>>>))defn(<<<__DV>>>)>>>)>>>)dnl
dnl ---- let* ----
define(<<<ev_let>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<split_first(<<<$1>>>)ev_let2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_let2>>>, <<<ev_let_bind(inner_of(<<<$1>>>), <<<$2>>>, env_new(<<<$3>>>))>>>)dnl
define(<<<ev_let_bind>>>, <<<ifelse(len(<<<$1>>>), 0, <<<ev_form(skip_ws(<<<$2>>>), <<<$3>>>)>>>, <<<ev_ltb0(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_ltb0>>>, <<<ev_token(E, skip_ws(<<<$1>>>))ev_ltb1(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_ltb1>>>, <<<split_first(skip_ws(<<<$2>>>))ev_ltb2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$1>>>)>>>)dnl
define(<<<ev_ltb2>>>, <<<define(<<<__LV>>>, ev_form(<<<$1>>>, <<<$4>>>))env_set(<<<$4>>>, <<<$5>>>, defn(<<<__LV>>>))ev_let_bind(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
dnl ---- arithmetic ----
define(<<<ev_arith>>>, <<<eval(ev_as_scan(skip_ws(<<<$2>>>), <<<$1>>>, E, <<<$3>>>))>>>)dnl
define(<<<ev_as_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$3>>>, <<<ev_as_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_as_d>>>, <<<ifelse(<<<$1>>>, RP, <<<$4>>>, <<<ev_as1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ev_as2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ev_as3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ev_as4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ev_as5(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as5>>>, <<<ev_token(E, <<<$1>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<ev_as_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$5>>>))ifelse(len(<<<$4>>>), 0, <<<ev_as_scan(skip_ws(<<<$2>>>), <<<$3>>>, defn(<<<__V>>>), <<<$5>>>)>>>, <<<ev_as_scan(skip_ws(<<<$2>>>), <<<$3>>>, <<<$4>>><<<$3>>>defn(<<<__V>>>), <<<$5>>>)>>>)>>>)dnl
dnl ---- vector evaluation ----
define(<<<ev_vector>>>, <<<[ev_vec_body(inner_of(<<<$1>>>), <<<$2>>>)]>>>)dnl
define(<<<ev_vec_body>>>, <<<ev_vb_scan(skip_ws(<<<$1>>>), E, <<<$2>>>)>>>)dnl
define(<<<ev_vb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<ev_vb_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_vb_d>>>, <<<ifelse(<<<$1>>>, <<<]>>>, <<<$3>>>, <<<ev_vb1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_vb2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_vb3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_vb4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_vb5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb5>>>, <<<ev_token(E, <<<$1>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_vb_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$4>>>))ifelse(len(<<<$3>>>), 0, <<<ev_vb_scan(skip_ws(<<<$2>>>), defn(<<<__V>>>), <<<$4>>>)>>>, <<<ev_vb_scan(skip_ws(<<<$2>>>), <<<$3>>>SP()defn(<<<__V>>>), <<<$4>>>)>>>)>>>)dnl
dnl ---- map evaluation ----
define(<<<ev_map>>>, <<<{ev_map_body(inner_of(<<<$1>>>), <<<$2>>>)}>>>)dnl
define(<<<ev_map_body>>>, <<<ev_mb_scan(skip_ws(<<<$1>>>), E, <<<$2>>>)>>>)dnl
define(<<<ev_mb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<ev_mb_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_mb_d>>>, <<<ifelse(<<<$1>>>, <<<}>>>, <<<$3>>>, <<<ev_mb1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_mb2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_mb3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_mb4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_mb5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb5>>>, <<<ev_token(E, <<<$1>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_mb_k>>>, <<<ev_mb_v(skip_ws(<<<$2>>>), <<<$3>>>, <<<$4>>>, <<<$1>>>)>>>)dnl
define(<<<ev_mb_v>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, E, <<<ev_mv_d(first_char(skip_ws(<<<$1>>>)), skip_ws(<<<$1>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mv_d>>>, <<<ifelse(<<<$1>>>, <<<}>>>, E, <<<ev_mv1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$5>>>)>>>, <<<ev_mv2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$5>>>)>>>, <<<ev_mv3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$5>>>)>>>, <<<ev_mv4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$5>>>)>>>, <<<ev_mv5(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv5>>>, <<<ev_token(E, <<<$1>>>)ev_mb_join(<<<$3>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$4>>>)>>>)dnl
define(<<<ev_mb_join>>>, <<<define(<<<__V>>>, ev_form(<<<$2>>>, <<<$5>>>))ifelse(len(<<<$4>>>), 0, <<<ev_mb_scan(skip_ws(<<<$3>>>), <<<$1>>>SP()defn(<<<__V>>>), <<<$5>>>)>>>, <<<ev_mb_scan(skip_ws(<<<$3>>>), <<<$4>>>SP()<<<$1>>>SP()defn(<<<__V>>>), <<<$5>>>)>>>)>>>)dnl
dnl ---- collection core functions ----
define(<<<ev_list_fn>>>, <<<ifelse(len(<<<$1>>>), 0, <<<()>>>, <<<(ev_lf_scan(skip_ws(<<<$1>>>), E, <<<$2>>>))>>>)>>>)dnl
define(<<<ev_lf_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<ev_lf_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lf_d>>>, <<<ifelse(<<<$1>>>, RP, <<<$3>>>, <<<ev_lf1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_lf2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_lf3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_lf4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_lf5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf5>>>, <<<ev_token(E, <<<$1>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_lf_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$4>>>))ifelse(len(<<<$3>>>), 0, <<<ev_lf_scan(skip_ws(<<<$2>>>), defn(<<<__V>>>), <<<$4>>>)>>>, <<<ev_lf_scan(skip_ws(<<<$2>>>), <<<$3>>>SP()defn(<<<__V>>>), <<<$4>>>)>>>)>>>)dnl
define(<<<ev_listq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(index(defn(<<<__V>>>), <<<(>>>), 0, true, false)>>>)dnl
define(<<<ev_emptyq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(len(inner_of(defn(<<<__V>>>))), 0, true, false)>>>)dnl
define(<<<ev_count>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__VT>>>, ENC(defn(<<<__V>>>)))ifelse(defn(<<<__VT>>>), nil, 0, <<<count_scan(skip_ws(inner_of(defn(<<<__V>>>))), 0)>>>)>>>)dnl
define(<<<count_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<split_first(<<<$1>>>)count_scan(defn(<<<__SF_REST>>>), eval($2+1))>>>)>>>)dnl
dnl ---- comparison core functions ----
define(<<<ev_eq>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<eq>>>)>>>)dnl
define(<<<ev_lt>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<lt>>>)>>>)dnl
define(<<<ev_le>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<le>>>)>>>)dnl
define(<<<ev_gt>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<gt>>>)>>>)dnl
define(<<<ev_ge>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<ge>>>)>>>)dnl
define(<<<ev_cmp2>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<split_first(<<<$1>>>)ev_cmp2a(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_cmp2a>>>, <<<define(<<<__C1>>>, ev_form(<<<$1>>>, <<<$3>>>))ev_cmp2b(defn(<<<__C1>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<ev_cmp2b>>>, <<<ifelse(len(skip_ws(<<<$2>>>)), 0, E, <<<split_first(skip_ws(<<<$2>>>))ev_cmp2c(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_cmp2c>>>, <<<define(<<<__C2>>>, ev_form(<<<$2>>>, <<<$5>>>))ev_cmp2d(<<<$1>>>, defn(<<<__C2>>>), <<<$5>>>)>>>)dnl
define(<<<ev_cmp2d>>>, <<<ifelse(<<<$3>>>, <<<eq>>>, <<<ifelse(<<<$1>>>, <<<$2>>>, true, false)>>>, <<<ev_cmp2e(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_cmp2e>>>, <<<ifelse(<<<$3>>>, <<<lt>>>, <<<ifelse(eval(<<<$1>>> < <<<$2>>>), 1, true, false)>>>, <<<ev_cmp2f(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_cmp2f>>>, <<<ifelse(<<<$3>>>, <<<le>>>, <<<ifelse(eval(<<<$1>>> <= <<<$2>>>), 1, true, false)>>>, <<<ev_cmp2g(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_cmp2g>>>, <<<ifelse(<<<$3>>>, <<<gt>>>, <<<ifelse(eval(<<<$1>>> > <<<$2>>>), 1, true, false)>>>, <<<ifelse(eval(<<<$1>>> >= <<<$2>>>), 1, true, false)>>>)>>>)dnl
dnl ---- if ----
define(<<<ev_if>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<split_first(<<<$1>>>)ev_if2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_if2>>>, <<<define(<<<__C>>>, ev_form(<<<$1>>>, <<<$3>>>))define(<<<__CT>>>, ENC(defn(<<<__C>>>)))ev_if3(defn(<<<__CT>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_if3>>>, <<<ifelse(<<<$1>>>, nil, <<<ev_if_false(<<<$2>>>, <<<$3>>>)>>>, <<<ev_if4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_if4>>>, <<<ifelse(<<<$1>>>, false, <<<ev_if_false(<<<$2>>>, <<<$3>>>)>>>, <<<ev_if_true(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_if_true>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, E, <<<split_first(skip_ws(<<<$1>>>))ev_form(defn(<<<__SF_ELEM>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_if_false>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, <<<nil>>>, <<<split_first(skip_ws(<<<$1>>>))ev_if_f2(defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_if_f2>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, <<<nil>>>, <<<split_first(skip_ws(<<<$1>>>))ev_form(defn(<<<__SF_ELEM>>>), <<<$2>>>)>>>)>>>)dnl
dnl ---- fn* ----
define(<<<ev_fn>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<split_first(<<<$1>>>)ev_fn2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_fn2>>>, <<<split_first(<<<$2>>>)ev_fn3(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>)dnl
define(<<<ev_fn3>>>, <<<@LP()fn* SP()LP()inner_of(<<<$1>>>)<<<>>>RP()SP()<<<$2>>>SP()LP()$4<<<>>>RP()<<<>>>RP()>>>)dnl
dnl ---- do ----
define(<<<ev_do>>>, <<<ifelse(len(<<<$1>>>), 0, <<<nil>>>, <<<ev_do_scan(skip_ws(<<<$1>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_do_scan>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<ev_do_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_do_d>>>, <<<ifelse(<<<$1>>>, RP, E, <<<ev_do1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_do2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_do3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_do4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_do5(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do5>>>, <<<ev_token(E, <<<$1>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_do_elem>>>, <<<ifelse(len(skip_ws(<<<$2>>>)), 0, <<<ev_form(<<<$1>>>, <<<$3>>>)>>>, <<<define(<<<__DT>>>, ev_form(<<<$1>>>, <<<$3>>>))ev_do_scan(skip_ws(<<<$2>>>), <<<$3>>>)>>>)>>>)dnl
dnl ---- prn / not ----
define(<<<ev_prn>>>, <<<define(<<<__PO>>>, ev_lf_scan(skip_ws(<<<$1>>>), E, <<<$2>>>))syscmd(<<<printf '%s\n' '>>>defn(<<<__PO>>>)<<<'>>>)nil>>>)dnl
define(<<<ev_not>>>, <<<define(<<<__C>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__CT>>>, ENC(defn(<<<__C>>>)))ifelse(defn(<<<__CT>>>), nil, true, <<<ifelse(defn(<<<__CT>>>), false, true, false)>>>)>>>)dnl
dnl ---- function application ----
define(<<<apply_fn>>>, <<<ifelse(substr(<<<$1>>>, 0, 1), <<<@>>>, <<<apply_closure(rest_str(<<<$1>>>), <<<$2>>>, <<<$3>>>)>>>, <<<err_nf(<<<$4>>>)E>>>)>>>)dnl
define(<<<err_nf>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, <<<'$1' is not a function>>>)>>>)dnl
define(<<<apply_closure>>>, <<<split_first(inner_of(<<<$1>>>))apply_c2(defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<apply_c2>>>, <<<split_first(<<<$1>>>)apply_c3(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<apply_c3>>>, <<<split_first(<<<$2>>>)apply_c4(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<apply_c4>>>, <<<split_first(<<<$3>>>)apply_c5(<<<$1>>>, <<<$2>>>, defn(<<<__SF_ELEM>>>), <<<$4>>>, <<<$5>>>)>>>)dnl
define(<<<apply_c5>>>, <<<apply_c6(<<<$1>>>, <<<$2>>>, <<<$4>>>, inner_of(<<<$3>>>), <<<$5>>>)>>>)dnl
define(<<<apply_c6>>>, <<<define(<<<__NE>>>, env_new(<<<$4>>>))bind_params(inner_of(<<<$1>>>), <<<$3>>>, defn(<<<__NE>>>), <<<$5>>>)ev_form(<<<$2>>>, defn(<<<__NE>>>))>>>)dnl
define(<<<bind_params>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<ev_bp0(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_bp_rest>>>, <<<ev_token(E, skip_ws(<<<$1>>>))ev_bp_rest2(defn(<<<__SF_ELEM>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<ev_bp_rest2>>>, <<<define(<<<__RA>>>, ev_lf_scan(skip_ws(<<<$2>>>), E, <<<$4>>>))define(<<<__RP>>>, <<<(>>>defn(<<<__RA>>>)<<<)>>>)env_set(<<<$3>>>, <<<$1>>>, defn(<<<__RP>>>))>>>)dnl
define(<<<ev_bp0>>>, <<<ev_token(E, skip_ws(<<<$1>>>))ifelse(defn(<<<__SF_ELEM>>>), <<<&>>>, <<<ev_bp_rest(defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ev_bp1(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_bp1>>>, <<<ifelse(len(skip_ws(<<<$3>>>)), 0, E, <<<split_first(skip_ws(<<<$3>>>))ev_bp2(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_bp2>>>, <<<define(<<<__A>>>, ev_form(<<<$2>>>, <<<$6>>>))env_set(<<<$5>>>, <<<$1>>>, defn(<<<__A>>>))bind_params(<<<$4>>>, <<<$3>>>, <<<$5>>>, <<<$6>>>)>>>)dnl
dnl ---- token scan ----
define(<<<ev_token>>>, <<<ifelse(len(<<<$2>>>), 0, <<<sf_done(<<<$1>>>, E)>>>, <<<ev_tk1(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_tk1>>>, <<<ifelse(is_ws(first_char(<<<$2>>>)), 1, <<<sf_done(<<<$1>>>, skip_ws(<<<$2>>>))>>>, <<<ev_tk2(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_tk2>>>, <<<ifelse(first_char(<<<$2>>>), RP, <<<sf_done(<<<$1>>>, <<<$2>>>)>>>, <<<ev_token(<<<$1>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>)>>>)dnl
dnl ---- split_first ----
define(<<<split_first>>>, <<<sf_scan(E, skip_ws(<<<$1>>>))>>>)dnl
define(<<<sf_scan>>>, <<<ifelse(len(<<<$2>>>), 0, <<<sf_done(<<<$1>>>, E)>>>, <<<sf_s0(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s0>>>, <<<ifelse(is_ws(first_char(<<<$2>>>)), 1, <<<sf_done(<<<$1>>>, skip_ws(<<<$2>>>))>>>, <<<sf_s1(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s1>>>, <<<ifelse(first_char(<<<$2>>>), RP, <<<sf_done(<<<$1>>>, <<<$2>>>)>>>, <<<sf_s2(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s2>>>, <<<ifelse(first_char(<<<$2>>>), LP, <<<sf_paren(<<<$2>>>)>>>, <<<sf_s3(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s3>>>, <<<ifelse(first_char(<<<$2>>>), <<<[>>>, <<<sf_bracket(<<<$2>>>)>>>, <<<sf_s4(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s4>>>, <<<ifelse(first_char(<<<$2>>>), <<<{>>>, <<<sf_brace(<<<$2>>>)>>>, <<<sf_s5(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_s5>>>, <<<ifelse(first_char(<<<$2>>>), <<<">>>, <<<sf_string(<<<$2>>>)>>>, <<<sf_scan(<<<$1>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>)>>>)dnl
define(<<<sf_done>>>, <<<define(<<<__SF_ELEM>>>, <<<$1>>>)define(<<<__SF_REST>>>, <<<$2>>>)>>>)dnl
dnl ---- balanced groups ----
define(<<<sf_paren>>>, <<<sf_group(1, rest_str(<<<$1>>>), LP)>>>)dnl
define(<<<sf_bracket>>>, <<<sf_group(1, rest_str(<<<$1>>>), <<<[>>>)>>>)dnl
define(<<<sf_brace>>>, <<<sf_group(1, rest_str(<<<$1>>>), <<<{>>>)>>>)dnl
define(<<<sf_group>>>, <<<ifelse(len(<<<$2>>>), 0, <<<sf_done(<<<$3>>>, E)>>>, <<<sf_g1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g1>>>, <<<ifelse(first_char(<<<$2>>>), LP, <<<sf_group(eval(<<<$1>>>+1), rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>, <<<sf_g2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g2>>>, <<<ifelse(first_char(<<<$2>>>), <<<[>>>, <<<sf_group(eval(<<<$1>>>+1), rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>, <<<sf_g3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g3>>>, <<<ifelse(first_char(<<<$2>>>), <<<{>>>, <<<sf_group(eval(<<<$1>>>+1), rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>, <<<sf_g4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g4>>>, <<<ifelse(first_char(<<<$2>>>), RP, <<<sf_group_close(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<sf_g5(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g5>>>, <<<ifelse(first_char(<<<$2>>>), <<<]>>>, <<<sf_group_close(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<sf_g6(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<sf_g6>>>, <<<ifelse(first_char(<<<$2>>>), <<<}>>>, <<<sf_group_close(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<sf_group(<<<$1>>>, rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>)>>>)dnl
define(<<<sf_group_close>>>, <<<ifelse(<<<$1>>>, 1, <<<sf_done(<<<$3>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>, <<<sf_group(eval(<<<$1>>>-1), rest_str(<<<$2>>>), <<<$3>>>first_char(<<<$2>>>))>>>)>>>)dnl
dnl ---- string literal ----
define(<<<sf_string>>>, <<<sf_str_scan(rest_str(<<<$1>>>), <<<">>>)>>>)dnl
define(<<<sf_str_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<sf_done(<<<$2>>>, E)>>>, <<<sf_str1(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<sf_str1>>>, <<<ifelse(first_char(<<<$1>>>), <<<">>>, <<<sf_done(<<<$2>>>first_char(<<<$1>>>), rest_str(<<<$1>>>))>>>, <<<sf_str_scan(rest_str(<<<$1>>>), <<<$2>>>first_char(<<<$1>>>))>>>)>>>)dnl
