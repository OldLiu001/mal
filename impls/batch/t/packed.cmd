@echo off
set _G.PACKED=1
if "%~1" equ "CALL_READALL" goto :READALL
if "%~1" equ "CALL_READLINE" goto :READLINE
if "%~1" equ "CALL_WRITEALL" goto :WRITEALL
:MAIN
@echo off
set _G.FAST=1
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || %?|% "Call '%~nx0' failed."
	)
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)


set _ & (set | find /C /V "") & pause<nul
time <nul
%{% MAIN TEST3 %}%
time <nul
set _ & (set | find /C /V "") & pause
%-|%


:MAIN_TEST
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.A %}%
		set %%.B=3

		set %%.B2=30
		%{s% %%.A k %%.B %}%
		%{s% %%.A k2 %%.B %}%
		%{s% %%.A k3 %%.B %}%
		%{g% %%.A k  %%.R %}%


		%{s% %%.A k2 %%.B2 %}%

		%{n% %%.o %}%
		%{s% %%.A o1 %%.o %}%

		%{s% %%.A k3 %%.o %}%

		%{s% %%.A o1 %%.B2 %}%
		%<-% %%.A
	)
%-|%


:MAIN_TEST2
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% MAIN TEST %}% %->% %%.T
		%<-% %%.T
	)
%-|%

:MAIN_TEST3
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% MAIN TEST2 %->% %%.T
		%<-% %%.T
	)
%-|% 
exit /b 0
:nsutil
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

:NSUTIL_Init Main
	if not defined _G.NSUTIL (
		if defined _G.PACKED (
			call :UTIL_Init "%~1"
		) else (
			call UTIL :UTIL_Init "%~1"
		)

		set "_G.NSUTIL=%~n0"

		set /a "_G.NSP = 0"

		set "{n=!{! NSUTIL New"
		set "{c=!{! NSUTIL Clone"
		set "{g=!{! NSUTIL Get"
		set "{s=!{! NSUTIL Set"
	)
%-|%

:NSUTIL_New *NSVar
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
		
		if "%~1" == "" %?|% "'NSVar' undefined."

		set /a "_G.NSP += 1"
		set "%%.NSBody=_G.NS[!_G.NSP!]"
		set "!%%.NSBody!.Type=NSBody"
		set /a "_G.NSP += 1"
		set "%%.NSMeta=_G.NS[!_G.NSP!]"
		set "!%%.NSMeta!.Type=NSMeta"

		set "!%%.NSBody!.RefCnt=1"
		set "!%%.NSMeta!.Target=!%%.NSBody!"
		
		set /a "%%.PrevLv = _G.LEVEL - 1"
		set "_G.LEVEL[!%%.PrevLv!][!%%.NSMeta!]=!%%.NSMeta!"
		
		set "%~1=!%%.NSMeta!"
	)
%-|%

:NSUTIL_IsNSMeta *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."

		%&% "!%~1!.Type" "%%.Type"
		if /i "!%%.Type!" == "NSMeta" (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_IsNSBody *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."

		%&% "!%~1!.Type" "%%.Type"
		if /i "!%%.Type!" == "NSBody" (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_IsValidNS *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."

		%{% NSUTIL IsNSMeta "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" (
			%<-% %%.Res
			%-|%
		)
		%{% NSUTIL IsNSBody "!%~1!.Target" %}% %->% %%.Res
		%<-% %%.Res
	)
%-|%

:NSUTIL_AssertValidNS *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL IsValidNS "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" %?|% "not a valid NS."
	)
%-|%

:NSUTIL_AssertValidNSBody *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL IsNSBody "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" %?|% "not a valid NS."
	)
%-|%

:NSUTIL_Clone *From *To
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
		if "%~1" == "" %?|% "'From' undefined."
		if "%~2" == "" %?|% "'To' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		set /a "_G.NSP += 1"
		set "_G.NS[!_G.NSP!].Type=NSMeta"
		%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
		%&% "!%~1!.Target" "%%.NSBody"
		set /a "!%%.NSBody!.RefCnt += 1"

		set "%~2=_G.NS[!_G.NSP!]"

		set /a "%%.PrevLv = _G.LEVEL - 1"
		set "_G.LEVEL[!%%.PrevLv!][!%~2!]=!%~2!"
	)
%-|%

