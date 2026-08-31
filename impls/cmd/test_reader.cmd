@echo off
setlocal ENABLEDELAYEDEXPANSION
call reader.cmd ReadString "1"
echo RVAL=[!RVAL!] ERROR=[!RVAL_ERROR!]
call reader.cmd ReadString "(+ 1 2)"
echo RVAL=[!RVAL!] ERROR=[!RVAL_ERROR!]
