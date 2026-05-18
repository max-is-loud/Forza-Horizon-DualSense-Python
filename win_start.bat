@echo off
REM FH DualSense - Windows launcher.
setlocal enabledelayedexpansion
set "REPO=HamzaYslmn/Forza-Horizon-DualSense-Python"
set "RELEASES=https://github.com/%REPO%/releases/latest"
set "APP=%~dp0app"
set "PYPROJECT=%APP%\src\pyproject.toml"
set "GAME_CMD=%*"

for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "try { (Invoke-RestMethod -UseBasicParsing 'https://api.github.com/repos/%REPO%/releases/latest' -Headers @{'User-Agent'='fhds'}).tag_name } catch { '' }"`) do set "LATEST=%%v"
set "SOURCE=tags"
if "!LATEST!"=="" (set "LATEST=main" & set "SOURCE=heads")

set "CURRENT="
if exist "%PYPROJECT%" for /f "tokens=2 delims==" %%a in ('findstr /b /r /c:"^version" "%PYPROJECT%"') do if not defined CURRENT (
    set "v=%%a" & set "v=!v: =!" & set "v=!v:"=!" & set "CURRENT=v!v!"
)

if not defined CURRENT goto :install
if "!SOURCE!"=="heads" goto :install
if "!CURRENT!"=="!LATEST!" (echo Up to date ^(!CURRENT!^). & goto :run)
echo Update available: !CURRENT! -^> !LATEST!
set /p "ans=Update now? [Y/n]: "
if /I "!ans!"=="n" goto :run

:install
set "ZIP=%~dp0fhds.zip"
set "EXTRACT=%~dp0_extract"
echo Downloading !LATEST!...
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing 'https://github.com/%REPO%/archive/refs/!SOURCE!/!LATEST!.zip' -OutFile '%ZIP%'; if (Test-Path '%EXTRACT%') { Remove-Item -Recurse -Force '%EXTRACT%' }; Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%EXTRACT%' -Force } catch { exit 1 }"
if errorlevel 1 (
    echo Download failed. Get the release manually from %RELEASES%
    if not exist "%APP%\src\main.py" (pause & exit /b 1)
    goto :run
)
if not exist "%APP%" mkdir "%APP%"
for /d %%d in ("%EXTRACT%\*") do xcopy /e /y /q /i "%%d\*" "%APP%\" >nul
rmdir /s /q "%EXTRACT%"
del "%ZIP%"

:run
where uv >nul 2>nul || (
    echo Installing uv...
    powershell -NoProfile -Command "irm https://astral.sh/uv/install.ps1 | iex"
    where uv >nul 2>nul || (echo uv not on PATH - restart terminal. & pause & exit /b 1)
)

cd /d "%APP%\src"
set "PYTHONHOME="
set "PYTHONPATH="
set "PYTHONNOUSERSITE=1"
if defined GAME_CMD start "" !GAME_CMD!
uv run main.py
if not defined GAME_CMD pause >nul
endlocal
