@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init stepX
echo [rc2] init rc=%errorlevel%
set _G.RCMODE=1
call NSUTIL :NSUTIL_New _T.A
echo [rc2] new A rc=%errorlevel% A=!_T.A!
call NSUTIL :NSUTIL_New _T.B
echo [rc2] new B rc=%errorlevel% B=!_T.B!

rem SetDirect scalar
call NSUTIL :NSUTIL_SetDirect _T.A a 1
echo [rc2] SetDirect A.a=1 rc=%errorlevel%
rem SetDirect handle
call NSUTIL :NSUTIL_SetDirect _T.A b _T.B
echo [rc2] SetDirect A.b=B rc=%errorlevel%
rem Get back
call NSUTIL :NSUTIL_Get _T.A b _T.GV
echo [rc2] Get A.b rc=%errorlevel% V=!_T.GV!

rem registry name form: simulate _G.LEVEL[1][t]=A
set "_G.LEVEL[1][t]=!_T.A!"
call NSUTIL :NSUTIL_Set "_G.LEVEL[1][t]" c 9
echo [rc2] Set reg.c=9 rc=%errorlevel%

rem COW path: Clone A -> C (refcnt 2), then Set A
call NSUTIL :NSUTIL_Clone _T.A _T.C
echo [rc2] Clone A->C rc=%errorlevel% C=!_T.C!
call NSUTIL :NSUTIL_Set _T.A d 5
echo [rc2] Set A.d=5 (COW) rc=%errorlevel%
call NSUTIL :NSUTIL_Get _T.A d _T.G2
echo [rc2] Get A.d rc=%errorlevel% V=!_T.G2!
call NSUTIL :NSUTIL_IsValidNS "!_T.G2!" %->% _T.OK
echo [rc2] IsValidNS(A.d) rc=%errorlevel% OK=!_T.OK!

rem Free all
call NSUTIL :NSUTIL_Free _T.B
echo [rc2] free B rc=%errorlevel%
call NSUTIL :NSUTIL_Free _T.C
echo [rc2] free C rc=%errorlevel%
call NSUTIL :NSUTIL_Free _T.A
echo [rc2] free A rc=%errorlevel%
echo DONE2
exit /b 0