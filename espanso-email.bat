@echo off
setlocal enabledelayedexpansion
set "chars=abcdefghijklmnopqrstuvwxyz0123456789"
set /a "length=6 + %random% %% 5"
set "username="
for /l %%i in (1,1,%length%) do (
    set /a "idx=!random! %% 36"
    for /l %%j in (0,1,35) do (
        if %%j==!idx! set "username=!username!!chars:~%%j,1!"
    )
)
echo !username!@malinator.com
