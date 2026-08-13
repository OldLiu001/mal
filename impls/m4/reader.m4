dnl mal (M4 Lisp) reader - produces the canonical print string for step1.
dnl changequote(<<<, >>>) is already active (set by driver.m4.in before include).
dnl
dnl ENCODING SCHEME (critical): GNU m4 1.4.6 argument collection treats
dnl unquoted ( ) , in a macro's EXPANSION as syntax: ) closes the argument
dnl list, , splits it. So a helper macro that expands to text containing
dnl those chars (e.g. rest of "1 2 3)") corrupts the caller's argument
dnl collection. Workaround: at read_str entry, translit the input so that
dnl ( ) , become control chars \x01 \x02 \x03. All internal parsing works
dnl on encoded text; the final canonical string is decoded at PRINT time
dnl (the structural parens emitted by parse_list/quote_wrap etc. are
dnl literal text and are unaffected by decoding).
dnl
dnl Other rules:
dnl - LAZY BRANCHES: every ifelse branch containing a macro call MUST be
dnl   wrapped in <<< >>> quotes (m4 expands all ifelse arguments eagerly).
dnl - QUOTED PARAMS: every $1/$2 inside a macro body MUST be written as
dnl   <<<$1>>> / <<<$2>>> (values are rescanned after substitution; parens/
dnl   commas/leading whitespace would corrupt collection otherwise).
dnl - COMMA-FREE CALLS: builtin calls with commas in their argument text
dnl   (substr, translit) MUST be wrapped in helper macros so the commas
dnl   appear only inside a quoted macro definition, never inline.
dnl
define(<<<__ERR>>>, <<<0>>>)dnl
define(<<<SP>>>, format(%c,32))dnl
define(<<<BS>>>, format(%c,92))dnl
define(<<<NLCH>>>, format(%c,10))dnl
define(<<<TABCH>>>, format(%c,9))dnl
define(<<<CRCH>>>, format(%c,13))dnl
define(<<<E>>>, )dnl
dnl encoded delimiters
dnl NOTE: LP/CM were \x0b/\x0c (VT/FF) which GNU m4 treats as
 dnl whitespace during argument collection, silently splitting macro
 dnl args. Changed to \x0e/\x10 which are non-whitespace control
 dnl chars and never appear in MAL input. RP/HS moved to \x0f/\x11.
