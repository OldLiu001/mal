@echo off
setlocal ENABLEDELAYEDEXPANSION
set /a "_G.NSP = 0"
echo NSP0=!_G.NSP!
set /a "_G.NSP += 1"
echo NSP1=!_G.NSP!
set /a "_G.NSP += 1"
echo NSP2=!_G.NSP!
set "x=_G.NS[!_G.NSP!]"
echo x=!x!
exit /b 0