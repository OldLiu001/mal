@echo off
setlocal enabledelayedexpansion
set "{s=call :NSUTIL_Set"
set "}=& (if defined _G.ERR (exit /b 0))"
for %%. in (_L[1].) do (
	set "%%.Env=ENVV"
	%{s% "!%%.Env!" "Item[LT].Item[1].Key" "<" %}%
	echo V1-AFTER
)
for %%. in (_L[1].) do (
	set "%%.Env=ENVV"
	%{s% "!%%.Env!" "Item[GT].Item[1].Key" ">" %}%
	echo V2-AFTER
)
