@echo off
title OpenIPC Setup, Network, Config and Stream

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

set "USER_APP=cameraconfig.exe"
set "VCPKG_DLLS=C:\vcpkg\installed\x64-windows\bin"
set "CAMERA_IP=192.168.1.10"
set "MY_IP=192.168.1.20"

echo [1/7] Configuring Network IP (%MY_IP%)...
netsh interface ip set address "Ethernet 4" static %MY_IP% 255.255.255.0
if %errorlevel% neq 0 (
    echo ERROR: Failed to set IP. Check interface name!
    pause
    exit
)

echo.
echo [1.5/7] Waiting for connection to camera (%CAMERA_IP%)...
echo Windows is initializing the network adapter. Please wait...

:PING_LOOP
ping -n 1 -w 1000 %CAMERA_IP% >nul
if %errorlevel% == 0 (
    echo [OK] Camera is online!
    goto NETWORK_READY
)

timeout /t 1 >nul
echo .
goto PING_LOOP

:NETWORK_READY

echo.
echo [2/7] Checking FFplay...
where ffplay >nul 2>nul
if %errorlevel% neq 0 (
    winget install "FFmpeg (Essentials Build)" --accept-source-agreements --accept-package-agreements
)

echo [3/7] Checking libssh...
if not exist "C:\vcpkg" (
    cd /d C:\
    git clone https://github.com/microsoft/vcpkg.git
    cd vcpkg
    call bootstrap-vcpkg.bat
    cd /d "%~dp0"
)
C:\vcpkg\vcpkg install libssh:x64-windows

echo.
echo [4/7] Running configuration (User App)...

set "PATH=%VCPKG_DLLS%;%PATH%"

if exist "%USER_APP%" (
    "%USER_APP%"
) else (
    echo ERROR: File "%USER_APP%" not found!
    pause
    exit
)

echo.
echo [5/7] Configuration done. Waiting 40 seconds for reboot...
timeout /t 25 /nobreak

echo.
echo [6/7] Waiting for camera to restart...
:REBOOT_LOOP
ping -n 1 -w 1000 %CAMERA_IP% >nul
if %errorlevel% == 0 goto STREAM_START
timeout /t 1 >nul
goto REBOOT_LOOP

:STREAM_START
echo.
echo [7/7] Starting Stream...
ffplay -rtsp_transport tcp -fflags nobuffer -flags low_delay -i rtsp://root:root1234@%CAMERA_IP%:554/stream=0

pause
