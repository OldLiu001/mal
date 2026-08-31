@echo off
setlocal ENABLEDELAYEDEXPANSION
set _G.LEVEL=0

call :TOP
echo RESULT=!_L[0].out!
exit /b 0

:TOP
    rem bare ( block replaces former `for %%. in (_L[!level].) do (`
    (
        set "_L[!_G.LEVEL!].local=top@level"
        set "_L[!_G.LEVEL!].val=AAAA"
        rem pass level-var name string through a call, like macro args do
        call :SETVIA _L[!_G.LEVEL!].val WRITTEN
        if not "!_L[!_G.LEVEL!].val!"=="WRITTEN" ( echo TOP_INDIRECT_FAIL & exit /b 1 )
        set /a _G.LEVEL += 1
        call :NEST
        set /a _G.LEVEL -= 1
        if "!_L[!_G.LEVEL!].local!"=="top@level" ( echo TOP_FIRST_OK !_G.LEVEL! ) else ( echo TOP_FIRST_FAIL & exit /b 1 )
    )
exit /b 0

:NEST
    (
        set /a _G.LEVEL += 1
        call :LEAF
        set /a _G.LEVEL -= 1
        if "!_L[!_[G.LEVEL!].k!"=="k@level" ( echo NEST_OK !_G.LEVEL! ) else ( echo NEST_FAIL & exit /b 1 )
    )
exit /b 0

:LEAF
    (
        set "_L[!_G.LEVEL!].k=k@level"
        set "_L[!_G.LEVEL!].local=leaf@level"
        if "!_L[!_G.LEVEL!].k!"=="k@level" ( echo LEAF_OK !_G.LEVEL! ) else ( echo LEAF_FAIL & exit /b 1 )
    )
exit /b 0

:SETVIA
    echo DBG_ARG1=[%~1] ARG2=[%~2]
    set "%~1=%~2"
exit /b 0