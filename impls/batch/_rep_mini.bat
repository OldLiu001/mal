@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init stepX
echo [rep] init rc=%errorlevel%
set _G.RCMODE=1
call NSUTIL :NSUTIL_New _T.E
echo [rep] new E rc=%errorlevel% E=!_T.E!
set "_L[1].Env=!_T.E!"
set "_L[1].Enc=x"
call NSUTIL :NSUTIL_Set "_L[1].Env" "Item[!_L[1].Enc!].Count" 1
echo [rep] s1 rc=%errorlevel%
call NSUTIL :NSUTIL_Set "_L[1].Env" "Item[!_L[1].Enc!].Item[1].Key" +
echo [rep] s2 rc=%errorlevel%
call NSUTIL :NSUTIL_Set "_L[1].Env" "Item[!_L[1].Enc!].Item[1].Value" "!_T.E!"
echo [rep] s3 rc=%errorlevel%
call NSUTIL :NSUTIL_New _T.F
call NSUTIL :NSUTIL_Set "_L[1].Env" "Item[!_L[1].Enc!].Item[1].Value" "!_T.F!"
echo [rep] s4 (overwrite handle) rc=%errorlevel%
call NSUTIL :NSUTIL_Free _T.E
echo [rep] free E rc=%errorlevel%
call NSUTIL :NSUTIL_Free _T.F
echo [rep] free F rc=%errorlevel%
echo DONE_REP
exit /b 0