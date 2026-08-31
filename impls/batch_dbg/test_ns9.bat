@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init test_ns9

call NSUTIL :NSUTIL_New _L[!_G.LEVEL!].NS
call NSUTIL :NSUTIL_Set _L[!_G.LEVEL!].NS Type Reader

echo NS_body_val: !_G.NS[1].Data.Value[Type]!

REM Test using the NSUTIL_Get directly (not via %{g%} macro)
call NSUTIL :NSUTIL_Get "!_L[0].NS!" Type "_L[0].T2"
echo T2_direct: [!_L[0].T2!]