:NSUTIL_CloneMeta *From *To
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
		if "%~1" == "" %?|% "'From' undefined."
		if "%~2" == "" %?|% "'To' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		set /a "_G.NSP += 1"
		set "_G.NS[!_G.NSP!].Type=NSMeta"
		%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
		%&% "!%~1!.Target" "%%.NSBody"
		set /a "!%%.NSBody!.RefCnt += 1"

		set "%~2=_G.NS[!_G.NSP!]"
	)
%-|%

:NSUTIL_HasField *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		if "%~2" == "" %?|% "'Field' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%&% "!%~1!.Target" "%%.NSBody"
		if defined !%%.NSBody!.Data.Key[%~2] (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_Get *NS Field *Val
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
	
		if "%~1" == "" %?|% "'NS' undefined."
		if "%~2" == "" %?|% "'Field' undefined."
		if "%~3" == "" %?|% "'Val' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%{% NSUTIL HasField "%~1" "%~2" %}% %->% %%.Res

		%&% "!%~1!.Target" "%%.NSBody"
		%&% "!%%.NSBody!.Data.Value[%~2]" "%~3"
		set "!%%.NSBody!.Data.Key[%~2]="
		set "!%%.NSBody!.Data.Value[%~2]="
	)
%-|%

:NSUTIL_Free *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		%&% _G.RET %%.RetBackup

		if "%~1" == "" %?|% "'NS' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%
	
		%&% !%~1!.Target %%.NSBody
		set "!%~1!.Type="
		set "!%~1!.Target="

		%{% NSUTIL FreeNSBody "%%.NSBody" %}%

		%&% %%.RetBackup _G.RET
	)
%-|%

:NSUTIL_FreeNSBody *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
	
		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL AssertValidNSBody "%~1" %}%

		%&% "!%~1!.RefCnt" "%%.RefCnt"

		if !%%.RefCnt! gtr 1 (
			set /a "!%~1!.RefCnt -= 1"
		) else (
			if !%%.RefCnt! lss 1 (
				%?|% "double free detected."
			)

			set "!%~1!.Type="
			set "!%~1!.RefCnt="

			for /f "delims==" %%a in (
				'set !%~1!.Data.Key 2^>nul'
			) do (
				%&% "!%~1!.Data.Value[!%%a!]" "%%.Var"
				set "!%~1!.Data.Value[!%%a!]="

				%{% NSUTIL IsNSMeta "%%.Var" %}% %->% "%%.IsMeta"
				if "!%%.IsMeta!" == "1" (
					%{% NSUTIL Free "%%.Var" %}%
				)
				set "%%a="
			)
		)
	)
%-|%

:NSUTIL_CloneBody *NS *NewNS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
	
		if "%~1" == "" %?|% "'NS' undefined."
		if "%~2" == "" %?|% "'NewNS' undefined."

		%{% NSUTIL AssertValidNSBody "%~1" %}%

		set /a "_G.NSP += 1"
		set "%%.NewBody=_G.NS[!_G.NSP!]"
		set "!%%.NewBody!.Type=NSBody"
		set "!%%.NewBody!.RefCnt=1"

		for /f "delims==" %%a in (
			'set !%~1!.Data.Key 2^>nul'
		) do (
			set "!%%.NewBody!.Data.Key[%%a]=%%a"

			%{% NSUTIL IsNSMeta "!%~1!.Data.Value[%%a]" %}% %->% %%.IsMeta
			if "!%%.IsMeta!" == "1" (
				%{% NSUTIL CloneMeta "!%~1!.Data.Value[%%a]" "!%%.NewBody!.Data.Value[%%a]" %}%
			) else (
				%&% "!%~1!.Data.Value[%%a]" "!%%.NewBody!.Data.Value[%%a]"
			)
		)

		%&% "%%.NewBody" "%~2"
	)
%-|%

