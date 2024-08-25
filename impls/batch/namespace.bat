@rem Module Name: Namespace

@rem Export Functions:
@rem 	:New
@rem 	:Free _Namespace

@rem Requirement: enable delayed expansion.

@rem Used Namespaces:
@rem 	G_NamespacePtr
@rem 	G_Namespace[!G_NamespacePtr!]
@rem 	G_CallPath

@echo off

::Start
	rem If G_NamespacePtr is not defined, then set it to 0.
	set /a G_NamespacePtr = G_NamespacePtr

	set "_Arguments=%*"
	if "!_Arguments:~,1!" Equ ":" (
		Set "_Arguments=!_Arguments:~1!"
	)
	call :!_Arguments!
	set _Arguments=
goto :eof

% Module - Namespace - Start % (
	:New
		set /a G_NamespacePtr += 1
		set "G_Namespace[!G_NamespacePtr!]=_"

		set "_ReturnValue=G_Namespace[!G_NamespacePtr!]"
		call Stackframe.bat :SaveVars _ReturnValue
	goto :eof

	:Free _VarName
		set "_VarName=%~1"
		if not defined !_VarName! (
			echo [!G_CallPath!] Namespace[%~1] is not defined.
			exit 1
		)
		for /f "delims==" %%i in (
			'set !_VarName!'
		) do (
			@REM echo clear '%%i'
			set "%%i="
		)
	goto :eof
) % Module - Namespace - End %