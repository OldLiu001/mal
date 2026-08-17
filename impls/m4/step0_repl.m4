dnl mal (M4 Lisp) step0 - REPL
dnl
dnl The REPL loop itself lives in ../driver.m4.in (the driver), which defines
dnl readline/mainloop around this file's READ/EVAL/PRINT/REP macros.
dnl
dnl NOTE: this file is included AFTER the driver's changequote(<<<, >>>),
dnl so all quoting here uses <<< >>> as well.
dnl
dnl All value-passing between macro layers uses $@ (which preserves
dnl argument boundaries, so values containing commas survive).
dnl
define(<<<__READ>>>, <<<$@>>>)dnl
define(<<<__EVAL>>>, <<<$@>>>)dnl
define(<<<__PRINT>>>, <<<$@>>>)dnl
define(<<<REP>>>, <<<__PRINT(__EVAL(__READ($@)))<<<
>>>>>>)dnl
