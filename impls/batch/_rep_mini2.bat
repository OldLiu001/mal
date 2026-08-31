@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init stepX
echo [rm2] init rc=%errorlevel%
set _G.RCMODE=1
call NSUTIL :NSUTIL_New _T.E
echo [rm2] new E rc=%errorlevel% E=!_T.E!
set "_L[1].Env=!_T.E!"
rem Replicate set1: Item[+1].Count = 1
call NSUTIL :NSUTIL_Set "_L[1].Env" "Item[+1].Count" 1
echo [rm2] set1 rc=%errorlevel%
rem Replicate set2: Item[+1].Item[1].Key = +
call NSUTIL :NSUTIL_Set "_L[1].Env" "Item[+1].Item[1].Key" "+"
echo [rm2] set2 rc=%errorlevel%
echo [rm2] done
exit /b 0