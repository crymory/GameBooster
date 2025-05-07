@echo off
title Ghost Toolbox Custom Edition
color 0B
setlocal EnableDelayedExpansion

:: === Настрой GitHub путь и локальные переменные ===
set "TOOLS_URL=https://raw.githubusercontent.com/ТВОЙ-АККАУНТ/ТВОЙ-РЕПОЗИТОРИЙ/main"
set "NHCOLOR_FILE=nhcolor.exe"
set "TEMP_FOLDER=%~dp0tools"

:: === Создать папку для утилит, если её нет ===
if not exist "%TEMP_FOLDER%" (
    mkdir "%TEMP_FOLDER%"
)

:: === Скачать nhcolor.exe, если не существует ===
if not exist "%TEMP_FOLDER%\%NHCOLOR_FILE%" (
    echo Downloading nhcolor.exe ...
    powershell -Command "Invoke-WebRequest -Uri '%TOOLS_URL%/%NHCOLOR_FILE%' -OutFile '%TEMP_FOLDER%\%NHCOLOR_FILE%'"
)

:: === Добавить в PATH временно для текущего скрипта ===
set "PATH=%TEMP_FOLDER%;%PATH%"

:: === Используем nhcolor для меню ===
cls
%NHCOLOR_FILE% 0B "============================================================================"
%NHCOLOR_FILE% 07 " GHOST TOOLBOX CUSTOM | USER: %USERNAME% | COMPUTERNAME: %COMPUTERNAME%"
%NHCOLOR_FILE% 0B "============================================================================"
echo.

%NHCOLOR_FILE% 03 " [1] | Очистить логи"
%NHCOLOR_FILE% 03 " [2] | Отключить обновления Windows"
%NHCOLOR_FILE% 03 " [3] | Установить Google Chrome"
%NHCOLOR_FILE% 03 " [4] | Выход"

set /p choice=Выберите пункт: 

if "%choice%"=="1" goto clearlogs
if "%choice%"=="2" goto stopupdates
if "%choice%"=="3" goto chrome
if "%choice%"=="4" exit
goto :eof

:clearlogs
echo Очистка логов...
for /F "tokens=*" %%G in ('wevtutil.exe el') DO wevtutil.exe cl "%%G"
pause
goto :eof

:stopupdates
echo Отключение обновлений Windows...
sc stop wuauserv
sc config wuauserv start= disabled
pause
goto :eof

:chrome
echo Установка Chrome...
start https://dl.google.com/chrome/install/latest/chrome_installer.exe
pause
goto :eof
