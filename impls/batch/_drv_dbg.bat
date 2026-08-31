@echo off
set "_G.RCMODE=1"
set "_G.DBG=1"
set "_G.NSPOBS=1"
pushd "%~dp0"
(echo (def! sum2 (fn* (n acc) (if (= n 0) acc (sum2 (- n 1) (+ acc n))))))| step5_tco.bat READALL > _dbg_out.txt 2>&1
popd
