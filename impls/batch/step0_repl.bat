@rem Project Name: MAL
@rem Module Name: Main

@rem Global function list:
@rem 	Main
@rem 	Read
@rem 	Eval
@rem 	Print
@rem 	REP

@rem Origin name mapping:
@rem 	READ -> Read
@rem 	EVAL -> Eval
@rem 	PRINT -> Print
@rem 	rep -> REP

@echo off
setlocal disabledelayedexpansion
rem cancel all pre-defined variables.
for /f "delims==" %%a in ('set') do set "%%a="


:MAL_Main_GLOBALFUNCTION_Main
	set MAL_Main_LOCALVAR_Main_Input=
	set /p "MAL_Main_LOCALVAR_Main_Input=user> "
	if defined MAL_Main_LOCALVAR_Main_Input (
		rem first replace double quotation mark.
		set "MAL_Main_LOCALVAR_Main_Input=%MAL_Main_LOCALVAR_Main_Input:"=#$Double_Quotation$#%"
		rem Batch can't deal with "!" when delayed expansion is enabled, so replace it to a special string.
		call set "MAL_Main_LOCALVAR_Main_Input=%%MAL_Main_LOCALVAR_Main_Input:!=#$Exclamation$#%%"
		setlocal ENABLEDELAYEDEXPANSION
		%Speed Improve Start% (
			rem Batch has some problem in "^" processing, so replace it.
			set "MAL_Main_LOCALVAR_Main_Input=!MAL_Main_LOCALVAR_Main_Input:^=#$Caret$#!"
			rem replace %.
			set MAL_Main_LOCALVAR_Main_FormatedInput=
			:MAL_Main_LOCALTAG_Main_ReplacementLoop
			if defined MAL_Main_LOCALVAR_Main_Input (
				if "!MAL_Main_LOCALVAR_Main_Input:~,1!" == "%%" (
					set "MAL_Main_LOCALVAR_Main_FormatedInput=!MAL_Main_LOCALVAR_Main_FormatedInput!#$Percent$#"
				) else (
					set "MAL_Main_LOCALVAR_Main_FormatedInput=!MAL_Main_LOCALVAR_Main_FormatedInput!!MAL_Main_LOCALVAR_Main_Input:~,1!"
				)
				set "MAL_Main_LOCALVAR_Main_Input=!MAL_Main_LOCALVAR_Main_Input:~1!"
				goto MAL_Main_LOCALTAG_Main_ReplacementLoop
			)
			call :rep "!MAL_Main_LOCALVAR_Main_FormatedInput!"
			endlocal
		) %Speed Improve End%
	)
goto :MAL_Main_GLOBALFUNCTION_Main


%Speed Improve Start% (
	:MAL_Main_GLOBALFUNCTION_Read
		setlocal
			set "MAL_Main_GLOBALVAR_ReturnValue=%~1"
		for /f "tokens=* eol=" %%a in ("!MAL_Main_GLOBALVAR_ReturnValue!") do (
			endlocal
			set "MAL_Main_GLOBALVAR_ReturnValue=%%~a"
		)
	goto :eof

	:MAL_Main_GLOBALFUNCTION_Eval
		setlocal
			set "MAL_Main_GLOBALVAR_ReturnValue=%~1"
		for /f "tokens=* eol=" %%a in ("!MAL_Main_GLOBALVAR_ReturnValue!") do (
			endlocal
			set "MAL_Main_GLOBALVAR_ReturnValue=%%~a"
		)
	goto :eof

	:MAL_Main_GLOBALFUNCTION_Print
		setlocal
			set "MAL_Main_LOCALVAR_Print_Output=%~1"
			rem replace all speical symbol back.
			set MAL_Main_LOCALVAR_Print_OutputBuffer=
			:MAL_Main_LOCALTAG_Print_OutputLoop
			if "!MAL_Main_LOCALVAR_Print_Output:~,15!" == "#$Exclamation$#" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!^!"
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~15!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,9!" == "#$Caret$#" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!^^"
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~9!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,20!" == "#$Double_Quotation$#" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!^""
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~20!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,1!" == "=" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!="
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~1!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,1!" == " " (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer! "
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~1!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if "!MAL_Main_LOCALVAR_Print_Output:~,11!" == "#$Percent$#" (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!%%"
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~11!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			) else if defined MAL_Main_LOCALVAR_Print_Output (
				set "MAL_Main_LOCALVAR_Print_OutputBuffer=!MAL_Main_LOCALVAR_Print_OutputBuffer!!MAL_Main_LOCALVAR_Print_Output:~,1!"
				set "MAL_Main_LOCALVAR_Print_Output=!MAL_Main_LOCALVAR_Print_Output:~1!"
				goto MAL_Main_LOCALTAG_Print_OutputLoop
			)
			echo.!MAL_Main_LOCALVAR_Print_OutputBuffer!
			set "MAL_Main_GLOBALVAR_ReturnValue=%~1"
		for /f "tokens=* eol=" %%a in ("!MAL_Main_GLOBALVAR_ReturnValue!") do (
			endlocal
			set "MAL_Main_GLOBALVAR_ReturnValue=%%~a"
		)
	goto :eof

	:MAL_Main_GLOBALFUNCTION_REP
		setlocal
			call :READ "%~1"
			call :EVAL "!MAL_Main_GLOBALVAR_ReturnValue!"
			call :PRINT "!MAL_Main_GLOBALVAR_ReturnValue!"
		endlocal
	goto :eof
) %improve speed end%