@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init test_ns12

call NSUTIL :NSUTIL_New _L[!_G.LEVEL!].NS
call NSUTIL :NSUTIL_Set _L[!_G.LEVEL!].NS Type Reader

echo === Now calling Get manually ===
call :NSUTIL_Get "!_L[0].NS!" Type "_L[0].T2"
echo After Get: T2=[!_L[0].T2!]

echo === Now calling via NSUTIL ===
call NSUTIL :NSUTIL_Get "!_L[0].NS!" Type "_L[0].T3"
echo After Get3: T3=[!_L[0].T3!]
