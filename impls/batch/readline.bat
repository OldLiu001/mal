@REM v: 1.4

@echo off
setlocal disabledelayedexpansion
for /f "delims=#" %%. in (
	'prompt #$E# ^& echo on ^& for %%_ in ^( . ^) do rem'
) do (
	set "_Esc=%%."
)

set _In= & set /p "_In="
for /f "delims=" %%. in ("%_Esc%") do (
	if defined _In (
		call set "_In=%%_In:"=%%.D%%"
		call set "_In=%%_In:!=%%.E%%"
		setlocal ENABLEDELAYEDEXPANSION
		(
			set "_In=!_In:^=%%.C!"
			set "_In2="
			:_Replace
			if defined _In (
				if "!_In:~,1!" == "%%" (
					set "_In2=!_In2!%_Esc%P"
				) else (
					set "_In2=!_In2!!_In:~,1!"
				)
				set "_In=!_In:~1!"
				goto _Replace
			)
			:_Replace2
			if defined _In2 (
				if "!_In2:~,1!" == "%_Esc%" (
					set "_In3=!_In3!$"
				) else if "!_In2:~,1!" == "$" (
					set "_In3=!_In3!$$"
				) else if "!_In2:~,1!" == ":" (
					set "_In3=!_In3!$A"
				) else (
					set "_In3=!_In3!!_In2:~,1!"
				)
				set "_In2=!_In2:~1!"
				goto _Replace2
			)
			echo.!_In3!
		)
		endlocal
	)
)
