@REM v1.4

@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:NS_New _Type -> _Namespace
	for %%. in (_L{!_G_LEVEL!}_) do (
		set /a _G_NSP = _G_NSP
		set /a _G_NSP += 1
		set "_G_NS[!_G_NSP!]=_"
		set "_G_NS[!_G_NSP!].=_"
		set "_G_NS[!_G_NSP!].Type=%~1"

		set "%%.RetV=_G_NS[!_G_NSP!]"
		!_C_Return! %%.RetV
	)
exit /b 0

:NS_Free _Namespace -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "!%~1!" == "" (
			!_C_Fatal! "Arg _Namespace is empty."
		)
		if not defined !%~1! (
			!_C_Fatal! "'!%~1!' undefined."
		)
		if not defined !%~1!. (
			!_C_Fatal! "'!%~1!' is not a namespace."
		)

		for /f "delims==" %%i in (
			'set !%~1!'
		) do (
			set "%%i="
		)

		!_C_Return! _
	)
exit /b 0