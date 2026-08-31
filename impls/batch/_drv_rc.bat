@echo off
set "_G.RCMODE=1"
set "_G.RECYCLE=1"
set "_G.NSPOBS=1"
pushd "%~dp0"
python _runall.py step5_tco.bat _sum2_5.mal 290 --readall
popd
