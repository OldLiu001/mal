@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init stepX
echo [diag2] init rc=%errorlevel%
set _G.RCMODE=1
call NSUTIL :NSUTIL_New _T.A
echo [diag2] new A rc=%errorlevel% A=!_T.A!
call NSUTIL :NSUTIL_New _T.B
echo [diag2] new B rc=%errorlevel% B=!_T.B!
call NSUTIL :NSUTIL_Set _T.A x _T.B
echo [diag2] set A.x=B rc=%errorlevel%
call NSUTIL :NSUTIL_Free _T.B
echo [diag2] free B rc=%errorlevel%
call NSUTIL :NSUTIL_Set _T.A y 7
echo [diag2] set A.y=7 rc=%errorlevel%
call NSUTIL :NSUTIL_Free _T.A
echo [diag2] free A rc=%errorlevel%
echo DONE
exit /b 0