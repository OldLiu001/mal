@echo off
setlocal ENABLEDELAYEDEXPANSION
echo ---1---
for %%. in (_L[0].) do (
    echo loop body x
)
echo ---2---