@echo off
title GameBooster by rage
color 0B
setlocal EnableDelayedExpansion

:: === Настрой GitHub путь и локальные переменные ===
set "TOOLS_URL=https://raw.githubusercontent.com/crymory/GameBooster/f3f4e9024fd25bc2945cfdd93eedab7b2b46a85b/additional"
set "NHCOLOR_FILE=nhcolor.exe"
set "TEMP_FOLDER=%~dp0tools"
set "VERSION_FILE=version.txt"
set "CURRENT_VERSION=1.1"  :: Укажите текущую версию локального скрипта

:: === Создать папку для утилит, если её нет ===
if not exist "%TEMP_FOLDER%" (
    mkdir "%TEMP_FOLDER%"
)

:: === Проверка на обновление ===
echo Проверка на обновление...
powershell -Command "Invoke-WebRequest -Uri '%TOOLS_URL%/%VERSION_FILE%' -OutFile '%TEMP_FOLDER%\%VERSION_FILE%'"
set /p NEW_VERSION=<"%TEMP_FOLDER%\%VERSION_FILE%"

if "%NEW_VERSION%" NEQ "%CURRENT_VERSION%" (
    echo Обнаружена новая версия (%NEW_VERSION%). Хотите обновить?
    choice /C YN /M "Обновить?"
    if errorlevel 2 goto :eof
    if errorlevel 1 (
        echo Загрузка новой версии...
        powershell -Command "Invoke-WebRequest -Uri '%TOOLS_URL%/%NHCOLOR_FILE%' -OutFile '%TEMP_FOLDER%\%NHCOLOR_FILE%'"

        :: === Перезапуск программы для обновления ===
        echo Перезапуск...
        timeout /t 2 >nul
        start "" "%TEMP_FOLDER%\%NHCOLOR_FILE%"  :: Запускаем новый файл .exe
        exit
    )
)

:: === Скачать nhcolor.exe, если не существует ===
if not exist "%TEMP_FOLDER%\%NHCOLOR_FILE%" (
    echo Скачать nhcolor.exe ...
    powershell -Command "Invoke-WebRequest -Uri '%TOOLS_URL%/%NHCOLOR_FILE%' -OutFile '%TEMP_FOLDER%\%NHCOLOR_FILE%'"
)

:: === Добавить в PATH временно для текущего скрипта ===
set "PATH=%TEMP_FOLDER%;%PATH%"

:: === Показать интро "Powered by RAGE" ===
call :PainText 03 "                             P"
call :PainText 03 " o"
call :PainText 03 " w"
call :PainText 03 " e"
call :PainText 03 " r"
call :PainText 03 " e"
call :PainText 03 " d"
call :PainText 03 "    b"
call :PainText 03 " y"
call :PainText 0C "    R"
call :PainText 0C "  A"
call :PainText 0C "  G"
call :PainText 0C "  E"
timeout /t 3 >nul
cls

:: === Используем nhcolor для меню ===
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

:: === Подпрограмма для цветного текста с nhcolor ===
:PainText
:: %1 = цвет, %2 = текст
%NHCOLOR_FILE% %1 "%~2"
timeout /t 0.1 >nul
goto :eof
