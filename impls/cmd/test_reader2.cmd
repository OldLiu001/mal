@echo off
setlocal ENABLEDELAYEDEXPANSION

call reader.cmd ReadString "1"
echo RVAL=[!RVAL!] ERROR=[!RVAL_ERROR!]
