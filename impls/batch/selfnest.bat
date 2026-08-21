@echo off
if "%~1" equ "CALL_SELF" (
	for /f "tokens=1,*" %%a in ('echo.%*') do (
		call %%b
	)
	exit /b 0
)
echo MAIN_START
call selfnest.bat CALL_SELF :F1
echo MAIN_END
exit /b 0
:F1
echo F1_ENTER
call selfnest.bat CALL_SELF :F2
echo F1_END
exit /b 0
:F2
echo F2_ENTER
call selfnest.bat CALL_SELF :F3
echo F2_END
exit /b 0
:F3
echo F3_ENTER
exit /b 0