dnl mal (M4 Lisp) step1 - read & print
dnl READ parses a mal form into its canonical print string; EVAL and PRINT
dnl are identity (step1 behavior). The driver (driver.m4.in) supplies the
dnl REPL loop and calls REP with each input line (passed via defn, so the
dnl raw line arrives as a quoted value and survives argument collection).
include(reader.m4)dnl
define(<<<READ>>>, <<<define(<<<__LAST_AST>>>, read_str(<<<$1>>>))>>>)dnl
define(<<<EVAL>>>, <<<$1>>>)dnl
define(<<<PRINT>>>, <<<DEC(defn(<<<__LAST_AST>>>))>>>)dnl
define(<<<REP>>>, <<<READ(<<<$1>>>)ifelse(__ERR, 1, <<<Error: >>>__ERRMSG, <<<PRINT()>>>)
>>>)dnl
