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

:ENV_New _Outer -> Env
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.Env %}
		%{s% %%.Env Type Environment %}
		if "%~1" neq "_" (
			%{s% %%.Env Outer "%~1" %}
		) else (
			%{s% %%.Env Outer _ %}
		)
		set "%%.ItemCnt=0"
		%{s% %%.Env ItemCount 0 %}
		%<-% %%.Env
	)
%-|%

:ENV_Set *Env _Key *Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{g% "%~1" ItemCount %%.Cnt %}
		set /a %%.Cnt += 1
		%{s% "%~1" Key[!%%.Cnt!] "%~2" %}
		%{s% "%~1" Val[!%%.Cnt!] "%~3" %}
		%{s% "%~1" ItemCount !%%.Cnt! %}
	)
%-|%

:ENV_Find *Env _Key -> Env?
	for %%. in (_L[!_G.LEVEL!].) do (
		set "%%.Env=%~1"
		set "%%.Ret=_"
		:ENV_Find_Loop
		if "!%%.Env!" == "_" (
			%<-% %%.Ret
			%-|%
		)
		%{g% "!%%.Env!" ItemCount %%.Cnt %}
		set "%%.Found=0"
		for /l %%i in (1 1 !%%.Cnt!) do (
			if "!%%.Found!" == "0" (
				%{g% "!%%.Env!" Key[%%i] %%.CurKey %}
				if "!%%.CurKey!" == "%~2" (
					set "%%.Found=1"
					set "%%.Ret=!%%.Env!"
				)
			)
		)
		if "!%%.Found!" == "0" (
			%{g% "!%%.Env!" Outer %%.Env %}
			goto ENV_Find_Loop
		)
		%<-% %%.Ret
	)
%-|%

:ENV_Get *Env _Key -> Val
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% ENV Find "%~1" "%~2" %}% %->% %%.FoundEnv 
		if "!%%.FoundEnv!" == "_" (
			%??% "Symbol '%~2' not found."
			%-|%
		)
		%{g% "!%%.FoundEnv!" ItemCount %%.Cnt %}
		set "%%.Ret=_"
		for /l %%i in (1 1 !%%.Cnt!) do (
			%{g% "!%%.FoundEnv!" Key[%%i] %%.CurKey %}
			if "!%%.CurKey!" == "%~2" (
				%{g% "!%%.FoundEnv!" Val[%%i] %%.Ret %}
			)
		)
		%<-% %%.Ret
	)
%-|%