:NSUTIL_Set *NS Field *Val
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
	
		if "%~1" == "" %?|% "'NS' undefined."
		if "%~2" == "" %?|% "'Field' undefined."
		if "%~3" == "" %?|% "'Val' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%&% "!%~1!.Target" "%%.NSBody"

		%&% "!%%.NSBody!.RefCnt" "%%.RefCnt"
		if !%%.RefCnt! gtr 1 (
			set /a "!%%.NSBody!.RefCnt -= 1"
			%{% NSUTIL CloneBody "%%.NSBody" "%%.NewBody" %}%
			%&% "%%.NewBody" "%%.NSBody"
			%&% "%%.NewBody" "!%~1!.Target"
		)

		%{% NSUTIL HasField "%~1" "%~2" %}% %->% "%%.HasField"
		if "!%%.HasField!" == "1" (
			%&% "!%%.NSBody!.Data.Value[%~2]" %%.OldVal
			%{% NSUTIL IsValidNS "%%.OldVal" %}% %->% "%%.IsMeta"
			if "!%%.IsMeta!" == "1" (
				%{% NSUTIL Free "%%.OldVal" %}%
			)
		)

		set "!%%.NSBody!.Data.Key[%~2]=%~2"

		%{% NSUTIL IsValidNS "%~3" %}% %->% "%%.IsNS"
		if "!%%.IsNS!" == "1" (
			%{% NSUTIL CloneMeta "%~3" "!%%.NSBody!.Data.Value[%~2]" %}%
		) else (
			%&% "%~3" "!%%.NSBody!.Data.Value[%~2]"
		)
	)
%-|%

 
exit /b 0
:pack
@echo off
setlocal ENABLEDELAYEDEXPANSION
if "%~1" == "" (
	echo Single file packer for MAL-BATCH
	echo.
	echo Usage: %~n0 ^<entry^> ^<output^> 
	echo 	^<entry^> - Entry point of the program, like "stepX_XXX.bat"
	echo 	^<output^> - Output file, e.g. "mal_packed.bat"
	echo.
	pause
	exit /b 1
)

pushd "%~dp0"
set "entry=%~1"
set "output=%~2"

if exist "%output%" (
	echo Output file already exist.
	exit /b 1
)
if not exist "%entry%" (
	echo Entry not exist.
	exit /b 1
)

(
	echo @echo off
	echo set _G.PACKED=1
	echo if "%%~1" equ "CALL_READALL" goto :READALL
	echo if "%%~1" equ "CALL_READLINE" goto :READLINE
	echo if "%%~1" equ "CALL_WRITEALL" goto :WRITEALL
	echo :MAIN
) >"%output%"
type %entry% >>"%output%"

for /f "delims=" %%i in (
	'dir /b *.bat *.cmd ^| findstr /v /r "^step"'
) do (
	if "%%i" neq "%entry%" (
		(
			echo. & echo exit /b 0
			echo :%%~ni
		) >>"%output%"
		type "%%i"  >>"%output%"
	)
)
 
