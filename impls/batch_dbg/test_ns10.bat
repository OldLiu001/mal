@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init test_ns10

call NSUTIL :NSUTIL_New _L[!_G.LEVEL!].NS
echo After New: NS=!_L[0].NS!
call NSUTIL :NSUTIL_Set _L[!_G.LEVEL!].NS Type Reader
echo After Set: Val=!_G.NS[1].Data.Value[Type]!

echo === Now calling Get ===
call NSUTIL :NSUTIL_Get "!_L[0].NS!" Type "_L[0].T2"
echo After Get: T2=[!_L[0].T2!]
echo ERR=[!_G.ERR!]
