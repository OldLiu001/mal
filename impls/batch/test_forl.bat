@echo off
setlocal
set "n=0"
for /l %%_ in () do (
	set /a n += 1
	if !n! gtr 5 exit /b 0
	echo ITER !n!
)
echo AFTER_LOOP
exit /b 0