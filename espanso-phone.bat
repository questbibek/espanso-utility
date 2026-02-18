@echo off
setlocal enabledelayedexpansion
set /a "prefix=%random% %% 2"
if !prefix!==0 (set "prefix=97") else (set "prefix=98")
set "number="
for /l %%i in (1,1,8) do (
    set /a "digit=!random! %% 10"
    set "number=!number!!digit!"
)
echo !prefix!!number!
