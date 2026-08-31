# Measure the true cost of cross-file call vs same-file call vs for/f subprocess,
# on a scratch NON-OneDrive dir. Each scenario runs N iterations, timed by caller.
@echo off
setlocal ENABLEDELAYEDEXPANSION
echo READY
set /a N=1