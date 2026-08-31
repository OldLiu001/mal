@echo off
setlocal ENABLEDELAYEDEXPANSION
set "?|=echo WORKS"
set "_G.SKIPTHIS=rem"
%_G.SKIPTHIS% if "" == "" %?|% "'Val' undefined."
echo DONE
