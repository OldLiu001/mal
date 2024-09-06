@REM v0.6

@echo off
call %* || !_C_Fatal! "Call '%~nx0' failed."
exit /b 0

:New _Type -> _Namespace
	set /a _G_NSP = _G_NSP
	set /a _G_NSP += 1
	set "_G_NS[!_G_NSP!]=_"
	set "_G_NS[!_G_NSP!].=_"
	set "_G_NS[!_G_NSP!].Type=%~1"

	set "_G_RET=_G_NS[!_G_NSP!]"
exit /b 0

:Free _Namespace -> _
	if "!%~1!" == "" (
		>&2 echo [!G_TRACE!] Value of '%~1' is empty.
		pause & exit 1
	)
	if not defined !%~1! (
		>&2 echo [!G_TRACE!] '!%~1!' is undefined.
		pause & exit 1
	)
	if not defined !%~1!. (
		>&2 echo [!G_TRACE!] '!%~1!' is not a namespace.
		pause & exit 1
	)

	for /f "delims==" %%i in (
		'set !%~1!'
	) do (
		set "%%i="
	)
exit /b 0