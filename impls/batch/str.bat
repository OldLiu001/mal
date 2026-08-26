@echo off
if "%~1" neq "" (
	call %* || (
		if defined _G.TRACE (
			>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			>&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		2>con >&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		>&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		>&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	2>con >&2 pause
	exit 1
)
exit /b 0

:STR_New -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Str %}
		%{s% %%.Str Type String %}
		set "%%.LineCount=0"
		%{s% %%.Str LineCount 0 %}
		%<-% %%.Str
	)
%-|%

:STR_FromVar _Var -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Str %}
		%{s% %%.Str Type String %}
		%{s% %%.Str LineCount 1 %}
		%{s% %%.Str Line[1] "!%~1!" %}
		%<-% %%.Str
	)
%-|%

:STR_FromVal _Val -> Str
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Str %}
		%{s% %%.Str Type String %}
		%{s% %%.Str LineCount 1 %}
		%{s% %%.Str Line[1] "%~1" %}
		%<-% %%.Str
	)
%-|%

:STR_AppendStr &Str &NewStr
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		%{g% "%~2" LineCount %%.LineCount2 %}
		if !%%.LineCount! geq 1 (
			if !%%.LineCount2! geq 1 (
				%{g% "%~1" Line[!%%.LineCount!] %%.Line %}
				%{g% "%~2" Line[1] %%.Line2 %}
				set "%%.NewLine=!%%.Line!!%%.Line2!"
				%{s% "%~1" Line[!%%.LineCount!] "!%%.NewLine!" %}
			)
		) else if !%%.LineCount2! geq 1 (
			%{g% "%~2" Line[1] %%.Line2 %}
			%{s% "%~1" Line[1] "!%%.Line2!" %}
			set "%%.LineCount=1"
		)
		for /l %%i in (2 1 !%%.LineCount2!) do (
			set /a %%.LineCount += 1
			%{g% "%~2" Line[%%i] %%.Line3 %}
			%{s% "%~1" Line[!%%.LineCount!] "!%%.Line3!" %}
		)
		%{s% "%~1" LineCount !%%.LineCount! %}
		%<-% _
	)
%-|%

:STR_AppendVal &Str _Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		if "!%%.LineCount!" == "0" (
			set "%%.LineCount=1"
			%{s% "%~1" LineCount 1 %}
		)
		%{g% "%~1" Line[!%%.LineCount!] %%.LastLine %}
		if defined %%.LastLine (
			set "%%.NewLine=!%%.LastLine!%~2"
			%{s% "%~1" Line[!%%.LineCount!] "!%%.NewLine!" %}
		) else (
			%{s% "%~1" Line[!%%.LineCount!] "%~2" %}
		)
		%<-% _
	)
%-|%

:STR_AppendVar &Str _Var
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		if "!%%.LineCount!" == "0" (
			set "%%.LineCount=1"
			%{s% "%~1" LineCount 1 %}
		)
		%{g% "%~1" Line[!%%.LineCount!] %%.LastLine %}
		if defined %%.LastLine (
			set "%%.NewLine=!%%.LastLine!!%~2!"
			%{s% "%~1" Line[!%%.LineCount!] "!%%.NewLine!" %}
		) else (
			%{s% "%~1" Line[!%%.LineCount!] "!%~2!" %}
		)
		%<-% _
	)
%-|%

:STR_GetStr &Str -> Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		set "%%.Result="
		for /l %%i in (1 1 !%%.LineCount!) do (
			%{g% "%~1" Line[%%i] %%.Line %}
			set "%%.Result=!%%.Result!!%%.Line!"
		)
		%<-% %%.Result
	)
%-|%

:STR_GetVar &Str *Var
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" LineCount %%.LineCount %}
		set "%%.Result="
		for /l %%i in (1 1 !%%.LineCount!) do (
			%{g% "%~1" Line[%%i] %%.Line %}
			set "%%.Result=!%%.Result!!%%.Line!"
		)
		%&% %%.Result "%~2"
	)
%-|%
:UTIL_SetRet

	if defined _G.NSUTIL (

		call set "_T.SR.Type=%%!%~1!.Type%%"

		if /i "!_T.SR.Type!" == "NSMeta" (

			if defined _G.LEVEL[!_G.LEVEL!][!%~1!] (

				set "_G.LEVEL[!_G.LEVEL!][!%~1!]="

				set /a "_T.SR.PrevLevel = _G.LEVEL - 1"

				set "_G.RET=!%~1!"

				set "_G.LEVEL[!_T.SR.PrevLevel!][!_G.RET!]=!_G.RET!"

			) else (

				set "_G.RET=!%~1!"

			)

		) else (

			set "_G.RET=!%~1!"

		)

	) else (

		set "_G.RET=!%~1!"

	)

exit /b 0



:UTIL_GetRet

	if not defined _G.ERR (

		set "%~1=!_G.RET!"

	)

	set "_G.RET="

exit /b 0