exit /b 0
:util
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
		set /a "_G.LEVEL = 0
		set "_G.RET="
		set "_G.ERR="
		
		set "_T.UTIL="
		if not defined _G.PACKED set "_T.UTIL=!_G.UTIL!"
		
		set "<-=call !_T.UTIL! :UTIL_SetRet"
		set "->=& call !_T.UTIL! :UTIL_GetRet"
		set "|->=call !_T.UTIL! :UTIL_GetRet"
		set "??=call !_T.UTIL! :UTIL_Throw"		
		set "?|=call !_T.UTIL! :UTIL_Fatal"
		set "&=call !_T.UTIL! :UTIL_Copy"
		set "{=call !_T.UTIL! :UTIL_Invoke"
		set "}=& (if defined _G.ERR (exit /b 0))"
		set "?}=& if defined _G.ERR"
		set "?=if defined _G.ERR"
		set "-|=exit /b 0"

		if defined _G.FAST (
			set _G.SKIPTHIS=rem
			set _G.DOTHIS=
		) else (
			set _G.SKIPTHIS=
			set _G.DOTHIS=rem
		)
	) else (
		%?|% "double initialized."
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
	
	set "_G.TRACE[!_G.LEVEL!]=!_G.TRACE!"
	set "_G.TRACE=!_G.TRACE!>(%~1)%~2"
	
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
	
	if defined _G.NSUTIL (
		set "_G.TRACE[!_G.LEVEL!]=!_G.TRACE!"
		set "_G.TRACE=!_G.TRACE!>(NSUTIL)Free"
		set /a "_G.LEVEL += 1"
		set /a "_T.PrevLevel = _G.LEVEL - 1"

		for /f "delims==" %%a in (
			'set "_G.LEVEL[!_T.PrevLevel!]" 2^>nul'
		) do (
			if defined _G.PACKED (
				call :NSUTIL_Free "%%a"
			) else (
				call NSUTIL :NSUTIL_Free "%%a"
			)
			set "%%a="
		)

		for /f "delims==" %%a in (
			'set "_L[!_G.LEVEL!]" 2^>nul'
		) do set "%%a="

		set /a "_G.LEVEL -= 1"
		%&% "_G.TRACE[!_G.LEVEL!]" "_G.TRACE"
		set "_G.TRACE[!_G.LEVEL!]="
	)
	
	for /f "delims==" %%a in (
		'set "_L[!_G.LEVEL!]" 2^>nul'
	) do set "%%a="
	
	set /a _G.LEVEL -= 1
	
	%&% "_G.TRACE[!_G.LEVEL!]" "_G.TRACE"
	set "_G.TRACE[!_G.LEVEL!]="
	
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

	if defined _G.NSUTIL (
		%&% "!%~1!.Type" "_T.Type"
		if /i "!_T.Type!" == "NSMeta" (
			%{% NSUTIL CloneMeta "%~1" "_G.RET" %}%

			set /a "_T.PrevLevel = _G.LEVEL - 1"
			set "_G.LEVEL[!_T.PrevLevel!][!_G.RET!]=!_G.RET!"
		) else (
			set "_G.RET=!%~1!"
		)
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

	%?|% TODO: Add NS logic.
	set "_G.ERR=!%~1!"

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
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
 
exit /b 0
:packed
@echo off
set _G.PACKED=1
if "%~1" equ "CALL_READALL" goto :READALL
if "%~1" equ "CALL_READLINE" goto :READLINE
if "%~1" equ "CALL_WRITEALL" goto :WRITEALL
:MAIN
@echo off
set _G.FAST=1
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b || %?|% "Call '%~nx0' failed."
	)
	%-|%
)
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
if not defined _G.PACKED (
	call NSUTIL :NSUTIL_Init %~n0
) else (
	call :NSUTIL_Init %~n0
)


set _ & (set | find /C /V "") & pause<nul
time <nul
%{% MAIN TEST3 %}%
time <nul
set _ & (set | find /C /V "") & pause
%-|%


:MAIN_TEST
	for %%. in (_L[!_G.LEVEL!].) do (
		%{n% %%.A %}%
		set %%.B=3

		set %%.B2=30
		%{s% %%.A k %%.B %}%
		%{s% %%.A k2 %%.B %}%
		%{s% %%.A k3 %%.B %}%
		%{g% %%.A k  %%.R %}%


		%{s% %%.A k2 %%.B2 %}%

		%{n% %%.o %}%
		%{s% %%.A o1 %%.o %}%

		%{s% %%.A k3 %%.o %}%

		%{s% %%.A o1 %%.B2 %}%
		%<-% %%.A
	)
%-|%


:MAIN_TEST2
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% MAIN TEST %}% %->% %%.T
		%<-% %%.T
	)
%-|%

:MAIN_TEST3
	for %%. in (_L[!_G.LEVEL!].) do (
		%{% MAIN TEST2 %->% %%.T
		%<-% %%.T
	)
%-|% 
exit /b 0
:nsutil
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

:NSUTIL_Init Main
	if not defined _G.NSUTIL (
		if defined _G.PACKED (
			call :UTIL_Init "%~1"
		) else (
			call UTIL :UTIL_Init "%~1"
		)

		set "_G.NSUTIL=%~n0"

		set /a "_G.NSP = 0"

		set "{n=!{! NSUTIL New"
		set "{c=!{! NSUTIL Clone"
		set "{g=!{! NSUTIL Get"
		set "{s=!{! NSUTIL Set"
	)
%-|%

:NSUTIL_New *NSVar
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
		
		if "%~1" == "" %?|% "'NSVar' undefined."

		set /a "_G.NSP += 1"
		set "%%.NSBody=_G.NS[!_G.NSP!]"
		set "!%%.NSBody!.Type=NSBody"
		set /a "_G.NSP += 1"
		set "%%.NSMeta=_G.NS[!_G.NSP!]"
		set "!%%.NSMeta!.Type=NSMeta"

		set "!%%.NSBody!.RefCnt=1"
		set "!%%.NSMeta!.Target=!%%.NSBody!"
		
		set /a "%%.PrevLv = _G.LEVEL - 1"
		set "_G.LEVEL[!%%.PrevLv!][!%%.NSMeta!]=!%%.NSMeta!"
		
		set "%~1=!%%.NSMeta!"
	)
