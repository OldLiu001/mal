@echo off
setlocal ENABLEDELAYEDEXPANSION
set /a "_G.LEVEL=1"
set "_L[1]."
set "_L[1].S=+"
set "_L[1].Enc="
call :Encode
set "r1=!_L[1].Enc!"
set "_L[1].S=let*"
set "_L[1].Enc="
call :Encode
set "r2=!_L[1].Enc!"
set "_L[1].S=def!"
set "_L[1].Enc="
call :Encode
set "r3=!_L[1].Enc!"
set "_L[1].S=mynum"
set "_L[1].Enc="
call :Encode
set "r4=!_L[1].Enc!"
set "_L[1].S=MYNUM"
set "_L[1].Enc="
call :Encode
set "r5=!_L[1].Enc!"
set "_L[1].S=x"
set "_L[1].Enc="
call :Encode
set "r6=!_L[1].Enc!"
echo PLUS=[%r1%] LET=[%r2%] DEF=[%r3%] MYNUM=[%r4%] MYNUM_UP=[%r5%] X=[%r6%]
exit /b 0
:Encode
for %%. in (_L[!_G.LEVEL!].) do (
	if defined %%.S (
		set "%%.Ch=!%%.S:~,1!"
		set "%%.S=!%%.S:~1!"
		if "!%%.Ch!" geq "a" if "!%%.Ch!" leq "z" (
			set "%%.Enc=!%%.Enc!!%%.Ch!0"
			goto Encode
		)
		if "!%%.Ch!" equ "!" (
			set "%%.Enc=!%%.Enc!$E"
			goto Encode
		)
		set "%%.Enc=!%%.Enc!!%%.Ch!1"
		goto Encode
	)
)
exit /b 0