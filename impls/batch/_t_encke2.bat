@echo off
set _G.FAST=1
pushd "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
call NSUTIL :NSUTIL_Init _enctest
%{% MAIN EncKey "def$E" %}% %->% _R1
echo Enc(def$E^)=!_R1!
%{% MAIN EncKey "def!" %}% %->% _R2
echo Enc(def^^!)=!_R2!
echo done