%-|%

:NSUTIL_IsNSMeta *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."

		%&% "!%~1!.Type" "%%.Type"
		if /i "!%%.Type!" == "NSMeta" (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_IsNSBody *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."

		%&% "!%~1!.Type" "%%.Type"
		if /i "!%%.Type!" == "NSBody" (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_IsValidNS *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."

		%{% NSUTIL IsNSMeta "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" (
			%<-% %%.Res
			%-|%
		)
		%{% NSUTIL IsNSBody "!%~1!.Target" %}% %->% %%.Res
		%<-% %%.Res
	)
%-|%

:NSUTIL_AssertValidNS *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL IsValidNS "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" %?|% "not a valid NS."
	)
%-|%

:NSUTIL_AssertValidNSBody *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL IsNSBody "%~1" %}% %->% %%.Res
		if not "!%%.Res!" == "1" %?|% "not a valid NS."
	)
%-|%

:NSUTIL_Clone *From *To
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
		if "%~1" == "" %?|% "'From' undefined."
		if "%~2" == "" %?|% "'To' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		set /a "_G.NSP += 1"
		set "_G.NS[!_G.NSP!].Type=NSMeta"
		%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
		%&% "!%~1!.Target" "%%.NSBody"
		set /a "!%%.NSBody!.RefCnt += 1"

		set "%~2=_G.NS[!_G.NSP!]"

		set /a "%%.PrevLv = _G.LEVEL - 1"
		set "_G.LEVEL[!%%.PrevLv!][!%~2!]=!%~2!"
	)
%-|%

:NSUTIL_CloneMeta *From *To
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
		if "%~1" == "" %?|% "'From' undefined."
		if "%~2" == "" %?|% "'To' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		set /a "_G.NSP += 1"
		set "_G.NS[!_G.NSP!].Type=NSMeta"
		%&% "!%~1!.Target" "_G.NS[!_G.NSP!].Target"
		%&% "!%~1!.Target" "%%.NSBody"
		set /a "!%%.NSBody!.RefCnt += 1"

		set "%~2=_G.NS[!_G.NSP!]"
	)
%-|%

:NSUTIL_HasField *NS -> Bool
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		if "%~1" == "" %?|% "'NS' undefined."
		if "%~2" == "" %?|% "'Field' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%&% "!%~1!.Target" "%%.NSBody"
		if defined !%%.NSBody!.Data.Key[%~2] (
			set "%%.Res=1"
		) else (
			set "%%.Res=0"
		)
		%<-% "%%.Res"
	)
%-|%

:NSUTIL_Get *NS Field *Val
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
	
		if "%~1" == "" %?|% "'NS' undefined."
		if "%~2" == "" %?|% "'Field' undefined."
		if "%~3" == "" %?|% "'Val' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%{% NSUTIL HasField "%~1" "%~2" %}% %->% %%.Res

		%&% "!%~1!.Target" "%%.NSBody"
		%&% "!%%.NSBody!.Data.Value[%~2]" "%~3"
		set "!%%.NSBody!.Data.Key[%~2]="
		set "!%%.NSBody!.Data.Value[%~2]="
	)
%-|%

:NSUTIL_Free *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)

		%&% _G.RET %%.RetBackup

		if "%~1" == "" %?|% "'NS' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%
	
		%&% !%~1!.Target %%.NSBody
		set "!%~1!.Type="
		set "!%~1!.Target="

		%{% NSUTIL FreeNSBody "%%.NSBody" %}%

		%&% %%.RetBackup _G.RET
	)
%-|%

:NSUTIL_FreeNSBody *NS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
	
		if "%~1" == "" %?|% "'NS' undefined."
		%{% NSUTIL AssertValidNSBody "%~1" %}%

		%&% "!%~1!.RefCnt" "%%.RefCnt"

		if !%%.RefCnt! gtr 1 (
			set /a "!%~1!.RefCnt -= 1"
		) else (
			if !%%.RefCnt! lss 1 (
				%?|% "double free detected."
			)

			set "!%~1!.Type="
			set "!%~1!.RefCnt="

			for /f "delims==" %%a in (
				'set !%~1!.Data.Key 2^>nul'
			) do (
				%&% "!%~1!.Data.Value[!%%a!]" "%%.Var"
				set "!%~1!.Data.Value[!%%a!]="

				%{% NSUTIL IsNSMeta "%%.Var" %}% %->% "%%.IsMeta"
				if "!%%.IsMeta!" == "1" (
					%{% NSUTIL Free "%%.Var" %}%
				)
				set "%%a="
			)
		)
	)
