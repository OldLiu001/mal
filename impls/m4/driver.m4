changequote(<<<, >>>)dnl
define(<<<repline>>>, <<<esyscmd(<<<if IFS= read -r line; then printf "<<<%s>>>" "$line"; else printf "__M4EOF__"; fi>>>)>>>)dnl
define(<<<NL>>>, <<<esyscmd(<<<printf "\n">>>)>>>)dnl
define(<<<PR>>>, <<<esyscmd(<<<printf "user> ">>>)>>>)dnl
include(__STEP__)dnl
PR()dnl
define(<<<mainloop>>>, <<<define(<<<_l>>>, repline)ifelse(defn(<<<_l>>>), __M4EOF__, <<<>>>, <<<indir(<<<REP>>>, defn(<<<_l>>>))<<<>>>NL()PR<<<>>>mainloop>>>)>>>)dnl
mainloop
