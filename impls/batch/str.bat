@echo off
if "%~1" neq "" (
	call %* || %?|% "Call '%~nx0' failed."
)
%-|%

:STR_New -> Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		%|% NS New String %->% %%.Str
		set "!%%.Str!.LineCount=0"
		%<-% %%.Str
	)
%-|%

:STR_FromVar _Var -> Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		%|% NS New String %->% %%.Str
		set "!%%.Str!.LineCount=1"
		set "!%%.Str!.Line[1]=!%~1!"
		%<-% %%.Str
	)
%-|%

:STR_FromVal _Val -> Str
	for %%. in (_L{!_G_LEVEL!}_) do (
		%|% NS New String %->% %%.Str
		set "!%%.Str!.LineCount=1"
		set "!%%.Str!.Line[1]=%~1"
		%<-% %%.Str
	)
%-|%

:STR_AppendStr &Str &NewStr
	for %%. in (_L{!_G_LEVEL!}_) do (
		%&% !%~1!.LineCount %%.LineCount
		%&% !%~2!.LineCount %%.LineCount2
		if !%%.LineCount! geq 1 (
			if !%%.LineCount2! geq 1 (
				%&% !%~1!.Line[!%%.LineCount!] %%.Line
				%&% !%~2!.Line[1] %%.Line2
				set "!%~1!.Line[!%%.LineCount!]=!%%.Line!!%%.Line2!"
			)
		)
		for /l %%i in (2 1 !%%.LineCount2!) do (
			set /a %%.LineCount += 1
			%&% !%~2!.Line[%%i] !%~1!.Line[!%%.LineCount!]
		)
		%&% %%.LineCount !%~1!.LineCount
		%<-% _
	)
%-|%

:STR_AppendVal &Str _Val
	for %%. in (_L{!_G_LEVEL!}_) do (
		%&% !%~1!.LineCount %%.LineCount
		if "!%%.LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set %%.LineCount=1
		)
		if defined !%~1!.Line[!%%.LineCount!] (
			%&% !%~1!.Line[!%%.LineCount!] %%.LastLine
			set "%%.LastLine=!%%.LastLine!%~2"
			%&% %%.LastLine !%~1!.Line[!%%.LineCount!]
		) else (
			set "%%.LastLine=%~2"
			%&% %%.LastLine !%~1!.Line[!%%.LineCount!]
		)
		%<-% _
	)
%-|%

:STR_AppendVar &Str _Var
	for %%. in (_L{!_G_LEVEL!}_) do (
		%&% !%~1!.LineCount %%.LineCount
		if "!%%.LineCount!" == "0" (
			set "!%~1!.LineCount=1"
			set %%.LineCount=1
		)
		if defined !%~1!.Line[!%%.LineCount!] (
			%&% !%~1!.Line[!%%.LineCount!] %%.LastLine
			set "%%.LastLine=!%%.LastLine!!%~2!"
			%&% %%.LastLine !%~1!.Line[!%%.LineCount!]
		) else (
			set "%%.LastLine=!%~2!"
			%&% %%.LastLine !%~1!.Line[!%%.LineCount!]
		)
		%<-% _
	)
%-|%