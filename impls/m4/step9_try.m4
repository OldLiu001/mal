dnl mal (M4 Lisp) step9 - try*/catch*/throw + core fn registry
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
dnl ---- DEBUG-EVAL support (optional feature) ----
define(<<<NLC>>>, <<<format(%c, 10)>>>)dnl
define(<<<env_try>>>, <<<ifelse(<<<$1>>>, __EE, <<<>>>, <<<env_ts(<<<$1>>>, <<<$2>>>, eval(indir(<<<__E>>>$1<<<_C>>>)-1))>>>)>>>)dnl
define(<<<env_ts>>>, <<<ifelse(eval($3<0), 1, <<<env_ts_o(<<<$1>>>, <<<$2>>>)>>>, <<<ifdef(<<<__E>>>$1<<<_N>>>$3, <<<env_ts1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<env_ts_o(<<<$1>>>, <<<$2>>>)>>>)>>>)>>>)dnl
define(<<<env_ts1>>>, <<<ifelse(indir(<<<__E>>>$1<<<_N>>>$3), <<<$2>>>, <<<defn(<<<__E>>>$1<<<_V>>>$3)>>>, <<<env_ts(<<<$1>>>, <<<$2>>>, eval($3-1))>>>)>>>)dnl
define(<<<env_ts_o>>>, <<<ifdef(<<<__E>>>$1<<<_O>>>, <<<env_try(indir(<<<__E>>>$1<<<_O>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<dbg_eval>>>, <<<ifdef(<<<__DBG_SEEN>>>, <<<dbg_p(env_try(<<<$2>>>, <<<DEBUG-EVAL>>>), <<<$1>>>)>>>)>>>)dnl
define(<<<dbg_p>>>, <<<ifelse(<<<$1>>>, <<<>>>, <<<>>>, <<<$1>>>, <<<nil>>>, <<<>>>, <<<$1>>>, <<<false>>>, <<<>>>, <<<errprint(<<<EVAL: >>>DEC(<<<$2>>>)<<<>>>NLC())>>>)>>>)dnl

define(<<<__ENV_CTR>>>, 0)dnl
define(<<<__ATM_CTR>>>, 0)dnl
define(<<<__REPL_ENV>>>, )dnl
define(<<<__READ>>>, <<<define(<<<__LAST_AST>>>, ENC(read_str(<<<$1>>>)))>>>)dnl
define(<<<__PRINT>>>, <<<define(<<<__PR>>>, ev_form(defn(<<<__FORM>>>), defn(<<<__REPL_ENV>>>)))define(<<<__PRS>>>, strip_meta(defn(<<<__PR>>>)))define(<<<__PRH>>>, substr(ENC(defn(<<<__PRS>>>)), 0, 6))define(<<<__ATMH>>>, <<<@>>>LP()<<<ATM:>>>)ifelse(defn(<<<__PRH>>>), defn(<<<__ATMH>>>), <<<print_atom(DEC(defn(<<<__PRS>>>)))>>>, <<<ifelse(first_char(defn(<<<__PRS>>>)), <<<">>>, <<<pr_str_val(defn(<<<__PRS>>>))>>>, <<<DEC(ENC(defn(<<<__PRS>>>)))>>>)>>>)>>>)dnl
define(<<<REP>>>, <<<ifelse(defn(<<<__REPL_ENV>>>), __EE, <<<define(<<<__REPL_ENV>>>, env_new(__EE))define(<<<__ROOT_ENV>>>, defn(<<<__REPL_ENV>>>))env_set(defn(<<<__REPL_ENV>>>), <<<*ARGV*>>>, <<<()>>>)env_set(defn(<<<__REPL_ENV>>>), <<<throw>>>, <<<@corethrow>>>)env_set(defn(<<<__REPL_ENV>>>), <<<+>>>, <<<@core+>>>)env_set(defn(<<<__REPL_ENV>>>), <<<->>>, <<<@core->>>)env_set(defn(<<<__REPL_ENV>>>), <<<*>>>, <<<@core*>>>)env_set(defn(<<<__REPL_ENV>>>), <<</>>>, <<<@core/>>>)env_set(defn(<<<__REPL_ENV>>>), <<<=>>>, <<<@core=>>>)env_set(defn(<<<__REPL_ENV>>>), <<<<>>>, <<<@core<>>>)env_set(defn(<<<__REPL_ENV>>>), <<<<=>>>, <<<@core<=>>>)env_set(defn(<<<__REPL_ENV>>>), <<<>>>>, <<<@core>>>>>)env_set(defn(<<<__REPL_ENV>>>), <<<>=>>>, <<<@core>=>>>)env_set(defn(<<<__REPL_ENV>>>), <<<nil?>>>, <<<@corenil?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<prn>>>, <<<@coreprn>>>)env_set(defn(<<<__REPL_ENV>>>), <<<not>>>, <<<@corenot>>>)env_set(defn(<<<__REPL_ENV>>>), <<<read-string>>>, <<<@coreread-string>>>)env_set(defn(<<<__REPL_ENV>>>), <<<eval>>>, <<<@coreeval>>>)env_set(defn(<<<__REPL_ENV>>>), <<<slurp>>>, <<<@coreslurp>>>)env_set(defn(<<<__REPL_ENV>>>), <<<list>>>, <<<@corelist>>>)env_set(defn(<<<__REPL_ENV>>>), <<<list?>>>, <<<@corelist?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<empty?>>>, <<<@coreempty?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<count>>>, <<<@corecount>>>)env_set(defn(<<<__REPL_ENV>>>), <<<str>>>, <<<@corestr>>>)env_set(defn(<<<__REPL_ENV>>>), <<<cons>>>, <<<@corecons>>>)env_set(defn(<<<__REPL_ENV>>>), <<<concat>>>, <<<@coreconcat>>>)env_set(defn(<<<__REPL_ENV>>>), <<<vec>>>, <<<@corevec>>>)env_set(defn(<<<__REPL_ENV>>>), <<<vector>>>, <<<@corevector>>>)env_set(defn(<<<__REPL_ENV>>>), <<<first>>>, <<<@corefirst>>>)env_set(defn(<<<__REPL_ENV>>>), <<<rest>>>, <<<@corerest>>>)env_set(defn(<<<__REPL_ENV>>>), <<<nth>>>, <<<@corenth>>>)env_set(defn(<<<__REPL_ENV>>>), <<<atom>>>, <<<@coreatom>>>)env_set(defn(<<<__REPL_ENV>>>), <<<atom?>>>, <<<@coreatom?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<deref>>>, <<<@corederef>>>)env_set(defn(<<<__REPL_ENV>>>), <<<reset!>>>, <<<@corereset!>>>)env_set(defn(<<<__REPL_ENV>>>), <<<swap!>>>, <<<@coreswap!>>>)env_set(defn(<<<__REPL_ENV>>>), <<<map>>>, <<<@coremap>>>)env_set(defn(<<<__REPL_ENV>>>), <<<apply>>>, <<<@coreapply>>>)env_set(defn(<<<__REPL_ENV>>>), <<<pr-str>>>, <<<@corepr-str>>>)env_set(defn(<<<__REPL_ENV>>>), <<<println>>>, <<<@coreprintln>>>)env_set(defn(<<<__REPL_ENV>>>), <<<keyword>>>, <<<@corekeyword>>>)env_set(defn(<<<__REPL_ENV>>>), <<<keyword?>>>, <<<@corekeyword?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<symbol>>>, <<<@coresymbol>>>)env_set(defn(<<<__REPL_ENV>>>), <<<symbol?>>>, <<<@coresymbol?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<number?>>>, <<<@corenumber?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<string?>>>, <<<@corestring?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<fn?>>>, <<<@corefn?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<map?>>>, <<<@coremap?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<sequential?>>>, <<<@coresequential?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<false?>>>, <<<@corefalse?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<true?>>>, <<<@coretrue?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<vector?>>>, <<<@corevector?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<hash-map>>>, <<<@corehash-map>>>)env_set(defn(<<<__REPL_ENV>>>), <<<hash-map?>>>, <<<@corehash-map?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<get>>>, <<<@coreget>>>)env_set(defn(<<<__REPL_ENV>>>), <<<assoc>>>, <<<@coreassoc>>>)env_set(defn(<<<__REPL_ENV>>>), <<<dissoc>>>, <<<@coredissoc>>>)env_set(defn(<<<__REPL_ENV>>>), <<<keys>>>, <<<@corekeys>>>)env_set(defn(<<<__REPL_ENV>>>), <<<vals>>>, <<<@corevals>>>)env_set(defn(<<<__REPL_ENV>>>), <<<contains?>>>, <<<@corecontains?>>>)env_set(defn(<<<__REPL_ENV>>>), <<<with-meta>>>, <<<@corewith-meta>>>)env_set(defn(<<<__REPL_ENV>>>), <<<meta>>>, <<<@coremeta>>>)env_set(defn(<<<__REPL_ENV>>>), <<<readline>>>, <<<@corereadline>>>)env_set(defn(<<<__REPL_ENV>>>), <<<time-ms>>>, <<<@coretime-ms>>>)env_set(defn(<<<__REPL_ENV>>>), <<<seq>>>, <<<@coreseq>>>)env_set(defn(<<<__REPL_ENV>>>), <<<conj>>>, <<<@coreconj>>>)env_set(defn(<<<__REPL_ENV>>>), <<<*host-language*>>>, <<<"m4">>>)__READ(<<<(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list (quote if) (first xs) (if (> (count xs) 1) (nth xs 1) (throw "odd number of forms to cond")) (cons (quote cond) (rest (rest xs)))))))>>>)define(<<<__BOOTF>>>, defn(<<<__LAST_AST>>>))define(<<<__BOOTR>>>, ev_form(defn(<<<__BOOTF>>>), defn(<<<__REPL_ENV>>>)))>>>)__READ(<<<$1>>>)define(<<<__FORM>>>, defn(<<<__LAST_AST>>>))define(<<<__RES>>>, __PRINT())ifelse(__ERR, 1, <<<Error: >>>__ERRMSG, <<<defn(<<<__RES>>>)>>>)>>>)dnl
define(<<<env_new>>>, <<<define(<<<__ENV_CTR>>>, eval(defn(<<<__ENV_CTR>>>)+1))indir(<<<define>>>, <<<__E>>>defn(<<<__ENV_CTR>>>)<<<_C>>>, 0)ifelse(<<<$1>>>, __EE, __EE, <<<indir(<<<define>>>, <<<__E>>>defn(<<<__ENV_CTR>>>)<<<_O>>>, <<<$1>>>)>>>)defn(<<<__ENV_CTR>>>)>>>)dnl
define(<<<env_set>>>, <<<ifelse(<<<$2>>>, <<<DEBUG-EVAL>>>, <<<define(<<<__DBG_SEEN>>>, 1)>>>)define(<<<__EI>>>, indir(<<<__E>>>$1<<<_C>>>))indir(<<<define>>>, <<<__E>>>$1<<<_N>>>defn(<<<__EI>>>), <<<$2>>>)indir(<<<define>>>, <<<__E>>>$1<<<_V>>>defn(<<<__EI>>>), <<<$3>>>)indir(<<<define>>>, <<<__E>>>$1<<<_C>>>, eval(defn(<<<__EI>>>)+1))>>>)dnl
define(<<<env_get>>>, <<<ifelse(<<<$1>>>, __EE, <<<err_symbol(<<<$2>>>)__EE>>>, <<<env_gs(<<<$1>>>, <<<$2>>>, eval(indir(<<<__E>>>$1<<<_C>>>)-1))>>>)>>>)dnl
define(<<<env_gs>>>, <<<ifelse(eval($3<0), 1, <<<env_gs_outer(<<<$1>>>, <<<$2>>>)>>>, <<<ifdef(<<<__E>>>$1<<<_N>>>$3, <<<env_gs1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<env_gs_outer(<<<$1>>>, <<<$2>>>)>>>)>>>)>>>)dnl
define(<<<env_gs1>>>, <<<ifelse(indir(<<<__E>>>$1<<<_N>>>$3), <<<$2>>>, <<<defn(<<<__E>>>$1<<<_V>>>$3)>>>, <<<env_gs(<<<$1>>>, <<<$2>>>, eval($3-1))>>>)>>>)dnl
define(<<<env_gs_outer>>>, <<<ifdef(<<<__E>>>$1<<<_O>>>, <<<env_get(indir(<<<__E>>>$1<<<_O>>>), <<<$2>>>)>>>, <<<err_symbol(<<<$2>>>)__EE>>>)>>>)dnl
dnl ---- helpers ----
define(<<<is_number>>>, <<<ifelse(first_char(<<<$1>>>), <<<->>>, <<<ifelse(len(rest_str(<<<$1>>>)), 0, 0, <<<is_digits(rest_str(<<<$1>>>))>>>)>>>, <<<is_digits(<<<$1>>>)>>>)>>>)dnl
define(<<<is_digit>>>, <<<ifelse(regexp(<<<$1>>>, <<<^[0-9]$>>>), 0, 1, 0)>>>)dnl
define(<<<is_digits>>>, <<<ifelse(len(<<<$1>>>), 0, 1, <<<ifelse(is_digit(first_char(<<<$1>>>)), 1, <<<is_digits(rest_str(<<<$1>>>))>>>, 0)>>>)>>>)dnl
define(<<<inner_of>>>, <<<substr(<<<$1>>>,1,eval(len(<<<$1>>>)-2))>>>)dnl
dnl ---- EVAL dispatch (env travels as last argument) ----
define(<<<ev_form>>>, <<<dbg_eval(<<<$1>>>, <<<$2>>>)ifelse(len(<<<$1>>>), 0, __EE, <<<ev_d0(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_d0>>>, <<<ifelse(<<<$1>>>, <<<@>>>, <<<ev_atm_or_deref(<<<$2>>>, <<<$3>>>)>>>, <<<ev_d1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
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
define(<<<ev_list_body>>>, <<<ifelse(len(<<<$1>>>), 0, <<<LP()RP()>>>, <<<ev_lb_scan(skip_ws(<<<$1>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<ev_lb_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lb_d>>>, <<<ifelse(<<<$1>>>, RP, __EE, <<<ev_lb1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lb2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lb3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lb4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lb5(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lb5>>>, <<<ev_token(__EE, <<<$1>>>)ev_list_apply(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
dnl ---- function application / special forms ----
define(<<<ev_la_apply>>>, <<<ifelse(<<<$1>>>, <<<+>>>, <<<ev_arith(<<<+>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ev_la2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_list_apply>>>, <<<mc_d0(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<mc_d0>>>, <<<ifelse(<<<$1>>>, LP, <<<ev_la_apply(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<ev_la_apply(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<ev_la_apply(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<ev_la_apply(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ifelse(<<<$1>>>, <<<:>>>, <<<ev_la_apply(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ifelse(<<<$1>>>, <<<@>>>, <<<ev_la_apply(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ifelse(<<<$1>>>, <<<->>>, <<<ev_la_apply(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ifelse(is_number(<<<$2>>>), 1, <<<ev_la_apply(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<mc_sym(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
define(<<<mc_sym>>>, <<<define(<<<__MV>>>, mc_env_get(<<<$3>>>, <<<$1>>>))ifelse(defn(<<<__MV>>>), NF, <<<ev_la_apply(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(substr(defn(<<<__MV>>>), 0, 2), <<<@@>>>, <<<define(<<<__ME>>>, mc_apply(defn(<<<__MV>>>), <<<$2>>>, <<<$3>>>))ev_form(defn(<<<__ME>>>), <<<$3>>>)>>>, <<<ev_la_apply(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)>>>)dnl
define(<<<mc_env_get>>>, <<<mc_eg(<<<$1>>>, <<<$2>>>)>>>)dnl
define(<<<mc_eg>>>, <<<ifelse(<<<$1>>>, __EE, <<<NF>>>, <<<mc_eg2(<<<$1>>>, <<<$2>>>, eval(indir(<<<__E>>>$1<<<_C>>>)-1))>>>)>>>)dnl
define(<<<mc_eg2>>>, <<<ifelse(eval($3<0), 1, <<<mc_outer(<<<$1>>>, <<<$2>>>)>>>, <<<ifdef(<<<__E>>>$1<<<_N>>>$3, <<<mc_eg3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<mc_outer(<<<$1>>>, <<<$2>>>)>>>)>>>)>>>)dnl
define(<<<mc_eg3>>>, <<<ifelse(indir(<<<__E>>>$1<<<_N>>>$3), <<<$2>>>, <<<defn(<<<__E>>>$1<<<_V>>>$3)>>>, <<<mc_eg2(<<<$1>>>, <<<$2>>>, eval($3-1))>>>)>>>)dnl
define(<<<mc_outer>>>, <<<ifdef(<<<__E>>>$1<<<_O>>>, <<<mc_eg(indir(<<<__E>>>$1<<<_O>>>), <<<$2>>>)>>>, <<<NF>>>)>>>)dnl
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
define(<<<ev_la21>>>, <<<ifelse(<<<$1>>>, <<<read-string>>>, <<<ev_read_string(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la22(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la22>>>, <<<ifelse(<<<$1>>>, <<<eval>>>, <<<ev_mal_eval(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la23(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la23>>>, <<<ifelse(<<<$1>>>, <<<slurp>>>, <<<ev_slurp(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la24(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la24>>>, <<<ifelse(<<<$1>>>, <<<load-file>>>, <<<ev_load_file(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la25(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la25>>>, <<<ifelse(<<<$1>>>, <<<atom>>>, <<<ev_atom(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la26(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la26>>>, <<<ifelse(<<<$1>>>, <<<deref>>>, <<<ev_deref(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la27(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la27>>>, <<<ifelse(<<<$1>>>, <<<reset!>>>, <<<ev_reset(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la28(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la28>>>, <<<ifelse(<<<$1>>>, <<<swap!>>>, <<<ev_swap(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la29(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la29>>>, <<<ifelse(<<<$1>>>, <<<atom?>>>, <<<ev_atomq(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la30(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la30>>>, <<<ifelse(<<<$1>>>, <<<quote>>>, <<<ev_quote(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la31(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la31>>>, <<<ifelse(<<<$1>>>, <<<quasiquote>>>, <<<ev_qq(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la32(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la32>>>, <<<ifelse(<<<$1>>>, <<<cons>>>, <<<ev_cons(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la33(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la33>>>, <<<ifelse(<<<$1>>>, <<<concat>>>, <<<ev_concat(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la34(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la34>>>, <<<ifelse(<<<$1>>>, <<<vec>>>, <<<ev_vec_disp(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<vector>>>, <<<ev_vec_disp(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ev_la35(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)>>>)dnl
define(<<<ev_la35>>>, <<<ifelse(<<<$1>>>, <<<str>>>, <<<ev_str(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la36(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la36>>>, <<<ifelse(<<<$1>>>, <<<defmacro!>>>, <<<ev_defmacro(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la37(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la37>>>, <<<ifelse(<<<$1>>>, <<<macroexpand>>>, <<<ev_macroexpand(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la38(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la38>>>, <<<ifelse(<<<$1>>>, <<<macro?>>>, <<<ev_macroq(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la39(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la39>>>, <<<ifelse(<<<$1>>>, <<<first>>>, <<<ev_first(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la40(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la40>>>, <<<ifelse(<<<$1>>>, <<<rest>>>, <<<ev_rest(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la41(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la41>>>, <<<ifelse(<<<$1>>>, <<<nth>>>, <<<ev_nth(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la42(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la42>>>, <<<ifelse(<<<$1>>>, <<<cond>>>, <<<ev_cond(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la43(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la43>>>, <<<ifelse(<<<$1>>>, <<<try*>>>, <<<ev_try(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la44(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la44>>>, <<<ifelse(<<<$1>>>, <<<throw>>>, <<<ev_throw(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la45(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la45>>>, <<<ifelse(<<<$1>>>, <<<map>>>, <<<ev_map_fn(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la46(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la46>>>, <<<ifelse(<<<$1>>>, <<<apply>>>, <<<ev_apply_fn(<<<$2>>>, <<<$3>>>)>>>, <<<ev_la47(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_la47>>>, <<<define(<<<__F>>>, ev_form(<<<$1>>>, <<<$3>>>))ifelse(__ERR, 1, __EE, <<<apply_fn(defn(<<<__F>>>), <<<$2>>>, <<<$3>>>, <<<$1>>>)>>>)>>>)dnl
dnl ---- quote / quasiquote ----
define(<<<ev_quote>>>, <<<skip_ws(<<<$1>>>)>>>)dnl
define(<<<ev_qq>>>, <<<qq_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)dnl
define(<<<qq_d>>>, <<<ifelse(<<<$1>>>, LP, <<<qq_list(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<qq_vec(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<qq_map(<<<$2>>>, <<<$3>>>)>>>, <<<DEC(skip_ws(<<<$2>>>))>>>)>>>)>>>)>>>)dnl
define(<<<qq_list>>>, <<<ifelse(len(inner_of(<<<$1>>>)), 0, <<<LP()RP()>>>, <<<split_first(inner_of(<<<$1>>>))qq_l2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<qq_l2>>>, <<<ifelse(<<<$1>>>, <<<unquote>>>, <<<ev_form(skip_ws(<<<$2>>>), <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<splice-unquote>>>, <<<ev_form(skip_ws(<<<$2>>>), <<<$3>>>)>>>, <<<qq_scan(skip_ws(<<<$1>>>SP()<<<$2>>>), __EE, <<<$3>>>)>>>)>>>)>>>)dnl
define(<<<qq_build>>>, <<<ifelse(len(<<<$2>>>), 0, <<<(qq_scan(skip_ws(<<<$1>>>), __EE, <<<$3>>>))>>>, <<<qq_scan(skip_ws(<<<$1>>>SP()<<<$2>>>), __EE, <<<$3>>>)>>>)>>>)dnl
define(<<<qq_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<qq_s(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<qq_s>>>, <<<split_first(<<<$2>>>)qq_se(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<qq_se>>>, <<<qq_el(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<qq_el>>>, <<<ifelse(<<<$2>>>, <<<unquote>>>, <<<qq_el_unq(<<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ifelse(<<<$2>>>, <<<splice-unquote>>>, <<<qq_el_spl(<<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ifelse(<<<$1>>>, LP, <<<qq_elist(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<qq_atom(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)>>>)>>>)dnl
define(<<<qq_el_unq>>>, <<<split_first(skip_ws(<<<$1>>>))qq_unq(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<qq_el_spl>>>, <<<split_first(skip_ws(<<<$1>>>))qq_spl(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<qq_elist>>>, <<<ifelse(len(inner_of(<<<$1>>>)), 0, <<<qq_append(<<<$2>>>, <<<LP()RP()>>>, <<<$3>>>, <<<$4>>>)>>>, <<<split_first(inner_of(<<<$1>>>))qq_el2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<qq_el2>>>, <<<ifelse(<<<$1>>>, <<<unquote>>>, <<<qq_unq(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ifelse(<<<$1>>>, <<<splice-unquote>>>, <<<qq_spl(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<qq_recur(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)>>>)dnl
define(<<<qq_recur>>>, <<<define(<<<__QV>>>, <<<qq_scan(skip_ws(<<<$1>>>SP()<<<$2>>>), __EE, <<<$5>>>)>>>)qq_append(<<<$3>>>, defn(<<<__QV>>>), <<<$4>>>, <<<$5>>>)>>>)dnl
define(<<<qq_unq>>>, <<<define(<<<__QV>>>, ev_form(skip_ws(<<<$1>>>), <<<$4>>>))qq_append(<<<$2>>>, defn(<<<__QV>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<qq_spl>>>, <<<define(<<<__QV>>>, ev_form(skip_ws(<<<$1>>>), <<<$4>>>))qq_spl2(defn(<<<__QV>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<qq_spl2>>>, <<<qq_splice(inner_of(<<<$1>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<qq_splice>>>, <<<ifelse(len(<<<$1>>>), 0, <<<qq_scan(skip_ws(<<<$2>>>), <<<$3>>>, <<<$4>>>)>>>, <<<split_first(<<<$1>>>)qq_splice(defn(<<<__SF_REST>>>), <<<$2>>>, ifelse(len(<<<$3>>>), 0, <<<defn(<<<__SF_ELEM>>>)>>>, <<<$3>>>SP()defn(<<<__SF_ELEM>>>)), <<<$4>>>)>>>)>>>)dnl
define(<<<qq_atom>>>, <<<qq_append(<<<$2>>>, qq_d(first_char(<<<$1>>>), <<<$1>>>, <<<$4>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<qq_append>>>, <<<ifelse(len(<<<$2>>>), 0, <<<qq_scan(skip_ws(<<<$1>>>), <<<$3>>>, <<<$4>>>)>>>, <<<qq_scan(skip_ws(<<<$1>>>), ifelse(len(<<<$3>>>), 0, <<<$2>>>, <<<$3>>>SP()<<<$2>>>), <<<$4>>>)>>>)>>>)dnl
define(<<<qq_vec>>>, <<<[qq_vscan(inner_of(<<<$1>>>), __EE, <<<$2>>>)]>>>)dnl
define(<<<qq_vscan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<qq_vs(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<qq_vs>>>, <<<split_first(<<<$2>>>)qq_se(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<qq_map>>>, <<<{qq_mscan(inner_of(<<<$1>>>), __EE, <<<$2>>>)}>>>)dnl
define(<<<qq_mscan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<qq_ms(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<qq_ms>>>, <<<split_first(<<<$2>>>)qq_se(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
dnl ---- cons / concat / vec ----
define(<<<ev_cons>>>, <<<split_first(skip_ws(<<<$1>>>))ev_cons2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_cons2>>>, <<<define(<<<__CA>>>, ev_form(<<<$1>>>, <<<$3>>>))define(<<<__CB>>>, ev_form(skip_ws(<<<$2>>>), <<<$3>>>))ifelse(len(defn(<<<__CB>>>)), 2, <<<defn(<<<__CA>>>)>>>, <<<ifelse(len(inner_of(defn(<<<__CB>>>))), 0, <<<defn(<<<__CA>>>)>>>, <<<defn(<<<__CA>>>)SP()inner_of(defn(<<<__CB>>>))>>>)>>>)>>>)dnl
define(<<<ev_concat>>>, <<<concat_scan(skip_ws(<<<$1>>>), __EE, <<<$2>>>)>>>)dnl
define(<<<concat_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<ifelse(len(<<<$2>>>), 0, __EE, <<<$2>>>)>>>, <<<concat_el(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<concat_el>>>, <<<split_first(<<<$2>>>)concat_join(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<concat_join>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$4>>>))concat_scan(skip_ws(<<<$2>>>), ifelse(len(<<<$3>>>), 0, <<<inner_of(defn(<<<__V>>>))>>>, <<<$3>>>SP()inner_of(defn(<<<__V>>>))), <<<$4>>>)>>>)dnl
define(<<<ev_vec>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))[inner_of(defn(<<<__V>>>))]>>>)dnl
define(<<<ev_vec_disp>>>, <<<ifelse(<<<$1>>>, <<<vec>>>, <<<ev_vec(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<vector>>>, <<<[ev_vec_body(<<<$2>>>, <<<$3>>>)]>>>, <<<__EE>>>)>>>)>>>)dnl
dnl ---- str: concatenate args into a string (nil -> "", strings unquoted, others pr-ed) ----
define(<<<ev_str>>>, <<<define(<<<__SO>>>, str_scan(skip_ws(<<<$1>>>), __EE, <<<$2>>>))<<<">>>defn(<<<__SO>>>)<<<">>>>>>)dnl
define(<<<str_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<str_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<str_d>>>, <<<ifelse(<<<$1>>>, RP, <<<$3>>>, <<<str_f1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<str_f1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)str_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<str_f2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<str_f2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)str_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<str_f3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<str_f3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)str_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<str_f4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<str_f4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)str_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<str_f5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<str_f5>>>, <<<ev_token(__EE, <<<$1>>>)str_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<str_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$4>>>))str_join(defn(<<<__V>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<str_join>>>, <<<define(<<<__ST>>>, ENC(<<<$1>>>))ifelse(defn(<<<__ST>>>), nil, <<<str_scan(skip_ws(<<<$2>>>), <<<$3>>>nil, <<<$4>>>)>>>, <<<ifelse(first_char(defn(<<<__ST>>>)), <<<">>>, <<<str_scan(skip_ws(<<<$2>>>), <<<$3>>>inner_of(defn(<<<__ST>>>)), <<<$4>>>)>>>, <<<ifelse(first_char(defn(<<<__ST>>>)), LP, <<<str_scan(skip_ws(<<<$2>>>), <<<$3>>>nq_coll(defn(<<<__ST>>>)), <<<$4>>>)>>>, <<<ifelse(first_char(defn(<<<__ST>>>)), <<<[>>>, <<<str_scan(skip_ws(<<<$2>>>), <<<$3>>>nq_coll(defn(<<<__ST>>>)), <<<$4>>>)>>>, <<<ifelse(first_char(defn(<<<__ST>>>)), <<<{>>>, <<<str_scan(skip_ws(<<<$2>>>), <<<$3>>>nq_coll(defn(<<<__ST>>>)), <<<$4>>>)>>>, <<<str_scan(skip_ws(<<<$2>>>), <<<$3>>>DEC(defn(<<<__ST>>>)), <<<$4>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
define(<<<nq_coll>>>, <<<define(<<<__NQ>>>, ENC(<<<$1>>>))ifelse(first_char(defn(<<<__NQ>>>)), LP, <<<LP()nq_scan(inner_of(defn(<<<__NQ>>>)), __EE)RP()>>>, <<<ifelse(first_char(defn(<<<__NQ>>>)), <<<[>>>, <<<[nq_scan(inner_of(defn(<<<__NQ>>>)), __EE)]>>>, <<<ifelse(first_char(defn(<<<__NQ>>>)), <<<{>>>, <<<{nq_scan(inner_of(defn(<<<__NQ>>>)), __EE)}>>>, <<<ifelse(first_char(defn(<<<__NQ>>>)), <<<">>>, <<<pr_str_val(defn(<<<__NQ>>>))>>>, <<<DEC(defn(<<<__NQ>>>))>>>)>>>)>>>)>>>)>>>)dnl
define(<<<nq_scan>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, <<<$2>>>, <<<split_first(skip_ws(<<<$1>>>))nq_d(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<nq_d>>>, <<<define(<<<__NT>>>, ENC(<<<$1>>>))ifelse(first_char(defn(<<<__NT>>>)), <<<">>>, <<<nq_scan(<<<$2>>>, ifelse(len(<<<$3>>>), 0, inner_of(defn(<<<__NT>>>)), <<<$3>>>SP()inner_of(defn(<<<__NT>>>))))>>>, <<<ifelse(first_char(defn(<<<__NT>>>)), LP, <<<nq_scan(<<<$2>>>, ifelse(len(<<<$3>>>), 0, LP()nq_coll(defn(<<<__NT>>>))RP(), <<<$3>>>SP()LP()nq_coll(defn(<<<__NT>>>))RP()))>>>, <<<ifelse(first_char(defn(<<<__NT>>>)), <<<[>>>, <<<nq_scan(<<<$2>>>, ifelse(len(<<<$3>>>), 0, [nq_coll(defn(<<<__NT>>>))], <<<$3>>>SP()[nq_coll(defn(<<<__NT>>>))]))>>>, <<<ifelse(first_char(defn(<<<__NT>>>)), <<<{>>>, <<<nq_scan(<<<$2>>>, ifelse(len(<<<$3>>>), 0, {nq_coll(defn(<<<__NT>>>))}, <<<$3>>>SP(){nq_coll(defn(<<<__NT>>>))}))>>>, <<<nq_scan(<<<$2>>>, ifelse(len(<<<$3>>>), 0, DEC(defn(<<<__NT>>>)), <<<$3>>>SP()DEC(defn(<<<__NT>>>))))>>>)>>>)>>>)>>>)>>>)dnl


dnl ---- def! ----
define(<<<ev_def>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)ev_def2(defn(<<<__SF_REST>>>), defn(<<<__SF_ELEM>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_def2>>>, <<<define(<<<__DV>>>, ev_form(skip_ws(<<<$1>>>), <<<$3>>>))ifelse(__ERR, 1, __EE, <<<env_set(<<<$3>>>, <<<$2>>>, defn(<<<__DV>>>))defn(<<<__DV>>>)>>>)>>>)dnl
dnl ---- let* ----
define(<<<ev_let>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)ev_let2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_let2>>>, <<<ev_let_bind(inner_of(<<<$1>>>), <<<$2>>>, env_new(<<<$3>>>))>>>)dnl
define(<<<ev_let_bind>>>, <<<ifelse(len(<<<$1>>>), 0, <<<ev_form(skip_ws(<<<$2>>>), <<<$3>>>)>>>, <<<ev_ltb0(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_ltb0>>>, <<<ev_token(__EE, skip_ws(<<<$1>>>))ev_ltb1(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_ltb1>>>, <<<split_first(skip_ws(<<<$2>>>))ev_ltb2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$1>>>)>>>)dnl
define(<<<ev_ltb2>>>, <<<define(<<<__LV>>>, ev_form(<<<$1>>>, <<<$4>>>))env_set(<<<$4>>>, <<<$5>>>, defn(<<<__LV>>>))ev_let_bind(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
dnl ---- arithmetic ----
define(<<<ev_arith>>>, <<<eval(ev_as_scan(skip_ws(<<<$2>>>), <<<$1>>>, __EE, <<<$3>>>))>>>)dnl
define(<<<ev_as_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$3>>>, <<<ev_as_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_as_d>>>, <<<ifelse(<<<$1>>>, RP, <<<$4>>>, <<<ev_as1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ev_as2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ev_as3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ev_as4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<ev_as5(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_as5>>>, <<<ev_token(__EE, <<<$1>>>)ev_as_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<ev_as_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$5>>>))ifelse(len(<<<$4>>>), 0, <<<ev_as_scan(skip_ws(<<<$2>>>), <<<$3>>>, defn(<<<__V>>>), <<<$5>>>)>>>, <<<ev_as_scan(skip_ws(<<<$2>>>), <<<$3>>>, <<<$4>>><<<$3>>>defn(<<<__V>>>), <<<$5>>>)>>>)>>>)dnl
dnl ---- vector evaluation ----
define(<<<ev_vector>>>, <<<[ev_vec_body(inner_of(<<<$1>>>), <<<$2>>>)]>>>)dnl
define(<<<ev_vec_body>>>, <<<ev_vb_scan(skip_ws(<<<$1>>>), __EE, <<<$2>>>)>>>)dnl
define(<<<ev_vb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<ev_vb_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_vb_d>>>, <<<ifelse(<<<$1>>>, <<<]>>>, <<<$3>>>, <<<ev_vb1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_vb2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_vb3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_vb4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_vb5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_vb5>>>, <<<ev_token(__EE, <<<$1>>>)ev_vb_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_vb_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$4>>>))ifelse(len(<<<$3>>>), 0, <<<ev_vb_scan(skip_ws(<<<$2>>>), defn(<<<__V>>>), <<<$4>>>)>>>, <<<ev_vb_scan(skip_ws(<<<$2>>>), <<<$3>>>SP()defn(<<<__V>>>), <<<$4>>>)>>>)>>>)dnl
dnl ---- map evaluation ----
define(<<<ev_map>>>, <<<{dedup_pairs(ev_map_body(inner_of(<<<$1>>>), <<<$2>>>))}>>>)dnl
define(<<<map_dedup>>>, <<<translit(dedup_pairs(translit(<<<$1>>>, HS, <<< >>>)), <<< >>>, HS)>>>)dnl
define(<<<ev_map_body>>>, <<<ev_mb_scan(skip_ws(<<<$1>>>), __EE, <<<$2>>>)>>>)dnl
define(<<<ev_mb_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<ev_mb_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_mb_d>>>, <<<ifelse(<<<$1>>>, <<<}>>>, <<<$3>>>, <<<ev_mb1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_mb2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_mb3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_mb4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_mb5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mb5>>>, <<<ev_token(__EE, <<<$1>>>)ev_mb_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_mb_k>>>, <<<ev_mb_v(skip_ws(<<<$2>>>), <<<$3>>>, <<<$4>>>, <<<$1>>>)>>>)dnl
define(<<<ev_mb_v>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, __EE, <<<ev_mv_d(first_char(skip_ws(<<<$1>>>)), skip_ws(<<<$1>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_mv_d>>>, <<<ifelse(<<<$1>>>, <<<}>>>, __EE, <<<ev_mv1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$5>>>)>>>, <<<ev_mv2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$5>>>)>>>, <<<ev_mv3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$5>>>)>>>, <<<ev_mv4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_mb_join(<<<$4>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$5>>>)>>>, <<<ev_mv5(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_mv5>>>, <<<ev_token(__EE, <<<$1>>>)ev_mb_join(<<<$3>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$4>>>)>>>)dnl
define(<<<ev_mb_join>>>, <<<define(<<<__V>>>, ev_form(<<<$2>>>, <<<$1>>>))ifelse(len(<<<$4>>>), 0, <<<ev_mb_scan(skip_ws(<<<$3>>>), <<<$5>>>SP()defn(<<<__V>>>), <<<$1>>>)>>>, <<<ev_mb_scan(skip_ws(<<<$3>>>), <<<$4>>>SP()<<<$5>>>SP()defn(<<<__V>>>), <<<$1>>>)>>>)>>>)dnl
dnl ---- collection core functions ----
define(<<<ev_list_fn>>>, <<<ifelse(len(<<<$1>>>), 0, <<<LP()RP()>>>, <<<ev_lf_scan(skip_ws(<<<$1>>>), __EE, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lf_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<ev_lf_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lf_d>>>, <<<ifelse(<<<$1>>>, RP, <<<$3>>>, <<<ev_lf1(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_lf2(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_lf3(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_lf4(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>, <<<ev_lf5(<<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_lf5>>>, <<<ev_token(__EE, <<<$1>>>)ev_lf_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_lf_elem>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$4>>>))ifelse(len(<<<$3>>>), 0, <<<ev_lf_scan(skip_ws(<<<$2>>>), defn(<<<__V>>>), <<<$4>>>)>>>, <<<ev_lf_scan(skip_ws(<<<$2>>>), <<<$3>>>SP()defn(<<<__V>>>), <<<$4>>>)>>>)>>>)dnl
define(<<<ev_listq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(first_char(strip_meta(defn(<<<__V>>>))), LP, true, false)>>>)dnl
define(<<<ev_emptyq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(len(inner_of(strip_meta(defn(<<<__V>>>)))), 0, true, false)>>>)dnl
define(<<<ev_count>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__VT>>>, ENC(defn(<<<__V>>>)))ifelse(defn(<<<__VT>>>), nil, 0, <<<count_scan(skip_ws(inner_of(defn(<<<__V>>>))), 0)>>>)>>>)dnl
define(<<<count_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<split_first(<<<$1>>>)count_scan(defn(<<<__SF_REST>>>), eval($2+1))>>>)>>>)dnl
dnl ---- comparison core functions ----
define(<<<ev_eq>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<eq>>>)>>>)dnl
define(<<<ev_lt>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<lt>>>)>>>)dnl
define(<<<ev_le>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<le>>>)>>>)dnl
define(<<<ev_gt>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<gt>>>)>>>)dnl
define(<<<ev_ge>>>, <<<ev_cmp2(<<<$1>>>, <<<$2>>>, <<<ge>>>)>>>)dnl
define(<<<ev_cmp2>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)ev_cmp2a(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_cmp2a>>>, <<<define(<<<__C1>>>, ev_form(<<<$1>>>, <<<$3>>>))ev_cmp2b(defn(<<<__C1>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<ev_cmp2b>>>, <<<ifelse(len(skip_ws(<<<$2>>>)), 0, __EE, <<<split_first(skip_ws(<<<$2>>>))ev_cmp2c(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_cmp2c>>>, <<<define(<<<__C2>>>, ev_form(<<<$2>>>, <<<$4>>>))ev_cmp2d(<<<$1>>>, defn(<<<__C2>>>), <<<$5>>>)>>>)dnl
define(<<<eq_norm>>>, <<<translit(<<<$1>>>, <<<[]>>>, LP()RP())>>>)dnl
define(<<<ev_cmp2d>>>, <<<ifelse(<<<$3>>>, <<<eq>>>, <<<ifelse(first_char(ENC(<<<$1>>>)), <<<{>>>, <<<eq_map(<<<$1>>>, <<<$2>>>)>>>, <<<ifelse(eq_norm(strip_meta(<<<$1>>>)), eq_norm(strip_meta(<<<$2>>>)), true, false)>>>)>>>, <<<ev_cmp2e(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<eq_map>>>, <<<ifelse(first_char(ENC(strip_meta(<<<$2>>>))), <<<{>>>, <<<eq_mp(inner_of(strip_meta(<<<$1>>>)), inner_of(strip_meta(<<<$2>>>)))>>>, false)>>>)dnl
define(<<<eq_mp>>>, <<<ifelse(eval(eq_cnt(<<<$1>>>) - eq_cnt(<<<$2>>>)), 0, <<<eq_all(skip_ws(<<<$1>>>), skip_ws(<<<$2>>>))>>>, false)>>>)dnl
define(<<<eq_cnt>>>, <<<ifelse(len(<<<$1>>>), 0, 0, <<<split_first(<<<$1>>>)split_first(skip_ws(defn(<<<__SF_REST>>>)))eval(eq_cnt(skip_ws(defn(<<<__SF_REST>>>))) + 1)>>>)>>>)dnl
define(<<<eq_all>>>, <<<ifelse(len(<<<$1>>>), 0, true, <<<split_first(<<<$1>>>)eq_ak(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<eq_ak>>>, <<<split_first(skip_ws(<<<$2>>>))eq_av(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>)dnl
define(<<<eq_av>>>, <<<ifelse(eq_find(<<<$4>>>, <<<$1>>>, <<<$2>>>), true, <<<eq_all(skip_ws(<<<$3>>>), <<<$4>>>)>>>, false)>>>)dnl
define(<<<eq_find>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, false, <<<split_first(skip_ws(<<<$1>>>))eq_fk(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<eq_fk>>>, <<<ifelse(<<<$1>>>, <<<$3>>>, <<<split_first(skip_ws(<<<$2>>>))eq_fv(defn(<<<__SF_ELEM>>>), <<<$4>>>)>>>, <<<split_first(skip_ws(<<<$2>>>))eq_find(skip_ws(defn(<<<__SF_REST>>>)), <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<eq_fv>>>, <<<ifelse(eq_norm(strip_meta(<<<$2>>>)), eq_norm(strip_meta(<<<$1>>>)), true, false)>>>)dnl
define(<<<ev_cmp2e>>>, <<<ifelse(<<<$3>>>, <<<lt>>>, <<<ifelse(eval(<<<$1>>> < <<<$2>>>), 1, true, false)>>>, <<<ev_cmp2f(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_cmp2f>>>, <<<ifelse(<<<$3>>>, <<<le>>>, <<<ifelse(eval(<<<$1>>> <= <<<$2>>>), 1, true, false)>>>, <<<ev_cmp2g(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_cmp2g>>>, <<<ifelse(<<<$3>>>, <<<gt>>>, <<<ifelse(eval(<<<$1>>> > <<<$2>>>), 1, true, false)>>>, <<<ifelse(eval(<<<$1>>> >= <<<$2>>>), 1, true, false)>>>)>>>)dnl
dnl ---- if ----
define(<<<ev_if>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)ev_if2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_if2>>>, <<<define(<<<__C>>>, ev_form(<<<$1>>>, <<<$3>>>))define(<<<__CT>>>, ENC(defn(<<<__C>>>)))ev_if3(defn(<<<__CT>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<ev_if3>>>, <<<ifelse(<<<$1>>>, nil, <<<ev_if_false(<<<$2>>>, <<<$3>>>)>>>, <<<ev_if4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_if4>>>, <<<ifelse(<<<$1>>>, false, <<<ev_if_false(<<<$2>>>, <<<$3>>>)>>>, <<<ev_if_true(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_if_true>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, __EE, <<<split_first(skip_ws(<<<$1>>>))ev_form(defn(<<<__SF_ELEM>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_if_false>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, <<<nil>>>, <<<split_first(skip_ws(<<<$1>>>))ev_if_f2(defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_if_f2>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, <<<nil>>>, <<<split_first(skip_ws(<<<$1>>>))ev_form(defn(<<<__SF_ELEM>>>), <<<$2>>>)>>>)>>>)dnl
dnl ---- fn* ----
define(<<<ev_fn>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)ev_fn2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_fn2>>>, <<<split_first(<<<$2>>>)ev_fn3(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>)dnl
define(<<<ev_fn3>>>, <<<@LP()fn* SP()LP()inner_of(<<<$1>>>)<<<>>>RP()SP()<<<$2>>>SP()LP()$4<<<>>>RP()<<<>>>RP()>>>)dnl
dnl ---- do ----
define(<<<ev_do>>>, <<<ifelse(len(<<<$1>>>), 0, <<<nil>>>, <<<ev_do_scan(skip_ws(<<<$1>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_do_scan>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<ev_do_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_do_d>>>, <<<ifelse(<<<$1>>>, RP, __EE, <<<ev_do1(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do1>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_do2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do2>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<sf_bracket(<<<$2>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_do3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do3>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<sf_brace(<<<$2>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_do4(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<sf_string(<<<$2>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_do5(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_do5>>>, <<<ev_token(__EE, <<<$1>>>)ev_do_elem(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_do_elem>>>, <<<ifelse(len(skip_ws(<<<$2>>>)), 0, <<<ev_form(<<<$1>>>, <<<$3>>>)>>>, <<<define(<<<__DT>>>, ev_form(<<<$1>>>, <<<$3>>>))ev_do_scan(skip_ws(<<<$2>>>), <<<$3>>>)>>>)>>>)dnl
dnl ---- prn / not ----
define(<<<ev_prn>>>, <<<define(<<<__PO>>>, ev_lf_scan(skip_ws(<<<$1>>>), __EE, <<<$2>>>))syscmd(<<<printf '%s\n' '>>>DEC(defn(<<<__PO>>>))<<<'>>>)nil>>>)dnl
dnl ---- read-string ----
define(<<<ev_read_string>>>, <<<split_first(<<<$1>>>)ev_read_string2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_read_string2>>>, <<<ifelse(__ERR, 1, __EE, <<<patsubst(patsubst(patsubst(read_str(translit(unesc(inner_of(ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))), NLCH()TABCH()CRCH(), S1()S2()S3())), S1(), <<<\\n>>>), S2(), <<<\\t>>>), S3(), <<<\\r>>>)>>>)>>>)dnl
dnl 转义解码：\n → 换行，\t → tab，\r → CR，\" → "，\\ → \，\其它 → 其它
dnl ===== unesc: 转义解码链（值内部形式 -> 真实字符）=====
dnl 转义: \\n -> 换行, \\t -> tab, \\r -> CR, \\" -> ", \\\\ -> \\, \\其它 -> 其它
dnl 实现: 递归逐字符, 用 \x01 做输出分隔符(非名字字符, 防宏名粘连), 最后 translit 删除
define(<<<BS>>>, format(%c,92))dnl
define(<<<NLCH>>>, format(%c,10))dnl
define(<<<TABCH>>>, format(%c,9))dnl
define(<<<CRCH>>>, format(%c,13))dnl
define(<<<DQCH>>>, format(%c,34))dnl
define(<<<first_char>>>, <<<substr(<<<$1>>>,0,1)>>>)dnl
define(<<<rest_str>>>, <<<substr(<<<$1>>>,1)>>>)dnl
define(<<<skip2>>>, <<<substr(<<<$1>>>,2)>>>)dnl
define(<<<second_char>>>, <<<substr(<<<$1>>>,1,1)>>>)dnl
dnl ===== unesc: 转义解码（值内部形式 -> 真实字符）=====
dnl 转义: \\n -> 换行, \\t -> tab, \\r -> CR, \\" -> ", \\\\ -> \\, \\其它 -> 其它
dnl 实现: patsubst 一次性正则替换（输入引号保护, 括号安全; 先长转义后 \\\\ 防误吃）
define(<<<BS>>>, format(%c,92))dnl
define(<<<NLCH>>>, format(%c,10))dnl
define(<<<TABCH>>>, format(%c,9))dnl
define(<<<CRCH>>>, format(%c,13))dnl
define(<<<DQCH>>>, format(%c,34))dnl
define(<<<S1>>>, format(%c,1))dnl
define(<<<S2>>>, format(%c,2))dnl
define(<<<S3>>>, format(%c,3))dnl
define(<<<unesc>>>, <<<unesc_x(<<<$1>>>)>>>)dnl
define(<<<unesc_x>>>, <<<patsubst(patsubst(patsubst(patsubst(patsubst(<<<$1>>>,<<<\\n>>>,NLCH()),<<<\\t>>>,TABCH()),<<<\\r>>>,CRCH()),<<<\\">>>,DQCH()),<<<\\\\>>>,<<<\\>>>)>>>)dnl
define(<<<dq>>>, <<<">>>)dnl
dnl ---- eval ----
define(<<<ev_mal_eval>>>, <<<ev_form(ENC(ev_form(skip_ws(<<<$1>>>), <<<$2>>>)), defn(<<<__ROOT_ENV>>>))>>>)dnl
dnl ---- slurp ----
define(<<<ev_slurp>>>, <<<split_first(<<<$1>>>)ev_slurp2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_slurp2>>>, <<<define(<<<__SLF>>>, inner_of(DEC(ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))))define(<<<__SL>>>, esyscmd(<<<cat '>>>__SLF<<<'>>>))define(<<<__SLB>>>, __SL)define(<<<__SLS>>>, <<<">>>translit(__SLB, NLCH()TABCH()CRCH(), S1()S2()S3())<<<">>>)patsubst(patsubst(patsubst(defn(<<<__SLS>>>), S1(), <<<\\n>>>), S2(), <<<\\t>>>), S3(), <<<\\r>>>)>>>)dnl
dnl ---- load-file ----
define(<<<ev_load_file>>>, <<<split_first(<<<$1>>>)ev_load_file2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_load_file2>>>, <<<define(<<<__LFF>>>, inner_of(DEC(ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))))define(<<<__LF>>>, esyscmd(<<<cat '>>>__LFF<<<'>>>))define(<<<__LFB>>>, substr(__LF, 0, eval(len(__LF)-1)))define(<<<__LFC>>>, patsubst(__LFB, <<<;.*>>>, <<<>>>))ev_lf_loop(translit(ENC(__LFC), NLCH(), SP()), <<<$3>>>)>>>)dnl
dnl load-file 逐行循环：用 format(%c,10) 找换行
define(<<<NLCH>>>, format(%c,10))dnl
define(<<<ev_lf_loop>>>, <<<ifelse(len(<<<$1>>>), 0, nil, <<<ev_lfl_ws(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
dnl 跳过前导空白/换行
define(<<<ev_lfl_ws>>>, <<<ifelse(is_ws(first_char(<<<$1>>>)), 1, <<<ev_lf_loop(rest_str(<<<$1>>>), <<<$2>>>)>>>, <<<ifelse(first_char(<<<$1>>>), NLCH(), <<<ev_lf_loop(rest_str(<<<$1>>>), <<<$2>>>)>>>, <<<ev_lfl_c(<<<$1>>>, <<<$2>>>)>>>)>>>)>>>)dnl
dnl 注释行跳过（; 开头，直到换行）
define(<<<ev_lfl_c>>>, <<<ifelse(first_char(<<<$1>>>), <<<;>>>, <<<ev_lfl_skipc(substr(<<<$1>>>, 1), <<<$2>>>)>>>, <<<ev_lfl_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_lfl_skipc>>>, <<<ifelse(index(<<<$1>>>, NLCH()), -1, <<<nil>>>, <<<ev_lf_loop(substr(<<<$1>>>, eval(index(<<<$1>>>, NLCH())+1)), <<<$2>>>)>>>)>>>)dnl
dnl 按第一个字符分派：LP → 平衡组；否则读 token 到空白/换行
define(<<<ev_lfl_d>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_lfl_eval(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>, <<<ev_lfl_t(<<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_lfl_t>>>, <<<ev_token(__EE, <<<$1>>>)ev_lfl_eval(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_lfl_eval>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<define(<<<__LFR>>>, ev_form(<<<$1>>>, <<<$3>>>))>>>)ev_lf_loop(skip_ws(<<<$2>>>), <<<$3>>>)>>>)dnl
dnl ---- atom ----
define(<<<ev_atom>>>, <<<split_first(<<<$1>>>)ev_atom2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_atom2>>>, <<<define(<<<__AV>>>, ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))define(<<<__ATM_CTR>>>, eval(defn(<<<__ATM_CTR>>>)+1))define(<<<__AID>>>, defn(<<<__ATM_CTR>>>))indir(<<<define>>>, <<<__ATM>>>defn(<<<__AID>>>), defn(<<<__AV>>>))define(<<<__AOBJ>>>, ENC(<<<@>>>LP()<<<ATM:>>>defn(<<<__AID>>>)RP()))__AOBJ>>>)dnl
dnl ---- atom? ----
define(<<<ev_atomq>>>, <<<split_first(<<<$1>>>)ev_atomq2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_atomq2>>>, <<<define(<<<__AQ>>>, ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))ifelse(substr(__AQ, 0, 6), <<<@>>>LP()<<<ATM:>>>, true, false)>>>)dnl
dnl ---- deref ----
define(<<<ev_deref>>>, <<<split_first(<<<$1>>>)ev_deref2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_deref2>>>, <<<define(<<<__DF>>>, ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))ev_deref3(__DF)>>>)dnl
define(<<<LP2>>>, <<<(>>>)dnl
define(<<<RP2>>>, <<<)>>>)dnl
define(<<<SP>>>, <<< >>>)dnl
define(<<<print_atom>>>, <<<define(<<<__PAID>>>, substr(<<<$1>>>, 6, eval(len(<<<$1>>>)-7)))define(<<<__PAV>>>, indir(<<<defn>>>, <<<__ATM>>>__PAID))LP2()atom<<<>>>SP()skip_ws(defn(<<<__PAV>>>))RP2()>>>)dnl
define(<<<ev_deref3>>>, <<<define(<<<__DFID>>>, substr(<<<$1>>>, 6, eval(len(<<<$1>>>)-7)))indir(<<<defn>>>, <<<__ATM>>>__DFID)>>>)dnl
define(<<<ev_atm_or_deref>>>, <<<define(<<<__ADH>>>, substr(<<<$1>>>, 0, 6))define(<<<__ADT>>>, <<<@>>>LP()<<<ATM:>>>)ifelse(defn(<<<__ADH>>>), defn(<<<__ADT>>>), <<<print_atom(<<<$1>>>)>>>, <<<$1>>>)>>>)dnl
define(<<<ev_deref_sym>>>, <<<define(<<<__DS>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ev_deref3(__DS)>>>)dnl

dnl ---- reset! ----
define(<<<ev_reset>>>, <<<split_first(<<<$1>>>)ev_reset2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_reset2>>>, <<<define(<<<__RF>>>, ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))ev_reset3(__RF, defn(<<<__SF_REST>>>), <<<$3>>>)>>>)dnl
define(<<<ev_reset3>>>, <<<define(<<<__RFID>>>, substr(<<<$1>>>, 6, eval(len(<<<$1>>>)-7)))define(<<<__RV>>>, ev_form(skip_ws(<<<$2>>>), <<<$3>>>))indir(<<<define>>>, <<<__ATM>>>__RFID, defn(<<<__RV>>>))defn(<<<__RV>>>)>>>)dnl
dnl ---- swap! ----
define(<<<ev_swap>>>, <<<split_first(<<<$1>>>)ev_swap2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_swap2>>>, <<<define(<<<__SW>>>, ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))ev_swap3(__SW, defn(<<<__SF_REST>>>), <<<$3>>>)>>>)dnl
define(<<<ev_swap3>>>, <<<define(<<<__SWID>>>, substr(<<<$1>>>, 6, eval(len(<<<$1>>>)-7)))define(<<<__SWOLD>>>, indir(<<<defn>>>, <<<__ATM>>>__SWID))ev_swap4(__SWID, <<<$2>>>, <<<$3>>>)>>>)dnl
dnl swap! : 参数 = fn + 额外参数。先切出 fn，再求值 fn，额外参数逐个求值拼在 old 后
define(<<<ev_swap4>>>, <<<ev_sw_d(first_char(skip_ws(<<<$2>>>)), skip_ws(<<<$2>>>), $1, <<<$3>>>)>>>)dnl
define(<<<ev_sw_d>>>, <<<ifelse(<<<$1>>>, LP, <<<sf_paren(<<<$2>>>)ev_swap5(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), $3, <<<$4>>>)>>>, <<<ev_sw_e(<<<$2>>>, $3, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_sw_e>>>, <<<ev_token(__EE, <<<$1>>>)ev_swap5(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), $2, <<<$3>>>)>>>)dnl
dnl swap! : 复用 apply 的 quote 包裹模式，把已求值的 atom 旧值和其余参数逐个包成 (quote val) 后传给 apply_fn，避免对值二次求值
define(<<<ev_swap5>>>, <<<define(<<<__SWF>>>, ev_form(<<<$1>>>, <<<$4>>>))define(<<<__SWR>>>, swap_args(skip_ws(<<<$2>>>), defn(<<<__SWF>>>), LP()quote SP()defn(<<<__SWOLD>>>)RP(), <<<$4>>>))indir(<<<define>>>, <<<__ATM>>>$3, defn(<<<__SWR>>>))defn(<<<__SWR>>>)>>>)dnl
define(<<<swap_args>>>, <<<ifelse(len(<<<$1>>>), 0, <<<apply_call(<<<$2>>>, <<<$4>>>, <<<$3>>>)>>>, <<<split_first(<<<$1>>>)swap_el(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<swap_el>>>, <<<define(<<<__AV>>>, ev_form(<<<$1>>>, <<<$5>>>))swap_args(<<<$2>>>, <<<$3>>>, ifelse(len(<<<$4>>>), 0, LP()quote SP()defn(<<<__AV>>>)RP(), <<<$4>>>SP()LP()quote SP()defn(<<<__AV>>>)RP()), <<<$5>>>)>>>)dnl

define(<<<ev_not>>>, <<<define(<<<__C>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__CT>>>, ENC(defn(<<<__C>>>)))ifelse(defn(<<<__CT>>>), nil, true, <<<ifelse(defn(<<<__CT>>>), false, true, false)>>>)>>>)dnl
dnl ---- function application ----
define(<<<apply_fn>>>, <<<define(<<<__AFV>>>, strip_meta(<<<$1>>>))ifelse(substr(defn(<<<__AFV>>>), 0, 5), <<<@core>>>, <<<apply_core(substr(defn(<<<__AFV>>>), 5), <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(substr(defn(<<<__AFV>>>), 0, 2), <<<@@>>>, <<<apply_closure(substr(defn(<<<__AFV>>>), 2), <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(substr(defn(<<<__AFV>>>), 0, 1), <<<@>>>, <<<apply_closure(rest_str(defn(<<<__AFV>>>)), <<<$2>>>, <<<$3>>>)>>>, <<<err_nf(<<<$4>>>)__EE>>>)>>>)>>>)>>>)dnl
define(<<<apply_core>>>, <<<split_first(<<<$1>>>)apply_core2(defn(<<<__SF_ELEM>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<apply_core2>>>, <<<apply_core3(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<apply_core3>>>, <<<ifelse(<<<$1>>>, <<<+>>>, <<<ev_arith(<<<+>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<->>>, <<<ev_arith(<<<->>>, <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<*>>>, <<<ev_arith(<<<*>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<</>>>, <<<ev_arith(<<</>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<=>>>, <<<ev_eq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<<>>>, <<<ev_lt(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<<=>>>, <<<ev_le(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<>>>>, <<<ev_gt(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<>=>>>, <<<ev_ge(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<prn>>>, <<<ev_prn(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<println>>>, <<<ev_println(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<pr-str>>>, <<<ev_prstr(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<not>>>, <<<ev_not(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<read-string>>>, <<<ev_read_string(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<eval>>>, <<<ev_mal_eval(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<slurp>>>, <<<ev_slurp(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<list>>>, <<<ev_list_fn(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<list?>>>, <<<ev_listq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<empty?>>>, <<<ev_emptyq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<count>>>, <<<ev_count(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<str>>>, <<<ev_str(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<cons>>>, <<<ev_cons(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<concat>>>, <<<ev_concat(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<vec>>>, <<<ev_vec_disp(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<first>>>, <<<ev_first(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<rest>>>, <<<ev_rest(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<nth>>>, <<<ev_nth(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<atom>>>, <<<ev_atom(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<atom?>>>, <<<ev_atomq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<deref>>>, <<<ev_deref(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<reset!>>>, <<<ev_reset(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<swap!>>>, <<<ev_swap(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<throw>>>, <<<ev_throw_val(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<map>>>, <<<ev_map_fn(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<apply>>>, <<<ev_apply_fn(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<symbol?>>>, <<<ev_sym_disp(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<nil?>>>, <<<ev_nilq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<true?>>>, <<<ev_trueq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<false?>>>, <<<ev_falseq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<number?>>>, <<<ev_numberq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<string?>>>, <<<ev_stringq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<fn?>>>, <<<ev_fnq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<vector?>>>, <<<ev_vectorq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<sequential?>>>, <<<ev_sequentialq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<map?>>>, <<<ev_mapq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<hash-map?>>>, <<<ev_hashmapq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<keyword?>>>, <<<ev_keywordq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<keyword>>>, <<<ev_keyword(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<hash-map>>>, <<<ev_hashmap(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<get>>>, <<<ev_get(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<contains?>>>, <<<ev_containsq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<keys>>>, <<<ev_keys(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<vals>>>, <<<ev_vals(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<assoc>>>, <<<ev_assoc(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<dissoc>>>, <<<ev_dissoc(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<with-meta>>>, <<<ev_withmeta(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<meta>>>, <<<ev_meta(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<readline>>>, <<<ev_readline(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<time-ms>>>, <<<ev_timems(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<seq>>>, <<<ev_seq(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<conj>>>, <<<ev_conj(<<<$2>>>, <<<$3>>>)>>>, <<<ev_sym_disp(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
define(<<<err_nf>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, <<<'$1' is not a function>>>)>>>)dnl
define(<<<apply_closure>>>, <<<split_first(inner_of(<<<$1>>>))apply_c2(defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<apply_c2>>>, <<<split_first(<<<$1>>>)apply_c3(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<apply_c3>>>, <<<split_first(<<<$2>>>)apply_c4(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<apply_c4>>>, <<<split_first(<<<$3>>>)apply_c5(<<<$1>>>, <<<$2>>>, defn(<<<__SF_ELEM>>>), <<<$4>>>, <<<$5>>>)>>>)dnl
define(<<<apply_c5>>>, <<<apply_c6(<<<$1>>>, <<<$2>>>, <<<$4>>>, inner_of(<<<$3>>>), <<<$5>>>)>>>)dnl
define(<<<apply_c6>>>, <<<define(<<<__NE>>>, env_new(<<<$4>>>))bind_params(inner_of(<<<$1>>>), <<<$3>>>, defn(<<<__NE>>>), <<<$5>>>)ev_form(<<<$2>>>, defn(<<<__NE>>>))>>>)dnl
define(<<<bind_params>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<ev_bp0(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_bp_rest>>>, <<<ev_token(__EE, skip_ws(<<<$1>>>))ev_bp_rest2(defn(<<<__SF_ELEM>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<ev_bp_rest2>>>, <<<define(<<<__RA>>>, ev_lf_scan(skip_ws(<<<$2>>>), __EE, <<<$4>>>))define(<<<__RP>>>, LP()defn(<<<__RA>>>)RP())env_set(<<<$3>>>, <<<$1>>>, defn(<<<__RP>>>))>>>)dnl
define(<<<ev_bp0>>>, <<<ev_token(__EE, skip_ws(<<<$1>>>))ifelse(defn(<<<__SF_ELEM>>>), <<<&>>>, <<<ev_bp_rest(defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<ev_bp1(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<ev_bp1>>>, <<<ifelse(len(skip_ws(<<<$3>>>)), 0, __EE, <<<split_first(skip_ws(<<<$3>>>))ev_bp2(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<ev_bp2>>>, <<<define(<<<__A>>>, ev_form(<<<$2>>>, <<<$6>>>))env_set(<<<$5>>>, <<<$1>>>, defn(<<<__A>>>))bind_params(<<<$4>>>, <<<$3>>>, <<<$5>>>, <<<$6>>>)>>>)dnl
dnl ---- macros: defmacro! / macroexpand / macro? ----
define(<<<ev_defmacro>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)ev_dm2(defn(<<<__SF_REST>>>), defn(<<<__SF_ELEM>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_dm2>>>, <<<define(<<<__DV>>>, ev_form(skip_ws(<<<$1>>>), <<<$3>>>))ifelse(__ERR, 1, __EE, <<<define(<<<__MV>>>, @defn(<<<__DV>>>))env_set(<<<$3>>>, <<<$2>>>, defn(<<<__MV>>>))defn(<<<__MV>>>)>>>)>>>)dnl
define(<<<ev_macroq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(substr(strip_meta(defn(<<<__V>>>)), 0, 2), <<<@@>>>, true, false)>>>)dnl
define(<<<ev_macroexpand>>>, <<<define(<<<__MX>>>, me_loop(skip_ws(<<<$1>>>), <<<$2>>>))defn(<<<__MX>>>)>>>)dnl
define(<<<me_loop>>>, <<<ifelse(first_char(<<<$1>>>), LP, <<<me_l0(<<<$1>>>, <<<$2>>>)>>>, <<<$1>>>)>>>)dnl
define(<<<me_l0>>>, <<<ifelse(len(inner_of(<<<$1>>>)), 0, <<<$1>>>, <<<split_first(inner_of(<<<$1>>>))me_l1(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<me_l1>>>, <<<me_l2(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<me_l2>>>, <<<ifelse(<<<$1>>>, LP, <<<$4>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<$4>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<$4>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<$4>>>, <<<ifelse(<<<$1>>>, <<<:>>>, <<<$4>>>, <<<ifelse(<<<$1>>>, <<<@>>>, <<<$4>>>, <<<ifelse(<<<$1>>>, <<<->>>, <<<ifelse(is_number(<<<$2>>>), 1, <<<$4>>>, <<<me_sym(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>, <<<me_sym(<<<$2>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
define(<<<me_sym>>>, <<<define(<<<__MV>>>, mc_env_get(<<<$4>>>, <<<$1>>>))ifelse(defn(<<<__MV>>>), NF, <<<$3>>>, <<<ifelse(substr(defn(<<<__MV>>>), 0, 2), <<<@@>>>, <<<define(<<<__ME>>>, mc_apply(defn(<<<__MV>>>), <<<$2>>>, <<<$4>>>))me_loop(defn(<<<__ME>>>), <<<$4>>>)>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<mc_apply>>>, <<<split_first(inner_of(rest_str(rest_str(<<<$1>>>))))mc_a2(defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<mc_a2>>>, <<<split_first(<<<$1>>>)mc_a3(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<mc_a3>>>, <<<split_first(<<<$2>>>)mc_a4(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<mc_a4>>>, <<<split_first(<<<$3>>>)mc_a5(<<<$1>>>, <<<$2>>>, defn(<<<__SF_ELEM>>>), <<<$4>>>, <<<$5>>>)>>>)dnl
define(<<<mc_a5>>>, <<<mc_a6(<<<$1>>>, <<<$2>>>, <<<$4>>>, inner_of(<<<$3>>>), <<<$5>>>)>>>)dnl
define(<<<mc_a6>>>, <<<define(<<<__NE>>>, env_new(<<<$4>>>))bind_raw(inner_of(<<<$1>>>), <<<$3>>>, defn(<<<__NE>>>), <<<$5>>>)ev_form(<<<$2>>>, defn(<<<__NE>>>))>>>)dnl
define(<<<bind_raw>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<mc_bp0(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<mc_bp0>>>, <<<ev_token(__EE, skip_ws(<<<$1>>>))ifelse(defn(<<<__SF_ELEM>>>), <<<&>>>, <<<mc_bp_rest(defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<mc_bp1(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<mc_bp1>>>, <<<ifelse(len(skip_ws(<<<$3>>>)), 0, __EE, <<<split_first(skip_ws(<<<$3>>>))mc_bp2(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$4>>>, <<<$5>>>)>>>)>>>)dnl
define(<<<mc_bp2>>>, <<<env_set(<<<$5>>>, <<<$1>>>, <<<$2>>>)bind_raw(<<<$4>>>, <<<$3>>>, <<<$5>>>, <<<$6>>>)>>>)dnl
define(<<<mc_bp_rest>>>, <<<define(<<<__MRA>>>, skip_ws(<<<$2>>>))env_set(<<<$3>>>, <<<$1>>>, LP()defn(<<<__MRA>>>)RP())>>>)dnl
dnl ---- first / rest / nth ----
define(<<<ev_first>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__VT>>>, ENC(defn(<<<__V>>>)))ifelse(defn(<<<__VT>>>), nil, nil, <<<ifelse(first_char(defn(<<<__V>>>)), LP, <<<first_scan(inner_of(defn(<<<__V>>>)))>>>, <<<ifelse(first_char(defn(<<<__V>>>)), <<<[>>>, <<<first_scan(inner_of(defn(<<<__V>>>)))>>>, nil)>>>)>>>)>>>)dnl
define(<<<first_scan>>>, <<<ifelse(len(<<<$1>>>), 0, nil, <<<split_first(<<<$1>>>)defn(<<<__SF_ELEM>>>)>>>)>>>)dnl
define(<<<ev_rest>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__VT>>>, ENC(defn(<<<__V>>>)))ifelse(defn(<<<__VT>>>), nil, <<<LP()RP()>>>, <<<ifelse(first_char(defn(<<<__V>>>)), LP, <<<rest_scan(inner_of(defn(<<<__V>>>)))>>>, <<<ifelse(first_char(defn(<<<__V>>>)), <<<[>>>, <<<rest_scan(inner_of(defn(<<<__V>>>)))>>>, <<<LP()RP()>>>)>>>)>>>)>>>)dnl
define(<<<rest_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<LP()RP()>>>, <<<split_first(<<<$1>>>)ifelse(len(defn(<<<__SF_REST>>>)), 0, <<<LP()RP()>>>, <<<defn(<<<__SF_REST>>>)>>>)>>>)>>>)dnl
define(<<<ev_nth>>>, <<<split_first(<<<$1>>>)ev_nth2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_nth2>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$3>>>))define(<<<__N>>>, ev_form(skip_ws(<<<$2>>>), <<<$3>>>))nth_scan(inner_of(defn(<<<__V>>>)), defn(<<<__N>>>))>>>)dnl
define(<<<nth_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<err_nth_index>>> , <<<ifelse(<<<$2>>>, 0, <<<split_first(<<<$1>>>)defn(<<<__SF_ELEM>>>)>>>, <<<split_first(<<<$1>>>)nth_scan(defn(<<<__SF_REST>>>), eval(<<<$2>>>-1))>>>)>>>)>>>)dnl
define(<<<err_nth_index>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, nth: index out of range)__EE>>>)dnl
dnl ---- cond (special form) ----
define(<<<ev_cond>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, nil, <<<split_first(skip_ws(<<<$1>>>))ev_cond2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_cond2>>>, <<<define(<<<__C>>>, ev_form(<<<$1>>>, <<<$3>>>))define(<<<__CT>>>, ENC(defn(<<<__C>>>)))ifelse(defn(<<<__CT>>>), nil, <<<ev_cond_skip(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(defn(<<<__CT>>>), false, <<<ev_cond_skip(<<<$2>>>, <<<$3>>>)>>>, <<<ev_cond_val(<<<$2>>>, <<<$3>>>)>>>)>>>)>>>)dnl
define(<<<ev_cond_skip>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, nil, <<<split_first(skip_ws(<<<$1>>>))ev_cond_skip2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_cond_skip2>>>, <<<ifelse(len(skip_ws(<<<$2>>>)), 0, nil, <<<split_first(skip_ws(<<<$2>>>))ev_cond2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>)>>>)dnl
define(<<<ev_cond_val>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, <<<err_cond_odd(<<<$2>>>)__EE>>>, <<<split_first(skip_ws(<<<$1>>>))ev_form(defn(<<<__SF_ELEM>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<err_cond_odd>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, cond: odd number of forms)__EE>>>)dnl
dnl ---- try* / catch* / throw ----
define(<<<ev_throw>>>, <<<ev_throw_val(skip_ws(<<<$1>>>), <<<$2>>>)>>>)dnl
define(<<<ev_throw_val>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRVAL>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__ERRMSG>>>, Exception: DEC(defn(<<<__ERRVAL>>>)))__EE>>>)dnl
define(<<<ev_try>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)ev_try2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<ev_try2>>>, <<<ifelse(len(skip_ws(<<<$2>>>)), 0, <<<ev_form(<<<$1>>>, <<<$3>>>)>>>, <<<define(<<<__TEO>>>, defn(<<<__ERR>>>))define(<<<__TEM>>>, defn(<<<__ERRMSG>>>))define(<<<__TVO>>>, defn(<<<__ERRVAL>>>))define(<<<__ERRVAL>>>, )define(<<<__TR>>>, ev_form(<<<$1>>>, <<<$3>>>))ifelse(defn(<<<__ERR>>>), 1, <<<define(<<<__ERR>>>, 0)ev_try_catch(<<<$2>>>, ifelse(len(defn(<<<__ERRVAL>>>)), 0, <<<">>>defn(<<<__ERRMSG>>>)<<<">>>, defn(<<<__ERRVAL>>>)), <<<$3>>>)>>>, <<<define(<<<__ERR>>>, defn(<<<__TEO>>>))define(<<<__ERRMSG>>>, defn(<<<__TEM>>>))define(<<<__ERRVAL>>>, defn(<<<__TVO>>>))defn(<<<__TR>>>)>>>)>>>)>>>)dnl
define(<<<ev_try_catch>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)ev_tc2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<ev_tc2>>>, <<<split_first(inner_of(<<<$1>>>))ev_tc3(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<ev_tc3>>>, <<<split_first(<<<$2>>>)ev_tc4(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<ev_tc4>>>, <<<define(<<<__NE>>>, env_new(<<<$4>>>))env_set(defn(<<<__NE>>>), <<<$1>>>, <<<$3>>>)ev_form(<<<$2>>>, defn(<<<__NE>>>))>>>)dnl
dnl ---- map / apply ----
define(<<<ev_map_fn>>>, <<<split_first(<<<$1>>>)ev_map2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_map2>>>, <<<define(<<<__MF>>>, ev_form(<<<$1>>>, <<<$3>>>))define(<<<__ML>>>, ev_form(skip_ws(<<<$2>>>), <<<$3>>>))map_scan(inner_of(defn(<<<__ML>>>)), defn(<<<__MF>>>), __EE, <<<$3>>>)>>>)dnl
define(<<<map_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<ifelse(len(<<<$3>>>), 0, __EE, <<<$3>>>)>>>, <<<split_first(<<<$1>>>)map_el(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<map_el>>>, <<<define(<<<__MR>>>, apply_fn(<<<$3>>>, LP()quote SP()<<<$1>>>RP(), <<<$5>>>, __EE))ifelse(defn(<<<__ERR>>>), 1, __EE, <<<map_scan(<<<$2>>>, <<<$3>>>, ifelse(len(<<<$4>>>), 0, <<<defn(<<<__MR>>>)>>>, <<<$4>>>SP()defn(<<<__MR>>>)), <<<$5>>>)>>>)>>>)dnl
define(<<<ev_apply_fn>>>, <<<split_first(<<<$1>>>)ev_apply2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_apply2>>>, <<<define(<<<__F>>>, ev_form(<<<$1>>>, <<<$3>>>))apply_args(skip_ws(<<<$2>>>), defn(<<<__F>>>), __EE, <<<$3>>>)>>>)dnl
define(<<<apply_args>>>, <<<ifelse(len(<<<$1>>>), 0, <<<apply_call(<<<$2>>>, <<<$4>>>, <<<$3>>>)>>>, <<<split_first(<<<$1>>>)apply_el(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<apply_el>>>, <<<ifelse(len(<<<$2>>>), 0, <<<apply_last(<<<$1>>>, <<<$3>>>, <<<$4>>>, <<<$5>>>)>>>, <<<define(<<<__AV>>>, ev_form(<<<$1>>>, <<<$5>>>))apply_args(<<<$2>>>, <<<$3>>>, ifelse(len(<<<$4>>>), 0, LP()quote SP()defn(<<<__AV>>>)RP(), <<<$4>>>SP()LP()quote SP()defn(<<<__AV>>>)RP()), <<<$5>>>)>>>)>>>)dnl
define(<<<apply_last>>>, <<<define(<<<__AL>>>, ev_form(<<<$1>>>, <<<$4>>>))apply_expand(inner_of(defn(<<<__AL>>>)), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<apply_expand>>>, <<<ifelse(len(<<<$1>>>), 0, <<<apply_call(<<<$2>>>, <<<$4>>>, <<<$3>>>)>>>, <<<split_first(<<<$1>>>)apply_expand(defn(<<<__SF_REST>>>), <<<$2>>>, ifelse(len(<<<$3>>>), 0, LP()quote SP()defn(<<<__SF_ELEM>>>)RP(), <<<$3>>>SP()LP()quote SP()defn(<<<__SF_ELEM>>>)RP()), <<<$4>>>)>>>)>>>)dnl
define(<<<apply_call>>>, <<<apply_fn(<<<$1>>>, <<<$3>>>, <<<$2>>>, __EE)>>>)dnl
dnl ---- type predicates ----
define(<<<ev_symbolq>>>, <<<define(<<<__SV>>>, skip_ws(<<<$1>>>))define(<<<__V>>>, ev_form(defn(<<<__SV>>>), <<<$2>>>))ifelse(__ERR, 1, <<<sym_like(defn(<<<__SV>>>))>>>, <<<sym_check(defn(<<<__V>>>))>>>)>>>)dnl
define(<<<sym_like>>>, <<<ifelse(len(<<<$1>>>), 0, false, <<<ifelse(first_char(<<<$1>>>), <<<">>>, false, <<<ifelse(first_char(<<<$1>>>), LP, false, <<<ifelse(first_char(<<<$1>>>), <<<[>>>, false, <<<ifelse(first_char(<<<$1>>>), <<<{>>>, false, <<<ifelse(first_char(<<<$1>>>), <<<:>>>, false, <<<ifelse(first_char(<<<$1>>>), <<<@>>>, false, <<<ifelse(is_number(<<<$1>>>), 1, false, true)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
define(<<<sym_check>>>, <<<define(<<<__VT>>>, ENC(<<<$1>>>))ifelse(defn(<<<__VT>>>), nil, false, <<<ifelse(defn(<<<__VT>>>), true, false, <<<ifelse(defn(<<<__VT>>>), false, false, <<<ifelse(first_char(defn(<<<__VT>>>)), <<<">>>, false, <<<ifelse(first_char(defn(<<<__VT>>>)), LP, false, <<<ifelse(first_char(defn(<<<__VT>>>)), <<<[>>>, false, <<<ifelse(first_char(defn(<<<__VT>>>)), <<<{>>>, false, <<<ifelse(first_char(defn(<<<__VT>>>)), <<<:>>>, false, <<<ifelse(first_char(defn(<<<__VT>>>)), <<<@>>>, false, <<<ifelse(is_number(defn(<<<__VT>>>)), 1, false, true)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
define(<<<ev_nilq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(ENC(defn(<<<__V>>>)), nil, true, false)>>>)dnl
define(<<<ev_trueq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(ENC(defn(<<<__V>>>)), true, true, false)>>>)dnl
define(<<<ev_falseq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(ENC(defn(<<<__V>>>)), false, true, false)>>>)dnl
define(<<<ev_numberq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(is_number(defn(<<<__V>>>)), 1, true, false)>>>)dnl
define(<<<ev_stringq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(first_char(defn(<<<__V>>>)), <<<">>>, true, false)>>>)dnl
define(<<<ev_fnq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__FQV>>>, strip_meta(defn(<<<__V>>>)))define(<<<__FQH2>>>, substr(defn(<<<__FQV>>>), 0, 2))define(<<<__FQH6>>>, substr(defn(<<<__FQV>>>), 0, 6))define(<<<__FQATM>>>, <<<@>>>LP()<<<ATM:>>>)ifelse(first_char(defn(<<<__FQV>>>)), <<<@>>>, <<<ifelse(defn(<<<__FQH2>>>), <<<@@>>>, false, <<<ifelse(defn(<<<__FQH6>>>), defn(<<<__FQATM>>>), false, true)>>>)>>>, false)>>>)dnl
define(<<<ev_vectorq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(first_char(strip_meta(defn(<<<__V>>>))), <<<[>>>, true, false)>>>)dnl
define(<<<ev_sequentialq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(first_char(strip_meta(defn(<<<__V>>>))), LP, true, <<<ifelse(first_char(strip_meta(defn(<<<__V>>>))), <<<[>>>, true, false)>>>)>>>)dnl
define(<<<ev_mapq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(first_char(strip_meta(defn(<<<__V>>>))), <<<{>>>, true, false)>>>)dnl
define(<<<ev_hashmapq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(first_char(strip_meta(defn(<<<__V>>>))), <<<{>>>, true, false)>>>)dnl
define(<<<ev_keywordq>>>, <<<define(<<<__V>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))ifelse(first_char(defn(<<<__V>>>)), <<<:>>>, true, false)>>>)dnl
dnl ---- keyword / hash-map ----
define(<<<ev_keyword>>>, <<<define(<<<__K>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__KT>>>, ENC(defn(<<<__K>>>)))ifelse(first_char(defn(<<<__KT>>>)), <<<">>>, <<<:>>>inner_of(defn(<<<__KT>>>)), <<<ifelse(first_char(defn(<<<__KT>>>)), <<<:>>>, <<<defn(<<<__KT>>>)>>>, <<<:>>>defn(<<<__KT>>>))>>>)>>>)dnl
define(<<<ev_symbol>>>, <<<define(<<<__SY>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__SYT>>>, ENC(defn(<<<__SY>>>)))ifelse(first_char(defn(<<<__SYT>>>)), <<<">>>, inner_of(defn(<<<__SYT>>>)), <<<defn(<<<__SYT>>>)>>>)>>>)dnl
define(<<<ev_sym_disp>>>, <<<ifelse(<<<$1>>>, <<<symbol>>>, <<<ev_symbol(<<<$2>>>, <<<$3>>>)>>>, <<<ifelse(<<<$1>>>, <<<symbol?>>>, <<<ev_symbolq(<<<$2>>>, <<<$3>>>)>>>, <<<__EE>>>)>>>)>>>)dnl
define(<<<ev_hashmap>>>, <<<define(<<<__H>>>, ev_lf_scan(skip_ws(<<<$1>>>), __EE, <<<$2>>>)){dedup_pairs(defn(<<<__H>>>))}>>>)dnl
define(<<<ev_get>>>, <<<split_first(<<<$1>>>)ev_get2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_get2>>>, <<<define(<<<__M>>>, ev_form(<<<$1>>>, <<<$3>>>))define(<<<__K>>>, ev_form(skip_ws(<<<$2>>>), <<<$3>>>))get_scan(inner_of(defn(<<<__M>>>)), defn(<<<__K>>>))>>>)dnl
define(<<<get_scan>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, nil, <<<split_first(skip_ws(<<<$1>>>))get_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<get_k>>>, <<<ifelse(<<<$1>>>, <<<$3>>>, <<<split_first(skip_ws(<<<$2>>>))defn(<<<__SF_ELEM>>>)>>>, <<<get_scan(get_skip(<<<$2>>>), <<<$3>>>)>>>)>>>)dnl
define(<<<get_skip>>>, <<<split_first(skip_ws(<<<$1>>>))defn(<<<__SF_REST>>>)>>>)dnl
define(<<<ev_containsq>>>, <<<split_first(<<<$1>>>)ev_cont2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_cont2>>>, <<<define(<<<__M>>>, ev_form(<<<$1>>>, <<<$3>>>))define(<<<__K>>>, ev_form(skip_ws(<<<$2>>>), <<<$3>>>))cont_scan(inner_of(defn(<<<__M>>>)), defn(<<<__K>>>))>>>)dnl
define(<<<cont_scan>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, false, <<<split_first(skip_ws(<<<$1>>>))cont_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<cont_k>>>, <<<ifelse(<<<$1>>>, <<<$3>>>, true, <<<cont_scan(cont_skip(<<<$2>>>), <<<$3>>>)>>>)>>>)dnl
define(<<<cont_skip>>>, <<<split_first(skip_ws(<<<$1>>>))defn(<<<__SF_REST>>>)>>>)dnl
define(<<<ev_keys>>>, <<<define(<<<__M>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))keys_scan(inner_of(defn(<<<__M>>>)), __EE)>>>)dnl
define(<<<keys_scan>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, <<<ifelse(len(<<<$2>>>), 0, __EE, <<<$2>>>)>>>, <<<split_first(skip_ws(<<<$1>>>))keys_el(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<keys_el>>>, <<<keys_skip2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<keys_skip2>>>, <<<split_first(skip_ws(<<<$2>>>))keys_scan(defn(<<<__SF_REST>>>), ifelse(len(<<<$3>>>), 0, <<<$1>>>, <<<$3>>>SP()<<<$1>>>))>>>)dnl
define(<<<ev_vals>>>, <<<define(<<<__M>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))vals_scan(inner_of(defn(<<<__M>>>)), __EE)>>>)dnl
define(<<<vals_scan>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, <<<ifelse(len(<<<$2>>>), 0, __EE, <<<$2>>>)>>>, <<<split_first(skip_ws(<<<$1>>>))vals_el(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<vals_el>>>, <<<vals_skip2(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)dnl
define(<<<vals_skip2>>>, <<<split_first(skip_ws(<<<$2>>>))vals_scan(defn(<<<__SF_REST>>>), ifelse(len(<<<$3>>>), 0, <<<defn(<<<__SF_ELEM>>>)>>>, <<<$3>>>SP()defn(<<<__SF_ELEM>>>)))>>>)dnl
define(<<<ev_assoc>>>, <<<split_first(<<<$1>>>)ev_assoc2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_assoc2>>>, <<<define(<<<__M>>>, ev_form(<<<$1>>>, <<<$3>>>))assoc_collect(skip_ws(<<<$2>>>), __EE, inner_of(defn(<<<__M>>>)), <<<$3>>>)>>>)dnl
define(<<<assoc_collect>>>, <<<ifelse(len(<<<$1>>>), 0, <<<{assoc_del(<<<$2>>>, <<<$3>>>)}>>>, <<<split_first(<<<$1>>>)assoc_ck(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<assoc_ck>>>, <<<define(<<<__AK>>>, ev_form(<<<$1>>>, <<<$5>>>))split_first(skip_ws(<<<$2>>>))assoc_cv(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>, defn(<<<__AK>>>), <<<$5>>>)>>>)dnl
define(<<<assoc_cv>>>, <<<define(<<<__AV>>>, ev_form(<<<$1>>>, <<<$6>>>))assoc_collect(<<<$2>>>, ifelse(len(<<<$3>>>), 0, <<<defn(<<<__AK>>>)SP()defn(<<<__AV>>>)>>>, <<<$3>>>SP()defn(<<<__AK>>>)SP()defn(<<<__AV>>>)), <<<$4>>>, <<<$6>>>)>>>)dnl
define(<<<assoc_del>>>, <<<dedup_pairs(ifelse(len(skip_ws(<<<$2>>>)), 0, <<<$1>>>, <<<$2>>> <<<$1>>>))>>>)dnl
define(<<<dedup_pairs>>>, <<<ifelse(len(skip_ws(<<<$1>>>)), 0, __EE, <<<split_first(skip_ws(<<<$1>>>))dedup_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>))>>>)>>>)dnl
define(<<<dedup_k>>>, <<<split_first(skip_ws(<<<$2>>>))dedup_v(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>))>>>)dnl
define(<<<dedup_v>>>, <<<ifelse(mk_has(skip_ws(<<<$3>>>), <<<$1>>>), 1, <<<dedup_pairs(skip_ws(<<<$3>>>))>>>, <<<ifelse(len(skip_ws(<<<$3>>>)), 0, <<<$1>>> <<<$2>>>, <<<$1>>> <<<$2>>> <<<dedup_pairs(skip_ws(<<<$3>>>))>>>)>>>)>>>)dnl
define(<<<mk_has>>>, <<<ifelse(len(<<<$1>>>), 0, 0, <<<split_first(<<<$1>>>)mk_hk(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<mk_hk>>>, <<<ifelse(<<<$1>>>, <<<$3>>>, 1, <<<split_first(skip_ws(<<<$2>>>))mk_hv(defn(<<<__SF_REST>>>), <<<$3>>>)>>>)>>>)dnl
define(<<<mk_hv>>>, <<<mk_has(skip_ws(<<<$1>>>), <<<$2>>>)>>>)dnl


define(<<<del_one>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(<<<$1>>>)del_k(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<del_k>>>, <<<ifelse(<<<$1>>>, <<<$3>>>, <<<del_skip(<<<$2>>>, <<<$3>>>)>>>, <<<del_keep(<<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<del_skip>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<split_first(skip_ws(<<<$1>>>))del_one(skip_ws(defn(<<<__SF_REST>>>)), <<<$2>>>)>>>)>>>)dnl
define(<<<del_keep>>>, <<<split_first(skip_ws(<<<$2>>>))del_keep2(<<<$1>>>, defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>)>>>)dnl
define(<<<del_keep2>>>, <<<del_k2b(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<del_k2b>>>, <<<ifelse(len(skip_ws(<<<$3>>>)), 0, <<<del_k2e(<<<$1>>>, <<<$2>>>)>>>, <<<del_k2f(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<del_k2e>>>, <<<$1>>>SP()<<<$2>>>)dnl
define(<<<del_k2f>>>, <<<define(<<<__DK2>>>, del_one(skip_ws(<<<$3>>>), <<<$4>>>))<<<$1>>>SP()<<<$2>>>ifelse(len(defn(<<<__DK2>>>)), 0, , <<<SP()defn(<<<__DK2>>>)>>>)>>>)dnl
define(<<<ev_dissoc>>>, <<<split_first(<<<$1>>>)ev_dissoc2(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)dnl
define(<<<ev_dissoc2>>>, <<<define(<<<__M>>>, ev_form(<<<$1>>>, <<<$3>>>))dissoc_scan(skip_ws(<<<$2>>>), inner_of(defn(<<<__M>>>)))>>>)dnl
define(<<<dissoc_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<{<<<$2>>>}>>>, <<<split_first(<<<$1>>>)dissoc_dk(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$2>>>)>>>)>>>)dnl
define(<<<dissoc_dk>>>, <<<dissoc_scan(<<<$2>>>, del_one(<<<$3>>>, <<<$1>>>))>>>)dnl
dnl ---- pr-str / println ----
define(<<<str_encode>>>, <<<patsubst(patsubst(patsubst(patsubst(patsubst(<<<$1>>>, <<<\\>>>, <<<\\\\>>>), <<<">>>, <<<\\">>>), <<<NLCH()>>>, <<<\n>>>), <<<TABCH()>>>, <<<\t>>>), <<<CRCH()>>>, <<<\r>>>)>>>)dnl
define(<<<pr_str_val>>>, <<<">>><<<inner_of(<<<$1>>>)>>><<<">>>)dnl
define(<<<ev_prstr>>>, <<<define(<<<__SO>>>, prstr_scan(skip_ws(<<<$1>>>), __EE, <<<$2>>>))<<<">>>esc_str(defn(<<<__SO>>>))<<<">>>>>>)dnl
define(<<<esc_str>>>, <<<patsubst(patsubst(<<<$1>>>, <<<\\>>>, <<<\\\\>>>), <<<">>>, <<<\\">>>)>>>)dnl
define(<<<prstr_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<prstr_d(first_char(<<<$1>>>), <<<$1>>>, <<<$2>>>, <<<$3>>>)>>>)>>>)dnl
define(<<<prstr_d>>>, <<<ifelse(<<<$1>>>, RP, <<<$3>>>, <<<prstr_el(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<prstr_el>>>, <<<split_first(<<<$2>>>)prstr_join(defn(<<<__SF_ELEM>>>), defn(<<<__SF_REST>>>), <<<$3>>>, <<<$4>>>)>>>)dnl
define(<<<prstr_join>>>, <<<define(<<<__V>>>, ev_form(<<<$1>>>, <<<$4>>>))define(<<<__VT>>>, ENC(defn(<<<__V>>>)))ifelse(defn(<<<__VT>>>), nil, <<<prstr_scan(skip_ws(<<<$2>>>), ifelse(len(<<<$3>>>), 0, nil, <<<$3>>>SP()nil), <<<$4>>>)>>>, <<<prstr_scan(skip_ws(<<<$2>>>), ifelse(len(<<<$3>>>), 0, <<<ifelse(first_char(defn(<<<__VT>>>)), <<<">>>, <<<pr_str_val(defn(<<<__VT>>>))>>>, <<<DEC(defn(<<<__VT>>>))>>>)>>>, <<<$3>>>SP()ifelse(first_char(defn(<<<__VT>>>)), <<<">>>, <<<pr_str_val(defn(<<<__VT>>>))>>>, <<<DEC(defn(<<<__VT>>>))>>>)), <<<$4>>>)>>>)>>>)dnl
define(<<<ev_println>>>, <<<ev_prn(<<<$1>>>, <<<$2>>>)nil>>>)dnl
dnl ---- token scan ----
define(<<<ev_token>>>, <<<ifelse(len(<<<$2>>>), 0, <<<sf_done(<<<$1>>>, __EE)>>>, <<<ev_tk1(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_tk1>>>, <<<ifelse(is_ws(first_char(<<<$2>>>)), 1, <<<sf_done(<<<$1>>>, skip_ws(<<<$2>>>))>>>, <<<ev_tk2(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
define(<<<ev_tk2>>>, <<<ifelse(first_char(<<<$2>>>), RP, <<<sf_done(<<<$1>>>, <<<$2>>>)>>>, <<<ev_token(<<<$1>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>)>>>)dnl
dnl ---- split_first ----
define(<<<split_first>>>, <<<sf_scan(__EE, skip_ws(<<<$1>>>))>>>)dnl
define(<<<sf_scan>>>, <<<ifelse(len(<<<$2>>>), 0, <<<sf_done(<<<$1>>>, __EE)>>>, <<<sf_s0(<<<$1>>>, <<<$2>>>)>>>)>>>)dnl
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
define(<<<sf_str1>>>, <<<ifelse(first_char(<<<$1>>>), <<<">>>, <<<sf_done(<<<$2>>>first_char(<<<$1>>>), rest_str(<<<$1>>>))>>>, <<<ifelse(first_char(<<<$1>>>), BS, <<<sf_str_scan(skip2(<<<$1>>>), <<<$2>>>defn(<<<BS>>>)second_char(<<<$1>>>))>>>, <<<sf_str_scan(rest_str(<<<$1>>>), <<<$2>>>first_char(<<<$1>>>))>>>)>>>)>>>)dnl
dnl ---- stepA: metadata support ----
dnl meta wrapper format: @<LP>META:<meta>\x04<value>
define(<<<WM_SEP>>>, format(%c,4))dnl
define(<<<WM_PFX>>>, <<<@>>>LP()<<<META:>>>)dnl
define(<<<is_meta>>>, <<<ifelse(substr(<<<$1>>>, 0, 7), <<<@>>>LP()<<<META:>>>, 1, 0)>>>)dnl
define(<<<strip_meta>>>, <<<ifelse(is_meta(<<<$1>>>), 1, <<<substr(<<<$1>>>, eval(index(<<<$1>>>, format(%c,4))+1))>>>, <<<$1>>>)>>>)dnl
define(<<<get_meta>>>, <<<ifelse(is_meta(<<<$1>>>), 1, <<<substr(<<<$1>>>, 7, eval(index(<<<$1>>>, format(%c,4))-7))>>>, <<<nil>>>)>>>)dnl
define(<<<ev_withmeta>>>, <<<split_first(skip_ws(<<<$1>>>))define(<<<__WM_R>>>, skip_ws(defn(<<<__SF_REST>>>)))define(<<<__WMV>>>, ev_form(defn(<<<__SF_ELEM>>>), <<<$2>>>))define(<<<__WMM>>>, ev_form(defn(<<<__WM_R>>>), <<<$2>>>))<<<@>>>LP()<<<META:>>>defn(<<<__WMM>>>)format(%c,4)defn(<<<__WMV>>>)>>>)dnl
define(<<<ev_meta>>>, <<<define(<<<__MV>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))get_meta(defn(<<<__MV>>>))>>>)dnl
dnl ---- stepA: readline / time-ms / seq / conj ----
dnl ev_readline: read one line from fd 0. The REPL mainloop (driver.m4.in)
dnl also reads fd 0 line-by-line via its own `readline` macro, so this
dnl must consume exactly one line and return its raw content as the MAL
dnl value. A single esyscmd reads into `line` and prints it back with no
dnl trailing newline; the previous nested-esyscmd version expanded $line
dnl at define-time (empty), so echo lost the line and returned "".
define(<<<ev_readline>>>, <<<define(<<<__RLA>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))define(<<<__RLP>>>, inner_of(defn(<<<__RLA>>>)))define(<<<__RLL>>>, esyscmd(<<<printf "%s" ">>>defn(<<<__RLP>>>)<<<" >&2; if IFS= read -r line; then printf "%s" "$line"; else printf "__RL_EOF__"; fi>>>))ifelse(defn(<<<__RLL>>>), <<<__RL_EOF__>>>, nil, <<<">>>esc_str(defn(<<<__RLL>>>))<<<">>>)>>>)dnl
define(<<<ev_timems>>>, <<<esyscmd(<<<perl -MTime::HiRes=time -e 'print int(time()*1000)'>>>)>>>)dnl
define(<<<ev_seq>>>, <<<define(<<<__SEQ>>>, ev_form(skip_ws(<<<$1>>>), <<<$2>>>))seq_scan(strip_meta(defn(<<<__SEQ>>>)))>>>)dnl
define(<<<seq_scan>>>, <<<ifelse(<<<$1>>>, nil, nil, <<<ifelse(len(<<<$1>>>), 0, nil, <<<ifelse(first_char(<<<$1>>>), <<<">>>, <<<ifelse(len(inner_of(<<<$1>>>)), 0, nil, <<<seq_str(inner_of(<<<$1>>>))>>>)>>>, <<<ifelse(len(inner_of(<<<$1>>>)), 0, nil, <<<LP()inner_of(<<<$1>>>)RP()>>>)>>>)>>>)>>>)>>>)dnl
dnl seq_str: build a list of quoted single chars from a raw string body.
define(<<<seq_str>>>, <<<LP()seq_elems(<<<$1>>>)RP()>>>)dnl
define(<<<seq_elems>>>, <<<ifelse(len(<<<$1>>>), 0, __EE, <<<ifelse(len(<<<$1>>>), 1, <<<">>>first_char(<<<$1>>>)<<<">>>, <<<">>>first_char(<<<$1>>>)<<<">>>SP()seq_elems(rest_str(<<<$1>>>)))>>>)>>>)dnl
define(<<<ev_conj>>>, <<<split_first(skip_ws(<<<$1>>>))define(<<<__CJ_R>>>, skip_ws(defn(<<<__SF_REST>>>)))define(<<<__CJ>>>, ev_form(defn(<<<__SF_ELEM>>>), <<<$2>>>))conj_scan(defn(<<<__CJ_R>>>), strip_meta(defn(<<<__CJ>>>)), <<<$2>>>)>>>)dnl
dnl conj_scan: capture the remaining forms into __CJV_R BEFORE calling
dnl ev_form, because ev_form(collection/element) re-runs split_first
dnl internally and would clobber the shared __SF_REST global.
define(<<<conj_scan>>>, <<<ifelse(len(<<<$1>>>), 0, <<<$2>>>, <<<split_first(<<<$1>>>)define(<<<__CJV_R>>>, skip_ws(defn(<<<__SF_REST>>>)))define(<<<__CJV>>>, ev_form(defn(<<<__SF_ELEM>>>), <<<$3>>>))conj_add(<<<$2>>>, defn(<<<__CJV>>>), defn(<<<__CJV_R>>>), <<<$3>>>)>>>)>>>)dnl
define(<<<conj_add>>>, <<<ifelse(first_char(<<<$1>>>), <<<[>>>, <<<conj_vec(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>, <<<conj_list(<<<$1>>>, <<<$2>>>, <<<$3>>>, <<<$4>>>)>>>)>>>)dnl
define(<<<conj_list>>>, <<<conj_scan(<<<$3>>>, ifelse(len(inner_of(<<<$1>>>)), 0, LP()<<<$2>>>RP(), LP()<<<$2>>>SP()inner_of(<<<$1>>>)<<<>>>RP()), <<<$4>>>)>>>)dnl
define(<<<conj_vec>>>, <<<conj_scan(<<<$3>>>, ifelse(len(inner_of(<<<$1>>>)), 0, <<<[>>>$2<<<]>>>, <<<[>>>inner_of(<<<$1>>>)<<<>>>SP()<<<$2>>><<<]>>>), <<<$4>>>)>>>)dnl
