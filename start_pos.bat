@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo ======================================================
echo   PIMUT TRADERS POS - ADVANCED STARTUP
echo ======================================================
echo.

:: 1. Find Python
set "PY_CMD="
for %%p in (python.exe py.exe python3.exe) do (
    if "!PY_CMD!"=="" (
        where %%p >nul 2>nul
        if !ERRORLEVEL! == 0 (
            set "PY_CMD=%%p"
        )
    )
)

if "!PY_CMD!"=="" (
    echo [ERROR] Python was not found on your system.
    echo Please install Python from https://www.python.org/
    echo and ensure "Add Python to PATH" is checked during installation.
    echo.
    pause
    exit /b
)

echo [1/4] Using: !PY_CMD!
!PY_CMD! --version

:: 2. Check/Install Core Dependencies
echo [2/4] Verifying core components...
!PY_CMD! -m pip install flask flask-cors flask-jwt-extended cloudinary >nul 2>&1
if !ERRORLEVEL! neq 0 (
    echo [INFO] Standard installation check failed. Trying full requirements...
    !PY_CMD! -m pip install -r backend/requirements.txt
)

:: 3. Configure Port & Host
set "POS_PORT=5000"
:: Use 127.0.0.1 as primary to avoid getaddrinfo resolution issues
set "POS_BIND_HOST=127.0.0.1"

:: Auto-detect if port 5000 is busy
netstat -ano | findstr :5000 | findstr LISTENING >nul
if !ERRORLEVEL! == 0 (
    echo [WARNING] Port 5000 is busy. Switching to 5001...
    set "POS_PORT=5001"
)

echo.
echo ======================================================
echo   SERVER LAUNCH
echo ======================================================
echo  URL: http://!POS_BIND_HOST!:!POS_PORT!/
echo ======================================================
echo.

:: 4. Start Backend
echo [3/4] Starting Server Window...
:: Start the backend and keep window open if it crashes
start "Pimut POS Server" cmd /k "cd /d "%~dp0" && set POS_BIND_HOST=!POS_BIND_HOST! && set POS_PORT=!POS_PORT! && !PY_CMD! backend/app.py || (echo. & echo [CRITICAL] Backend failed to start. & pause)"

:: 5. Intelligent Wait (Waits for the port to actually open)
echo [4/4] Waiting for server to become ready...
set "ready=0"
:: Try for up to 30 seconds
for /L %%i in (1,1,30) do (
    if "!ready!"=="0" (
        :: Check for the specific port in LISTENING state
        netstat -ano | findstr :!POS_PORT! | findstr LISTENING >nul
        if !ERRORLEVEL! == 0 (
            set "ready=1"
        ) else (
            <nul set /p=.
            timeout /t 1 /nobreak >nul
        )
    )
)

echo.
if "!ready!"=="1" (
    echo Server is ready! Launching POS...
    start "" "http://!POS_BIND_HOST!:!POS_PORT!/"
) else (
    echo.
    echo [ERROR] The server is taking too long to start.
    echo Please check the "Pimut POS Server" window for any error messages.
    echo.
    pause
)

exit /b
