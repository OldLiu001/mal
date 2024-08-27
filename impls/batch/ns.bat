@rem Module Name: Namespace

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

:New _Type
	set "_Type=%~1"
	set /a G_NSP += 1
	set "G_NS[!G_NSP!]=_"
	set "G_NS[!G_NSP!].Type=!_Type!"

	set "G_RET=G_NS[!G_NSP!]"
goto :eof

:Free _NS
	set "_NS=%~1"
	if not defined !_NS! (
		>&2 echo [!G_TRACE!] ns !_NS! is not defined.
		pause & exit 1
	)
	if "!_NS:~,4!" Neq "G_NS" (
		>&2 echo [!G_TRACE!] !_NS! is not a namespace.
		pause & exit 1
	)

	for /f "delims==" %%i in (
		'set !_NS!'
	) do (
		set "%%i="
	)
goto :eof