%-|%

:NSUTIL_CloneBody *NS *NewNS
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
	
		if "%~1" == "" %?|% "'NS' undefined."
		if "%~2" == "" %?|% "'NewNS' undefined."

		%{% NSUTIL AssertValidNSBody "%~1" %}%

		set /a "_G.NSP += 1"
		set "%%.NewBody=_G.NS[!_G.NSP!]"
		set "!%%.NewBody!.Type=NSBody"
		set "!%%.NewBody!.RefCnt=1"

		for /f "delims==" %%a in (
			'set !%~1!.Data.Key 2^>nul'
		) do (
			set "!%%.NewBody!.Data.Key[%%a]=%%a"

			%{% NSUTIL IsNSMeta "!%~1!.Data.Value[%%a]" %}% %->% %%.IsMeta
			if "!%%.IsMeta!" == "1" (
				%{% NSUTIL CloneMeta "!%~1!.Data.Value[%%a]" "!%%.NewBody!.Data.Value[%%a]" %}%
			) else (
				%&% "!%~1!.Data.Value[%%a]" "!%%.NewBody!.Data.Value[%%a]"
			)
		)

		%&% "%%.NewBody" "%~2"
	)
%-|%

:NSUTIL_Set *NS Field *Val
	for %%. in (_L[!_G.LEVEL!].) do (
		if not defined _G.NSUTIL (
			2>con >&2 echo [%~n0] Fatal: NSUTIL not initialized.
			2>con >&2 pause
			exit 1
		)
	
		if "%~1" == "" %?|% "'NS' undefined."
		if "%~2" == "" %?|% "'Field' undefined."
		if "%~3" == "" %?|% "'Val' undefined."

		%{% NSUTIL AssertValidNS "%~1" %}%

		%&% "!%~1!.Target" "%%.NSBody"

		%&% "!%%.NSBody!.RefCnt" "%%.RefCnt"
		if !%%.RefCnt! gtr 1 (
			set /a "!%%.NSBody!.RefCnt -= 1"
			%{% NSUTIL CloneBody "%%.NSBody" "%%.NewBody" %}%
			%&% "%%.NewBody" "%%.NSBody"
			%&% "%%.NewBody" "!%~1!.Target"
		)

		%{% NSUTIL HasField "%~1" "%~2" %}% %->% "%%.HasField"
		if "!%%.HasField!" == "1" (
			%&% "!%%.NSBody!.Data.Value[%~2]" %%.OldVal
			%{% NSUTIL IsValidNS "%%.OldVal" %}% %->% "%%.IsMeta"
			if "!%%.IsMeta!" == "1" (
				%{% NSUTIL Free "%%.OldVal" %}%
			)
		)

		set "!%%.NSBody!.Data.Key[%~2]=%~2"

		%{% NSUTIL IsValidNS "%~3" %}% %->% "%%.IsNS"
		if "!%%.IsNS!" == "1" (
			%{% NSUTIL CloneMeta "%~3" "!%%.NSBody!.Data.Value[%~2]" %}%
		) else (
			%&% "%~3" "!%%.NSBody!.Data.Value[%~2]"
		)
	)
%-|%

 
exit /b 0
:pack
@echo off
setlocal ENABLEDELAYEDEXPANSION
if "%~1" == "" (
	echo Single file packer for MAL-BATCH
	echo.
	echo Usage: %~n0 ^<entry^> ^<output^> 
	echo 	^<entry^> - Entry point of the program, like "stepX_XXX.bat"
	echo 	^<output^> - Output file, e.g. "mal_packed.bat"
	echo.
	pause
	exit /b 1
)

pushd "%~dp0"
set "entry=%~1"
set "output=%~2"

if exist "%output%" (
	echo Output file already exist.
	exit /b 1
)
if not exist "%entry%" (
	echo Entry not exist.
	exit /b 1
)

