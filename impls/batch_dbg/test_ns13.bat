@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init test_ns13

call NSUTIL :NSUTIL_New _L[!_G.LEVEL!].NS
call NSUTIL :NSUTIL_Set _L[!_G.LEVEL!].NS Type Reader

echo NSMeta: !_L[0].NS!
echo Target: !_G.NS[2].Target!
echo Value: !_G.NS[1].Data.Value[Type]!

REM Now call NSUTIL_Get directly using call /b
REM First, let's try calling it with simple string args
call NSUTIL :NSUTIL_Get !_L[0].NS! Type _L[0].T2
echo T2=[!_L[0].T2!]
