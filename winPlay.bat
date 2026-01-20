@echo off
title OpenIPC Streamer

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

set "MY_APP=cameraconfig.exe"
set "MY_PLAYER=ffplay.exe"
set "INTERFACE=Ethernet 4"
set "PC_IP=192.168.1.20"
set "CAM_IP=192.168.1.10"
set "URL=rtsp://root:root1234@%CAM_IP%:554/stream=0"

netsh interface ip set address "%INTERFACE%" static %PC_IP% 255.255.255.0

:PING_LOOP
ping -n 1 -w 1000 %CAM_IP% >nul
if %errorlevel% == 0 goto RUN_CONFIG
timeout /t 1 >nul
goto PING_LOOP

:RUN_CONFIG
if exist "%MY_APP%" (
    "%MY_APP%"
) else (
    pause
    exit
)

timeout /t 25 /nobreak

if exist "%MY_PLAYER%" (
    start "" "%MY_PLAYER%" -rtsp_transport tcp -fflags nobuffer -flags low_delay -i %URL%
) else (
    ffplay -rtsp_transport tcp -fflags nobuffer -flags low_delay -i %URL%
)

exit
