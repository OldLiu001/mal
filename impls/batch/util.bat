@echo off
if "%~1" neq "" (
	call %* || (
		if defined _G.TRACE (
			2>con >&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" failed.
		) else (
			2>con >&2 echo [%~n0] Fatal: Call "%~nx0" failed.
		)
		2>con >&2 pause
		exit 1
	)
) else (
	if defined _G.TRACE (
		2>con >&2 echo [!_G.TRACE!] Fatal: Call "%~nx0" with nothing.
	) else (
		2>con >&2 echo [%~n0] Fatal: Call "%~nx0" with nothing.
	)
	2>con >&2 pause
	exit 1
)
exit /b 0

:UTIL_Init Main
	if "%~1" == "" (
		2>con >&2 echo [%~n0] Fatal: 'Main' undefined.
		2>con >&2 pause
		exit 1
	)
	
	if not defined _G.UTIL (
		set "_G.UTIL=%~n0"
		set "_G.MAIN=%~1"
		set "_G.TRACE=!_G.MAIN!"
		set /a "_G.LEVEL = _G.NSP = 0
		set "_G.RET="
		set "_G.ERR="
		
		set "_T.UTIL="
		if defined _G.PACKED set "_T.UTIL=!_G.UTIL!"
		
		set "<-=call !_T.UTIL! :UTIL_SetRet"
		set "->=& call !_T.UTIL! :UTIL_GetRet"
		set "|->=call !_T.UTIL! :UTIL_GetRet"
		set "??=call !_T.UTIL! :UTIL_Throw"		
		set "?|=call !_T.UTIL! :UTIL_Fatal"
		set "&=call !_T.UTIL! :UTIL_Copy"
		set "{=call !_T.UTIL! :UTIL_Invoke"
		set "}=& if defined _G.ERR exit /b 0"
		set "?}=& if defined _G.ERR"
		set "?=if defined _G.ERR"
		set "-|=exit /b 0"
		
		set "#n=call !_T.UTIL! :UTIL_New"
		set "#f=call !_T.UTIL! :UTIL_Free"
		set "#c=call !_T.UTIL! :UTIL_Clone"
		set "#s=call !_T.UTIL! :UTIL_Set"
		set "#g=call !_T.UTIL! :UTIL_Get"
	)
	
	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Invoke ModName Fn ... -> ...
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
	)
	
	if "%~1" == "" %?|% "'ModName' undefined."
	if "%~2" == "" %?|% "'Fn' undefined."
	
	set "_G.TRACES[!_G.LEVEL!]=!_G.TRACE!"
	set "_G.TRACE=!_G.TRACE!>(%~1)%~2"
	
	set "_G.RET="
	set /a "_G.LEVEL += 1"
	
	for /f "tokens=1,2,*" %%a in ('echo.%*') do (
		if defined _G.PACKED (
			if /i "%%a" == "MAIN" (
				call :MAIN_%%b %%c
			) else (
				call :%%a_%%b %%c
			)
		) else (
			if /i "%%a" == "MAIN" (
				call !_G.MAIN! CALL_SELF :MAIN_%%b %%c
			) else (
				call %%a :%%a_%%b %%c
			)
		)
	)
	
	for /f "delims==" %%a in (
		'set "_G.LEVEL[!_G.LEVEL!]" 2^>nul'
	) do (
		call :UTIL_Free %%a
	)
	
	for /f "delims==" %%a in (
		'set "_L.LEVEL[!_G.LEVEL!]" 2^>nul'
	) do set "%%a="
	
	set /a _G.LEVEL -= 1
	
	%&% _G.TRACES[!_G.LEVEL!] _G.TRACE
	set "_G.TRACES[!_G.LEVEL!]="
	
	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_GetRet *Var
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)

	if "%~1" == "" %?|% "'Var' undefined."	

	if not defined _G.ERR (
		%&% "_G.RET" "%~1"
	)
	set "_G.RET="

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_SetRet *Var
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)

	if "%~1" == "" %?|% "'Var' undefined."
	
	set "_G.RET="
	%&% "!%~1!." "_T.Var"
	if "!_T.Var!" == "NSMETA" (
		call :UTIL_Clone "%~1" "_G.RET"
		set /a "_T.PREVLEVEL = _G.LEVEL - 1"
		set "_G.LEVEL[!_T.PREVLEVEL!][!_G.RET!]=!_G.RET!"
	) else (
		set "_G.RET=!%~1!"
	)

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Throw *Var
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'Var' undefined."
	
	set "_G.ERR="
	%&% "!%~1!." "_T.Var"
	if "!_T.Var!" == "NSMETA" (
		call :UTIL_Clone "%~1" "_G.ERR"
	) else (
		set "_G.ERR=!%~1!"
	)

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Fatal Msg
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'Msg' undefined."
	
	2>con >&2 echo [!_G.TRACE!] Fatal: %~1
	2>con >&2 pause
	exit 1