define(<<<LP>>>, format(%c,14))dnl      dnl encoded (  (\x0e, non-ws)
define(<<<RP>>>, format(%c,15))dnl      dnl encoded )  (\x0f, non-ws)
define(<<<CM>>>, format(%c,16))dnl      dnl encoded ,  (\x10, non-ws)
define(<<<HS>>>, format(%c,17))dnl      dnl encoded #  (\x11, non-ws)
define(<<<ENC>>>, <<<translit(<<<$1>>>, <<<(),#>>>, LP()RP()CM()HS())>>>)dnl
define(<<<DEC>>>, <<<translit(<<<$1>>>, LP()RP()CM()HS(), <<<(),#>>>)>>>)dnl
dnl ---- string helpers (wrap comma-containing builtin calls) ----
define(<<<first_char>>>, <<<substr(<<<$1>>>,0,1)>>>)dnl
define(<<<rest_str>>>, <<<substr(<<<$1>>>,1)>>>)dnl
define(<<<skip2>>>, <<<substr(<<<$1>>>,2)>>>)dnl
define(<<<second_char>>>, <<<substr(<<<$1>>>,1,1)>>>)dnl
dnl ---- whitespace / comment skipping (space and encoded comma) ----
define(<<<is_ws>>>, <<<ifelse(<<<$1>>>, <<< >>>, 1, <<<ifelse(<<<$1>>>, CM, 1, 0)>>>)>>>)dnl
define(<<<skip_ws>>>, <<<sw_loop(<<<$1>>>)>>>)dnl
define(<<<sw_loop>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<ifelse(is_ws(first_char(<<<$1>>>)), 1, <<<skip_ws(rest_str(<<<$1>>>))>>>, <<<ifelse(first_char(<<<$1>>>), <<<;>>>, E, <<<$1>>>)>>>)>>>)>>>)dnl
dnl ---- delimiter test (all branches lazily quoted; expansion is a bare 0/1) ----
define(<<<is_delim>>>, <<<ifelse(<<<$1>>>, <<< >>>, 1, <<<ifelse(<<<$1>>>, CM, 1, <<<ifelse(<<<$1>>>, LP, 1, <<<ifelse(<<<$1>>>, RP, 1, <<<ifelse(<<<$1>>>, <<<[>>>, 1, <<<ifelse(<<<$1>>>, <<<]>>>, 1, <<<ifelse(<<<$1>>>, <<<{>>>, 1, <<<ifelse(<<<$1>>>, <<<}>>>, 1, <<<ifelse(<<<$1>>>, <<<">>>, 1, <<<ifelse(<<<$1>>>, <<<'>>>, 1, <<<ifelse(<<<$1>>>, <<<`>>>, 1, <<<ifelse(<<<$1>>>, <<<~>>>, 1, <<<ifelse(<<<$1>>>, <<<@>>>, 1, <<<ifelse(<<<$1>>>, <<<^>>>, 1, <<<ifelse(<<<$1>>>, <<<;>>>, 1, 0)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
dnl ---- top level ----
define(<<<read_str>>>, <<<define(<<<__ERR>>>, 0)canon(ENC(<<<$1>>>))>>>)dnl
define(<<<canon>>>, <<<canon2(skip_ws(<<<$1>>>))>>>)dnl
define(<<<canon2>>>, <<<ifelse(len(<<<$1>>>), 0, E, <<<c_dispatch(first_char(<<<$1>>>), <<<$1>>>)>>>)>>>)dnl
dnl ---- dispatch on first character ----
define(<<<c_dispatch>>>, <<<ifelse(<<<$1>>>, LP, <<<parse_list(<<<$2>>>)>>>, <<<ifelse(<<<$1>>>, <<<[>>>, <<<parse_vector(<<<$2>>>)>>>, <<<ifelse(<<<$1>>>, <<<{>>>, <<<parse_map(<<<$2>>>)>>>, <<<ifelse(<<<$1>>>, <<<">>>, <<<parse_string(<<<$2>>>)>>>, <<<ifelse(<<<$1>>>, <<<'>>>, <<<quote_wrap(<<<$2>>>)>>>, <<<ifelse(<<<$1>>>, <<<`>>>, <<<qq_wrap(<<<$2>>>)>>>, <<<ifelse(<<<$1>>>, <<<~>>>, <<<tilde_wrap(<<<$2>>>)>>>, <<<ifelse(<<<$1>>>, <<<@>>>, <<<deref_wrap(<<<$2>>>)>>>, <<<ifelse(<<<$1>>>, <<<^>>>, <<<meta_wrap(<<<$2>>>)>>>, <<<classify_atom(<<<$2>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
dnl ---- quote family ----
define(<<<quote_wrap>>>, <<<(quote<<< >>>canon(rest_str(<<<$1>>>)))>>>)dnl
define(<<<qq_wrap>>>, <<<(quasiquote<<< >>>canon(rest_str(<<<$1>>>)))>>>)dnl
define(<<<deref_wrap>>>, <<<(deref<<< >>>canon(rest_str(<<<$1>>>)))>>>)dnl
define(<<<tilde_wrap>>>, <<<ifelse(second_char(<<<$1>>>), <<<@>>>, <<<(splice-unquote<<< >>>canon(skip2(<<<$1>>>)))>>>, <<<(unquote<<< >>>canon(rest_str(<<<$1>>>)))>>>)>>>)dnl
define(<<<meta_wrap>>>, <<<define(<<<__M_A>>>, canon(rest_str(<<<$1>>>)))define(<<<__M_B>>>, canon(defn(<<<__REST>>>)))(with-meta<<< >>>__M_B<<< >>>__M_A)>>>)dnl
dnl ---- atoms (number / symbol / nil / true / false / keyword) ----
define(<<<classify_atom>>>, <<<pa_scan(E, <<<$1>>>)>>>)dnl
define(<<<pa_scan>>>, <<<ifelse(len(<<<$2>>>), 0, <<<pa_done(<<<$1>>>, E)>>>, <<<ifelse(is_delim(first_char(<<<$2>>>)), 1, <<<pa_done(<<<$1>>>, <<<$2>>>)>>>, <<<pa_scan(<<<$1>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>)>>>)>>>)dnl
define(<<<pa_done>>>, <<<define(<<<__REST>>>, <<<$2>>>)<<<$1>>>>>>)dnl
dnl ---- lists ----
define(<<<parse_list>>>, <<<(>>><<<parse_list_body(skip_ws(rest_str(<<<$1>>>)))>>><<<)>>>)dnl
define(<<<parse_list_body>>>, <<<ifelse(len(<<<$1>>>), 0, <<<errset>>>, <<<parse_list_body2(skip_ws(<<<$1>>>))>>>)>>>)dnl
define(<<<parse_list_body2>>>, <<<ifelse(len(<<<$1>>>), 0, <<<errset>>>, <<<ifelse(first_char(<<<$1>>>), RP, <<<define(<<<__REST>>>, rest_str(<<<$1>>>))>>>, <<<pl_join(canon(<<<$1>>>), parse_list_body2(defn(<<<__REST>>>)))>>>)>>>)>>>)dnl
define(<<<pl_join>>>, <<<ifelse(len(<<<$2>>>), 0, <<<$1>>>, <<<$1>>>SP<<<$2>>>)>>>)dnl
dnl ---- vectors ----
define(<<<parse_vector>>>, <<<[>>><<<parse_vec_body(skip_ws(rest_str(<<<$1>>>)))>>><<<]>>>)dnl
define(<<<parse_vec_body>>>, <<<ifelse(len(<<<$1>>>), 0, <<<errset>>>, <<<parse_vec_body2(skip_ws(<<<$1>>>))>>>)>>>)dnl
define(<<<parse_vec_body2>>>, <<<ifelse(len(<<<$1>>>), 0, <<<errset>>>, <<<ifelse(first_char(<<<$1>>>), <<<]>>>, <<<define(<<<__REST>>>, rest_str(<<<$1>>>))>>>, <<<pv_join(canon(<<<$1>>>), parse_vec_body2(defn(<<<__REST>>>)))>>>)>>>)>>>)dnl
define(<<<pv_join>>>, <<<ifelse(len(<<<$2>>>), 0, <<<$1>>>, <<<$1>>>SP<<<$2>>>)>>>)dnl
dnl ---- hash maps ----
define(<<<parse_map>>>, <<<{>>><<<parse_map_body(skip_ws(rest_str(<<<$1>>>)))>>><<<}>>>)dnl
define(<<<parse_map_body>>>, <<<ifelse(len(<<<$1>>>), 0, <<<errset>>>, <<<parse_map_body2(skip_ws(<<<$1>>>))>>>)>>>)dnl
define(<<<parse_map_body2>>>, <<<ifelse(len(<<<$1>>>), 0, <<<errset>>>, <<<ifelse(first_char(<<<$1>>>), <<<}>>>, <<<define(<<<__REST>>>, rest_str(<<<$1>>>))>>>, <<<pm_join(canon(<<<$1>>>), parse_map_body2(defn(<<<__REST>>>)))>>>)>>>)>>>)dnl
define(<<<pm_join>>>, <<<ifelse(len(<<<$2>>>), 0, <<<$1>>>, <<<$1>>>SP<<<$2>>>)>>>)dnl
dnl ---- strings (verbatim copy of raw content between the quotes) ----
define(<<<parse_string>>>, <<<ps_scan(E, rest_str(<<<$1>>>))>>>)dnl
define(<<<ps_scan>>>, <<<ifelse(len(<<<$2>>>), 0, <<<ps_done(<<<$1>>>, E)>>>, <<<ifelse(first_char(<<<$2>>>), <<<">>>, <<<ps_done(<<<$1>>>, rest_str(<<<$2>>>))>>>, <<<ifelse(first_char(<<<$2>>>), BS, <<<ps_scan(<<<$1>>>defn(<<<BS>>>)second_char(<<<$2>>>), skip2(<<<$2>>>))>>>, <<<ifelse(first_char(<<<$2>>>), NLCH(), <<<ps_scan(<<<$1>>>BS()<<<n>>>, rest_str(<<<$2>>>))>>>, <<<ifelse(first_char(<<<$2>>>), TABCH(), <<<ps_scan(<<<$1>>>BS()<<<t>>>, rest_str(<<<$2>>>))>>>, <<<ifelse(first_char(<<<$2>>>), CRCH(), <<<ps_scan(<<<$1>>>BS()<<<r>>>, rest_str(<<<$2>>>))>>>, <<<ps_scan(<<<$1>>>first_char(<<<$2>>>), rest_str(<<<$2>>>))>>>)>>>)>>>)>>>)>>>)>>>)>>>)dnl
define(<<<ps_done>>>, <<<define(<<<__REST>>>, <<<$2>>>)"<<<$1>>>">>>)dnl
dnl ---- error helpers ----
define(<<<errset>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, unbalanced parentheses)define(<<<__REST>>>, )>>>)dnl
define(<<<err_string>>>, <<<define(<<<__ERR>>>, 1)define(<<<__ERRMSG>>>, EOF in string)define(<<<__REST>>>, )>>>)dnl
