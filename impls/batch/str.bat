@echo off

::Start
	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
goto :eof

:New
	call NS.bat :New String
	set "!G_RET!.LineCount=0"
goto :eof

:FromVar _Var
	set "_Var=!%~1!"
	call NS.bat :New String
	set "!G_RET!.LineCount=1"
	set "!G_RET!.Lines[1]=!_Var!"
	call :ClearLocalVars
goto :eof

:FromVal _Val
	set "_Val=%~1"
	call NS.bat :New String
	set "!G_RET!.LineCount=1"
	set "!G_RET!.Lines[1]=!_Val!"
	call :ClearLocalVars
goto :eof

:AppendStr _Str _NewStr
	call :CopyVar !%~1!.LineCount _LineCount
	call :CopyVar !%~2!.LineCount _LineCount2
	if !_LineCount! geq 1 (
		call :CopyVar !%~1!.Lines[!_LineCount!] _Line
		call :CopyVar !%~2!.Lines[1] _Line2
		set "!%~1!.Lines[!_LineCount!]=!_Line!!_Line2!"
	)
	for /l %%i in (2 1 !_LineCount2!) do (
		set /a _LineCount += 1
		call :CopyVar !%~2!.Lines[%%i] !%~1!.Lines[!_LineCount!]
	)
	call :CopyVar _LineCount !%~1!.LineCount
	set "G_RET="
	call :ClearLocalVars
goto :eof

:AppendVal _Str _Val
	call :CopyVar !%~1!.LineCount _LineCount
	if "!_LineCount!" == "0" (
		set "!%~1!.LineCount=1"
		set _LineCount=1
	)
	call :CopyVar !%~1!.Lines[!_LineCount!] _LastLine
	set "_LastLine=!_LastLine!%~2"
	call :CopyVar _LastLine !%~1!.Lines[!_LineCount!]
	set "G_RET="
	call :ClearLocalVars
goto :eof

:AppendVar _Str _Var
	call :CopyVar !%~1!.LineCount _LineCount
	if "!_LineCount!" == "0" (
		set "!%~1!.LineCount=1"
		set _LineCount=1
	)
	call :CopyVar !%~1!.Lines[!_LineCount!] _LastLine
	set "_LastLine=!_LastLine!!%~2!"
	call :CopyVar _LastLine !%~1!.Lines[!_LineCount!]
	set "G_RET="
	call :ClearLocalVars
goto :eof

:CopyVar _VarFrom _VarTo
	set "%~2=!%~1!"
goto :eof

:ClearLocalVars
	for /f "delims==" %%a in ('set _ 2^>nul') do set "%%a="
goto :eof