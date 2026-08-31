@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init diag3
set "_ENV="
call TYPES :TYPES_NewMalMap
call :UTIL_GetRet _ENV
rem ---- replicate real step3 RegisterBuiltins buckets ----
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[+1].Count" 1
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[+1].Item[1].Key" +
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[+].Item[1].Value" "_Fn+"
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[d0e0f1$1E1].Count" 1
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[def$E].Item[1].Key" "def$E"
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[def$E].Item[1].Value" "_FnDef"
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[l0e0t1*1].Count" 1
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[l0e0t1*1].Item[1].Key" "let*"
call NSUTIL :NSUTIL_Set "!_ENV!" "Item[l0e0t1*1].Item[1].Value" "_FnLet"
rem ---- now ask HasField/Get for exactly what Eval would ask ----
rem Eval(+) -> Enc +1
call NSUTIL :NSUTIL_HasField "!_ENV!" "Item[+1].Count"
call :UTIL_GetRet _hf
echo PLUS_HasCount=[!_hf!]
call NSUTIL :NSUTIL_Get "!_ENV!" "Item[+1].Item[1].Value" _vplus
echo PLUS_Value=[!_vplus!]
rem Eval(let*) -> Enc l0e0t1*1
call NSUTIL :NSUTIL_HasField "!_ENV!" "Item[l0e0t1*1].Count"
call :UTIL_GetRet _hf
echo LET_HasCount=[!_hf!]
call NSUTIL :NSUTIL_Get "!_ENV!" "Item[l0e0t1*1].Item[1].Value" _vlet
echo LET_Value=[!_vlet!]
exit /b 0
:UTIL_GetRet
	if not defined _G.ERR ( set "%~1=!_G.RET!" )
	set "_G.RET="
exit /b 0