@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init stepX
echo [diag] init done rc=%errorlevel%
set _G.RCMODE=1
call NSUTIL :NSUTIL_New _T.X
echo [diag] new done rc=%errorlevel% X=!_T.X!
call NSUTIL :NSUTIL_Set _T.X foo 42
echo [diag] set done rc=%errorlevel%
call NSUTIL :NSUTIL_Get _T.X foo _T.V
echo [diag] get done V=!_T.V!
call NSUTIL :NSUTIL_Free _T.X
echo [diag] free done rc=%errorlevel%
exit /b 0
