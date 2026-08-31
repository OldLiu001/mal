@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init stepX
echo [rm4] init rc=%errorlevel%
set _G.RCMODE=1
call NSUTIL :NSUTIL_New _T.E
echo [rm4] new E rc=%errorlevel% E=!_T.E!
for %%. in (_L[1].) do (
	set "%%.Env=!_T.E!"
	call NSUTIL :NSUTIL_Set "!%%.Env!" "Item[*1].Count" 1
	echo [rm4] set1 rc=%errorlevel%
	call NSUTIL :NSUTIL_Set "!%%.Env!" "Item[*1].Item[1].Key" "*"
	echo [rm4] set2 rc=%errorlevel%
	call NSUTIL :NSUTIL_Set "!%%.Env!" "Item[*1].Item[1].Value" "_G.NS[2]"
	echo [rm4] set3 rc=%errorlevel%
)
echo [rm4] done
exit /b 0