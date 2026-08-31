@echo off
setlocal ENABLEDELAYEDEXPANSION
set "T=("
echo A
call set "V=%%!T!%%"
echo B V=!V!
set "T2=+"
call set "V2=%%!T2!%%"
echo C V2=!V2!
call set "T3=%%!T!.Type%%"
echo D T3=!T3!
echo E
exit /b 0