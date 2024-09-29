@echo off
pushd "%~dp0"
cd ..\..\..
rem goto p
for %%a in (
	step0_repl
) do (
	rem echo @pushd "%%~dp0" ^& @cscript -nologo %%a.vbs > .\impls\batch\run_%%a.cmd
	python runtest.py --rundir "impls\batch" --test-timeout 1800 --deferrable --optional --no-pty "..\tests\%%a.mal" "%%a.bat"
	rem del .\impls\vbs\run_%%a.cmd
	rem pause
)
pause
exit

	step1_read_print
	step2_eval
	step3_env
	step4_if_fn_do
	step5_tco
	step6_file
	step7_quote
	step8_macros
	step9_try
	stepA_mal