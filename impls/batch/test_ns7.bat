@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)

call NSUTIL :NSUTIL_New _L[!_G.LEVEL!].NS
call NSUTIL :NSUTIL_Set _L[!_G.LEVEL!].NS Type Reader

echo === Direct access ===
echo NS1: !_G.NS[1]!
echo Target: !_G.NS[2].Target!
echo NSBody: !_G.NS[2].Target!
echo Value: !_G.NS[1].Data.Value[Type]!

echo === Now test Get ===
set "_L[1].NSBody=!_G.NS[2].Target!"
echo NSBody var: [!_L[1].NSBody!]
set "_L[1].ValName=!_L[1].NSBody!.Data.Value[Type]"
echo ValName: [!_L[1].ValName!]
call set "_L[1].T=%%!_L[1].ValName!%%"
echo T: [!_L[1].T!]
