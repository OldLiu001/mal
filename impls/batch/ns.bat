@REM v0.4, untested

@rem Module Name: Namespace

@rem Export Functions:
@rem 	:New _TypeName
@rem 	:Free _Namespace

@echo off
rem If _G_NSP is not defined, then set it to 0.
set /a _G_NSP = _G_NSP
2>nul call %* || (
	2>&1 echo [!_G_TRACE!] Call '%~nx0' failed.
	pause & exit 1
)
exit /b 0

:New _Type
	set /a _G_NSP += 1
	set "_G_NS[!_G_NSP!]=_"
	set "_G_NS[!_G_NSP!].=_"
	set "_G_NS[!_G_NSP!].Type=%~1"

	set "G_RET=_G_NS[!_G_NSP!]"
exit /b 0

:Free _NS
	set "_NS=%~1"
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