(
	echo @echo off
	echo set _G.PACKED=1
	echo if "%%~1" equ "CALL_READALL" goto :READALL
	echo if "%%~1" equ "CALL_READLINE" goto :READLINE
	echo if "%%~1" equ "CALL_WRITEALL" goto :WRITEALL
	echo :MAIN
) >"%output%"
type %entry% >>"%output%"

for /f "delims=" %%i in (
	'dir /b *.bat *.cmd ^| findstr /v /r "^step"'
) do (
	if "%%i" neq "%entry%" (
		(
			echo. & echo exit /b 0
			echo :%%~ni
		) >>"%output%"
		type "%%i"  >>"%output%"
	)
)
 
exit /b 0
:util
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
		set /a "_G.LEVEL = 0
		set "_G.RET="
		set "_G.ERR="
		
		set "_T.UTIL="
		if not defined _G.PACKED set "_T.UTIL=!_G.UTIL!"
		
		set "<-=call !_T.UTIL! :UTIL_SetRet"
		set "->=& call !_T.UTIL! :UTIL_GetRet"
		set "|->=call !_T.UTIL! :UTIL_GetRet"
		set "??=call !_T.UTIL! :UTIL_Throw"		
		set "?|=call !_T.UTIL! :UTIL_Fatal"
		set "&=call !_T.UTIL! :UTIL_Copy"
		set "{=call !_T.UTIL! :UTIL_Invoke"
		set "}=& (if defined _G.ERR (exit /b 0))"
		set "?}=& if defined _G.ERR"
		set "?=if defined _G.ERR"
		set "-|=exit /b 0"

		if defined _G.FAST (
			set _G.SKIPTHIS=rem
			set _G.DOTHIS=
		) else (
			set _G.SKIPTHIS=
			set _G.DOTHIS=rem
		)
	) else (
		%?|% "double initialized."
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
	
	set "_G.TRACE[!_G.LEVEL!]=!_G.TRACE!"
	set "_G.TRACE=!_G.TRACE!>(%~1)%~2"
	
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
	
	if defined _G.NSUTIL (
		set "_G.TRACE[!_G.LEVEL!]=!_G.TRACE!"
		set "_G.TRACE=!_G.TRACE!>(NSUTIL)Free"
		set /a "_G.LEVEL += 1"
		set /a "_T.PrevLevel = _G.LEVEL - 1"

		for /f "delims==" %%a in (
			'set "_G.LEVEL[!_T.PrevLevel!]" 2^>nul'
		) do (
			if defined _G.PACKED (
				call :NSUTIL_Free "%%a"
			) else (
				call NSUTIL :NSUTIL_Free "%%a"
			)
			set "%%a="
		)

		for /f "delims==" %%a in (
			'set "_L[!_G.LEVEL!]" 2^>nul'
		) do set "%%a="

		set /a "_G.LEVEL -= 1"
		%&% "_G.TRACE[!_G.LEVEL!]" "_G.TRACE"
		set "_G.TRACE[!_G.LEVEL!]="
	)
	
	for /f "delims==" %%a in (
		'set "_L[!_G.LEVEL!]" 2^>nul'
	) do set "%%a="
	
	set /a _G.LEVEL -= 1
	
	%&% "_G.TRACE[!_G.LEVEL!]" "_G.TRACE"
	set "_G.TRACE[!_G.LEVEL!]="
	
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

	if defined _G.NSUTIL (
		%&% "!%~1!.Type" "_T.Type"
		if /i "!_T.Type!" == "NSMeta" (
			%{% NSUTIL CloneMeta "%~1" "_G.RET" %}%

			set /a "_T.PrevLevel = _G.LEVEL - 1"
			set "_G.LEVEL[!_T.PrevLevel!][!_G.RET!]=!_G.RET!"
		) else (
			set "_G.RET=!%~1!"
		)
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

	%?|% TODO: Add NS logic.
	set "_G.ERR=!%~1!"

	for /f "delims==" %%a in (
		'set "_T" 2^>nul'
	) do set "%%a="
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
 
exit /b 0
:packed
@echo off
set _G.PACKED=1
if "%~1" equ "CALL_READALL" goto :READALL
if "%~1" equ "CALL_READLINE" goto :READLINE
if "%~1" equ "CALL_WRITEALL" goto :WRITEALL
:MAIN
@echo off
set _G.FAST=1
if "%~1" equ "CALL_SELF" (
	for /f "tokens=