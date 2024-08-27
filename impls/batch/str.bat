@echo off

::Start
	set "_Args=%*"
	if "!_Args:~,1!" Equ ":" (
		Set "_Args=!_Args:~1!"
	)
	call :!_Args!
	set _Args=
goto :eof

:New _FirstLine
	set "_FirstLine=!%~1!"
	call NS.bat :New String
	set "!G_RET!.LineCount=1"
	set "!G_RET!.Lines[1]=!_FirstLine!"
goto :eof

