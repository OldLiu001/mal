@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init test_ns8

call NSUTIL :NSUTIL_New _L[!_G.LEVEL!].NS
call NSUTIL :NSUTIL_Set _L[!_G.LEVEL!].NS Type Reader

echo NS_meta: !_G.NS[2]!
echo NS_body_target: !_G.NS[2].Target!
echo NS_body_val: !_G.NS[1].Data.Value[Type]!

REM Now manually simulate what NSUTIL_Get does, but inside its own for loop
for %%. in (_L[!_G.LEVEL!].) do (
	echo [inside for] %%.=%%.
	echo [inside for] %%.NS=%%.NS
	set "%%.NSBody=!_G.NS[2].Target!"
	echo [inside for] NSBody after set=!%%.NSBody!
	set "%%.ValName=!%%.NSBody!.Data.Value[Type]"
	echo [inside for] ValName=!%%.ValName!
	call set "%%.T=%%!%%.ValName!%%"
	echo [inside for] T=!%%.T!
)
