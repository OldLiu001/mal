@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init test_ns15

echo Before New: LEVEL=!_G.LEVEL!
call NSUTIL :NSUTIL_New _L[!_G.LEVEL!].NS
echo After New: LEVEL=!_G.LEVEL!
echo _L[0].NS=[!_L[0].NS!]
echo _G.NS[1].Type=[!_G.NS[1].Type!]
echo _G.NS[2].Type=[!_G.NS[2].Type!]
echo _G.NS[2].Target=[!_G.NS[2].Target!]
