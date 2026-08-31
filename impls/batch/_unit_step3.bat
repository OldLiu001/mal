@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init step3_env
set "_G.ENV="
call TYPES :TYPES_NewMalMap
call :UTIL_GetRet _G.ENV
echo ENV=[!_G.ENV!]
%{% MAIN RegisterBuiltins _G.ENV %}%
echo REG ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form="
set "Form=(+ 1 2)"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R1_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form=(def! x 3)"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R2_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form=x"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R3_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form=(def! mynum 111)"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R4_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form=mynum"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R5_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form=(let* (z 9) z)"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R6_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form=(let* (z (+ 2 3)) (+ 1 z))"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R7_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form=(def! MYNUM 222)"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R8_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
set "_G.ERR="
set "Form=MYNUM"
call util :UTIL_Invoke MAIN REP "!Form!"
echo R9_ERR=[!_G.ERR.Type!] MSG=[!_G.ERR.Msg!]
exit /b 0
:UTIL_GetRet
	if not defined _G.ERR ( set "%~1=!_G.RET!" )
	set "_G.RET="
exit /b 0