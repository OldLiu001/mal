@echo off
setlocal enabledelayedexpansion
set "{s=call :NSUTIL_Set"
set "}=& (if defined _G.ERR (exit /b 0))"
for %%. in (_L[1].) do (
	set "%%.Env=ENVV"
	set "T2V=<"
	echo V3 pre
	%{s% "!%%.Env!" "Item[LT].Item[1].Key" !T2V! %}%
	echo V3-AFTER
	set "T2V=>"
	%{s% "!%%.Env!" "Item[GT].Item[1].Key" !T2V! %}%
	echo V4-AFTER
)
