@rem Export Functions:
@rem 	:New _TypeName
@rem 	:Free _Namespace

@echo off

::Start
	rem If G_NSP is not defined, then set it to 0.
	set /a G_NSP = G_NSP

	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
goto :eof

:New
	set /a G_NSP += 1
	set "G_NS[!G_NSP!]=_"

	call Function.bat :RetVal G_NS[!G_NSP!]
goto :eof

:Free _VarName
	set "_VarName=%~1"
	if not defined !_VarName! (
		echo [!G_CallPath!] !_VarName! is not defined.
		pause & exit 1
	)
	if "!_VarName:~,11!" Neq "G_NS" (
		echo [!G_CallPath!] !_VarName! is not a namespace.
		pause & exit 1
	)

	for /f "delims==" %%i in (
		'set !_VarName!'
	) do (
		@REM echo clear '%%i'
		set "%%i="
	)
goto :eof