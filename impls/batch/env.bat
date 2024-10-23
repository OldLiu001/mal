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
	)
exit /b 0

:Env_Find _Env _Key -> _Env
	for %%. in (_L{!_G_LEVEL!}_) do (
	)
exit /b 0

:Env_Get _Env _Key -> _Val
	for %%. in (_L{!_G_LEVEL!}_) do (
	)
exit /b 0