%-|%

:UTIL_Copy *From *To
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'From' undefined."
	if "%~2" == "" %?|% "'To' undefined."
	
	set "%~2=!%~1!"

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Clone *From *To
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'From' undefined."
	if "%~2" == "" %?|% "'To' undefined."


	%&% "!%~1!." _T.Var
	if not "!_T.Var!" == "NSMETA" (
		%?|% "Invalid NSMETA."
	) else (
		%&% "!%~1.Target!." "_T.NSData"
		if not "!_T.NSData!" == "NSBODY" (
			%?|% "Invalid NSBODY."
		)

		set /a "_G.NSP += 1"
		set "_G.NS[!_G.NSP!].=NS"
		set "_G.NS[!_G.NSP!].Target=!%~1.Target!"
		set /a "!%~1.Target!.RefCnt += 1"
		set "%~2=_G.NS[!_G.NSP!]"
	)

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_New *NSVar
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'NSVar' undefined."
	
	set /a "_G.NSP += 1"
	set "_G.NS[!_G.NSP!].=NSBODY"
	set "_G.NS[!_G.NSP!].RefCnt=1"
	
	set /a "_G.NSP += 1"
	set "_G.NS[!_G.NSP!].=NSMETA"
	set /a "_G.NS[!_G.NSP!].Target = _G.NS - 1"
	%&% "_G.NS[!_G.NSP!].Target" "_T.NSBodyPtr"
	set "_G.NS[!_G.NSP!].Target=_G.NS[!_T.NSBodyPtr!]"
	set "_G.LEVEL[!_G.LEVEL!][_G.NS[!_G.NSP!]]=_G.NS[!_G.NSP!]"
	
	set "%~1=_G.NS[!_G.NSP!]"

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Set *NS Field *Val
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "'NS' undefined."
	if "%~2" == "" %?|% "'Field' undefined."
	if "%~3" == "" %?|% "'Val' undefined."

	%&% "!%~1!." "_T.NSMetaTag"
	if not "!_T.NSMetaTag!" == "NSMETA" %?|% "Invalid NSMETA."
	%&% "!%~1!.Target" "_T.NSBody"
	%&% "!_T.NSBody!." "_T.NSBodyTag"
	if not "!_T.NSBodyTag!" == "NSBODY" %?|% "Invalid NSBODY."
	
	%&% "!_T.NSBody!.RefCnt" "_T.RefCnt"
	if "!_T.RefCnt!" == "1" (
		if defined !_T.NSBody!.Data.Key.%~2 (
			%&% "!_T.NSBody!.Data.Value.%~2" "_T.OldVal"
			%&% "!_T.OldVal!." "_T.OldValTag"
			if "!_T.OldValTag!" == "NSMETA" (
				%&% "!_T.OldVal!.Target" "_T.OldValBody"
				set "!_T.OldVal!.="
				set "!_T.OldVal!.Target="

				%&% "!_T.OldValBody!." "_T.OldValBodyTag"
				if not "!_T.OldValBodyTag!" == "NSBODY" (
					%?|% "Invalid NSBody detected."
				)



			)
		)
		set "!_T.NSBody!.Data.Key.%~2=%~2"

		%&% "!%~3!." "_T.ValNSMetaTag"
		if "!_T.ValNSMetaTag!" == "NSMETA" (
			%&% "!%~3!.Target" "_T.ValNSBody"
			%&% "!_T.ValNSBody!." "_T.ValNSBodyTag"
			if not "!_T.ValNSBodyTag!" == "NSBODY" (
				%?|% "Invalid NSBody of 'Val'."
			)
			set /a "!_T.ValNSBody!.RefCnt += 1"

			set /a "_G.NSP += 1"
			set "_G.NS[!_G.NSP!].=NSMETA"
			set "_G.NS[!_G.NSP!].Target=!_T.ValNSBody!"
			set "!_T.NSBody!.Data.Value.%~2=_G.NS[!_G.NSP!]"
		) else (
			set "!_T.NSBody!.Data.Value.%~2=!%~3!"
		)
	) else (
		set /a "!_T.NSBody!.RefCnt -= 1"

		set /a "_G.NSP += 1"
		set /a "_T.NewNSBody=_G.NS[!_G.NSP!]"
		set "!_T.NewNSBody!.=NSBody"
		set "!_T.NewNSBody!.RefCnt=1"

		for /f "delims==" %%a in (
			'set !_T.NSBody!.Data.Key 2^>nul'
		) do (
			set "!_T.NewNSBody!.Data.Key.%%a=%%a"

			%&% "!_T.NSBody!.Data.Value.%%a" "_T.Value"
			%&% "!_T.Value!." "_T.ValueTag"
			if "!_T.ValueTag!" == "NSMETA" (
				%&% "!_T.Value!.Target" "_T.ValNSBody"
				%&% "!_T.ValNSBody!." "_T.ValNSBodyTag"
				if not "!_T.ValNSBodyTag!" == "NSBODY" (
					%?|% "Invalid NSBody detected."
				)
				set /a "!_T.ValNSBody!.RefCnt += 1"

				set /a "_G.NSP += 1"
				set "_G.NS[!_G.NSP!].=NSMETA"
				set "_G.NS[!_G.NSP!].Target=!_T.ValNSBody!"

				set "!_T.NewNSBody!.Data.Value.%%a=_G.NS[!_G.NSP!]"
			) else (
				set "!_T.NewNSBody!.Data.Value.%%a=!_T.Value!"
			)
		)

		set "!_T.NewNSBody!.Data.Key.%~2=%~2"

		%&% "!%~3!." "_T.ValNSMetaTag"
		if "!_T.ValNSMetaTag!" == "NSMETA" (
			%&% "!%~3!.Target" "_T.ValNSBody"
			%&% "!_T.ValNSBody!." "_T.ValNSBodyTag"
			if not "!_T.ValNSBodyTag!" == "NSBODY" (
				%?|% "Invalid NSBody of 'Val'."
			)
			set /a "!_T.ValNSBody!.RefCnt += 1"

			set /a "_G.NSP += 1"
			set "_G.NS[!_G.NSP!].=NSMETA"
			set "_G.NS[!_G.NSP!].Target=!_T.ValNSBody!"
			set "!_T.NewNSBody!.Data.Value.%~2=_G.NS[!_G.NSP!]"
		) else (
			set "!_T.NewNSBody!.Data.Value.%~2=!%~3!"
		)
	)
	
	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Get *NS Field *Val
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "NS undefined."
	if "%~2" == "" %?|% "Field undefined."
	if "%~3" == "" %?|% "Val undefined."
	
	if not defined !%~1!.NSMARK %?|% "Invalid NS."
	%&% !%~1!.Target _T.NSBody
	if not defined !_T.NSBody!.NSBODYMARK %?|% "Invalid NSBODY."
	
	if defined !_T.NSBody!.Data.Key.%~2 (
		%&% !_T.NSBody!.Data.Value.%~2 %~3
	) else (
		%?|% "Field not found."
	)
	
	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%

:UTIL_Free *Var
	if not defined _G.UTIL (
		2>con >&2 echo [%~n0] Fatal: UTIL not initialized.
		2>con >&2 pause
		exit 1
	)
	
	if "%~1" == "" %?|% "Var undefined."
	
	if not defined %~1.NSMARK %?|% "Invalid NS."
	if not defined !%~1.Target!.NSBODYMARK %?|% "Invalid NSBODY."
	
	%&% !%~1.Target!.RefCnt _T.RefCnt
	if "!_T.RefCnt!" == "1" (
		set "!%~1.Target!.RefCnt="
		set "!%~1.Target!.NSBODYMARK="
		for /f "delims==" %%a in (
			'set !%~1.Target!.Data.Key 2^>nul'
		) do (
			%&% !%~1.Target!.Data.Value.!%%a! _T.Value
			set "%%a="
			if defined !_T.Value!.NSMARK (
				call :UTIL_Free !_T.Value!
			) else (
				set "%%a="
			)
		)
	) else (
		set /a !%~1.Target!.RefCnt -= 1
	)
	
	set "%~1.NSMARK="
	set "%~1.Target="
	
	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
%-|%