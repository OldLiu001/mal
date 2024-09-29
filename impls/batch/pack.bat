@echo off
setlocal ENABLEDELAYEDEXPANSION
if "%~1" == "" (
	echo Single file packer for MAL-BATCH
	echo.
	echo Usage: %~n0 ^<entry^> ^<output^> 
	echo 	^<entry^> - Entry point of the program, like "stepX_XXX.bat"
	echo 	^<output^> - Output file, e.g. "mal_packed.bat"
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
	echo set MAL_BATCH_IMPL_SINGLE_FILE=1
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
