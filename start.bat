@echo off
setlocal

where uv >nul 2>nul
if errorlevel 1 (
    echo uv was not found.
    set /p answer=uv will be installed (https://astral.sh/uv/). Do you allow downloading it? Y/n 

    if /I "%answer%"=="n" (
        python -m pip install uv
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex"
    )

    where uv >nul 2>nul
    if errorlevel 1 (
        if exist "%USERPROFILE%\.local\bin\uv.exe" (
            set "PATH=%USERPROFILE%\.local\bin;%PATH%"
        )
    )

    where uv >nul 2>nul
    if errorlevel 1 (
        echo uv was installed but could not be found in this session. Open a new terminal and try again.
        pause
        exit /b 1
    )
)

cd /d "%~dp0src"
uv run main.py
pause
