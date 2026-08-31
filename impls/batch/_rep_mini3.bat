@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init stepX
echo [rm3] init rc=%errorlevel%
set _G.RCMODE=1
call NSUTIL :NSUTIL_New _T.E
echo [rm3] new E rc=%errorlevel% E=!_T.E!
set "_L[1].Env=!_T.E!"
rem Replicate MSub: Item[-1].Count = 1, Item[-1].Item[1].Key = -
call NSUTIL :NSUTIL_Set "_L[1].Env" "Item[-1].Count" 1
echo [rm3] set1 rc=%errorlevel%
call NSUTIL :NSUTIL_Set "_L[1].Env" "Item[-1].Item[1].Key" "-"
echo [rm3] set2 rc=%errorlevel%
echo [rm3] done
exit /b 0