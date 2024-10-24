@echo off
if "%~1" neq "" (
	call %* || !_C_Fatal! "Call '%~nx0' failed."
	exit /b 0
)
exit /b 0

:ENV_New _Outer -> _Env
	for %%. in (_L{!_G_LEVEL!}_) do (
		if "%~1" neq "_" (
			set "%%.Outer=!%~1!"
		) else (
			set "%%.Outer=_"
		)
		!_C_Invoke! NS New Enviroment & !_C_GetRet! %%.Env
		!_C_Copy! %%.Outer !%%.Env!.Outer
		!_C_Return! %%.Env
	)
exit /b 0

:Env_Set _Env _Key _Val -> _
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Env=!%~1!"
		set "%%.Key=!%~2!"
		set "%%.Val=!%~3!"
		if not defined !%%.Env!.Item[!%%.Key!] (
			set "!%%.Env!.Item[!%%.Key!]=_"
			set "!%%.Env!.Item[!%%.Key!].Count=1"
			set "!%%.Env!.Item[!%%.Key!].Sub[1].Key=!%%.Key!"
			set "!%%.Env!.Item[!%%.Key!].Sub[1].Value=!%%.Val!"
		) else (
			rem find key in current env (exclude outer env)
			!_C_Copy! !%%.Env!.Item[!%%.Key!].Count %%.Count
			set /a %%.Index = %%.Count + 1
			for /l %%i in (1 1 !%%.Count!) do (
				!_C_Copy! !%%.Env!.Item[!%%.Key!].Sub[%%i].Key %%.CurKey
				if "!%%.Key!" == "!%%.CurKey!" (
					set /a %%.Index = %%i
					!_C_Invoke! Types FreeMalType !%%.Env!.Item[!%%.Key!].Sub[!%%.Index!].Value
				)
			)

			!_C_Copy! %%.Key !%%.Env!.Item[!%%.Key!].Sub[!%%.Index!].Key
			!_C_Copy! %%.Val !%%.Env!.Item[!%%.Key!].Sub[!%%.Index!].Value
		)
		!_C_Return! _
	)
exit /b 0

:Env_Find _Env _Key -> _Env?
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Env=!%~1!"
		set "%%.Key=!%~2!"
		set "%%.Ret=_"
		if "!%%.Env!" == "_" (
			!_C_Return! %%.Ret
			exit /b 0
		)
		if not defined !%%.Env!.Item[!%%.Key!] (
			!_C_Copy! !%%.Env!.Outer %%.Outer
			!_C_Invoke! Env Find %%.Outer %%.Key
			!_C_GetRet! %%.Ret
			!_C_Return! %%.Ret
			exit /b 0
		)
		!_C_Copy! !%%.Env!.Item[!%%.Key!].Count %%.Count
		set "%%.Found=False"
		for /l %%i in (1 1 !%%.Count!) do (
			if "!%%.Found!" == "False" (
				!_C_Copy! !%%.Env!.Item[!%%.Key!].Sub[%%i].Key %%.CurKey
				if "!%%.Key!" == "!%%.CurKey!" (
					set "%%.Found=True"
				)
			)
		)
		if "!%%.Found!" == "False" (
			!_C_Copy! !%%.Env!.Outer %%.Outer
			!_C_Invoke! Env Find %%.Outer %%.Key
			!_C_GetRet! %%.Ret
			!_C_Return! %%.Ret
			exit /b 0
		)
		!_C_Return! %%.Env
	)
exit /b 0

:Env_Get _Env _Key -> _Val
	for %%. in (_L{!_G_LEVEL!}_) do (
		set "%%.Env=!%~1!"
		set "%%.Key=!%~2!"
		set "%%.Ret=_"
		
		!_C_Invoke! Env Find %%.Env %%.Key
		!_C_GetRet! %%.Env
		
		if "!%%.Env!" == "_" (
			!_C_Throw! Exception _ "Symbol '!%%.Key!' not found."
			exit /b 0
		)
		
		!_C_Copy! !%%.Env!.Item[!%%.Key!].Count %%.Count
		for /l %%i in (1 1 !%%.Count!) do (
			!_C_Copy! !%%.Env!.Item[!%%.Key!].Sub[%%i].Key %%.CurKey
			if "!%%.Key!" == "!%%.CurKey!" (
				!_C_Copy! !%%.Env!.Item[!%%.Key!].Sub[%%i].Value %%.Ret
			)
		)
		!_C_Return! %%.Ret
	)
exit /b 0
