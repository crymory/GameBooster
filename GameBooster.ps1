#requires -RunAsAdministrator

# Функция для проверки и загрузки обновлений
function Check-ForUpdates {
    $repo = "https://api.github.com/repos/username/repository/releases/latest"  # Замените на свой GitHub репозиторий
    $latestRelease = Invoke-RestMethod -Uri $repo
    $latestVersion = $latestRelease.tag_name
    $latestFileUrl = $latestRelease.assets[0].browser_download_url

    # Получаем текущую версию приложения
    $currentVersion = "1.0"  # Текущая версия вашего приложения

    if ($latestVersion -ne $currentVersion) {
        Write-Host "Найдена новая версия ($latestVersion)! Загружаю обновление..."

        # Загрузка последней версии с GitHub
        $updateFile = "GameBooster-Update.exe"
        Invoke-WebRequest -Uri $latestFileUrl -OutFile $updateFile

        # Запуск обновления
        Start-Process -FilePath $updateFile

        # Закрытие текущего процесса
        exit
    } else {
        Write-Host "У вас актуальная версия!"
    }
}

# Проверка обновлений при запуске
Check-ForUpdates

# Ваш основной скрипт или код (например, основной функционал GameBooster)
Clear-Host
Write-Host "Запуск GameBooster..."

Clear-Host
$host.UI.RawUI.WindowTitle = "GameBooster by rage"

# === Функции ===

function Pause {
    Read-Host -Prompt "Нажмите Enter для продолжения..."
}

function Check-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Этот скрипт нужно запускать с правами администратора!" -ForegroundColor Red
        Pause
        exit
    }
}

function Check-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "[!] Winget не найден! Установите его через Microsoft Store (App Installer)." -ForegroundColor Red
        Pause
        exit
    }
}

function Show-TitleAnimation {
    Clear-Host
    $title = "GameBooster by rage"
    Write-Host "nnnn"
    foreach ($char in $title.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 30
    }
    Write-Host "nn"
    Start-Sleep -Seconds 1
    Clear-Host
}

function Show-Progress {
    param (
        [string]$Activity,
        [int]$DurationMs
    )
    $steps = 20
    $delay = $DurationMs / $steps
    for ($i = 1; $i -le $steps; $i++) {
        Write-Progress -Activity $Activity -Status "$($i * 5)% выполнено" -PercentComplete ($i * 5)
        Start-Sleep -Milliseconds $delay
    }
    Write-Progress -Activity $Activity -Completed
}

function Disable-GameDVR {
    Write-Host "n[*] Отключение GameDVR..." -ForegroundColor Yellow
    Show-Progress -Activity "Отключение Game DVR" -DurationMs 2500
    $paths = @(
        "HKCU:\System\GameConfigStore",
        "HKCU:\Software\Microsoft\GameBar"
    )
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Set-ItemProperty -Path $path -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path $path -Name "GameDVR_FSEBehavior" -Value 2 -ErrorAction SilentlyContinue
        }
    }
    Write-Host "[?] GameDVR успешно отключен!" -ForegroundColor Green
}

function Enable-UltimatePerformancePlan {
    Write-Host "n[*] Включение схемы Ultimate Performance..." -ForegroundColor Yellow
    Show-Progress -Activity "Включение Ultimate Performance" -DurationMs 2500
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
    Write-Host "[?] Ultimate Performance включен!" -ForegroundColor Green
}

function Disable-BackgroundApps {
    Write-Host "n[*] Отключение фоновых приложений..." -ForegroundColor Yellow
    Show-Progress -Activity "Отключение фоновых приложений" -DurationMs 2500
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if (Test-Path $path) {
        Set-ItemProperty -Path $path -Name "GlobalUserDisabled" -Value 1 -ErrorAction SilentlyContinue
    }
    Write-Host "[?] Фоновые приложения отключены!" -ForegroundColor Green
}

function Enable-HWAcceleratedGPU {
    Write-Host "n[*] Включение аппаратного ускорения GPU..." -ForegroundColor Yellow
    Show-Progress -Activity "Настройка GPU" -DurationMs 2500
    $path = "HKCU:\Software\Microsoft\Avalon.Graphics"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name "DisableHWAcceleration" -Value 0 -Force
    Write-Host "[?] Аппаратное ускорение GPU включено!" -ForegroundColor Green
}

function Reduce-MenuDelay {
    Write-Host "n[*] Уменьшение задержки меню..." -ForegroundColor Yellow
    Show-Progress -Activity "Ускорение меню" -DurationMs 2500
    $path = "HKCU:\Control Panel\Desktop"
    if (Test-Path $path) {
        Set-ItemProperty -Path $path -Name "MenuShowDelay" -Value 0
    }
    Write-Host "[?] Задержка меню уменьшена!" -ForegroundColor Green
}

function Disable-VisualEffects {
    Write-Host "n[*] Отключение визуальных эффектов..." -ForegroundColor Yellow
    Show-Progress -Activity "Оптимизация визуальных эффектов" -DurationMs 2500
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2
    }
    Write-Host "[?] Визуальные эффекты оптимизированы!" -ForegroundColor Green
}

function Disable-Telemetry {
    Write-Host "n[*] Отключение телеметрии Microsoft..." -ForegroundColor Yellow
    Show-Progress -Activity "Настройка параметров приватности" -DurationMs 3500

    $services = @("DiagTrack", "dmwappushservice")
    foreach ($service in $services) {
        Get-Service -Name $service -ErrorAction SilentlyContinue | ForEach-Object {
            Set-Service -Name $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
            if ($_.Status -ne 'Stopped') {
                Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
            }
        }
    }

    $hostsPath = "$env:windir\System32\drivers\etc\hosts"
    $tempHostsPath = "$env:windir\System32\drivers\etc\hosts_temp"

    Copy-Item -Path $hostsPath -Destination $tempHostsPath -Force

    $entries = @(
        "0.0.0.0 vortex.data.microsoft.com",
        "0.0.0.0 settings-win.data.microsoft.com",
        "0.0.0.0 watson.telemetry.microsoft.com"
    )

    foreach ($entry in $entries) {
        $pattern = [regex]::Escape($entry)
        if (-not (Select-String -Path $tempHostsPath -Pattern $pattern -SimpleMatch -Quiet)) {
            Add-Content -Path $tempHostsPath -Value $entry
        }
    }

    Move-Item -Path $tempHostsPath -Destination $hostsPath -Force

    Write-Host "[?] Телеметрия Microsoft отключена!" -ForegroundColor Green
}

function Clear-JunkFiles {
    Write-Host "n[*] Очистка временных файлов..." -ForegroundColor Yellow
    Show-Progress -Activity "Очистка мусора" -DurationMs 3000
    
    $paths = @(
        "$env:TEMP",
        "$env:WINDIR\Temp",
        "$env:SystemRoot\Prefetch"
    )
    
    foreach ($path in $paths) {
        if (Test-Path -Path $path) {
            # Получаем список файлов и папок перед удалением
            $items = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue
            
            # Удаляем каждый элемент отдельно
            foreach ($item in $items) {
                try {
                    Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction SilentlyContinue
                }
                catch {
                    # Пропускаем файлы, которые невозможно удалить
                    Write-Host "  Невозможно удалить: $($item.FullName)" -ForegroundColor DarkYellow
                }
            }
        }
        else {
            Write-Host "  Путь не существует: $path" -ForegroundColor DarkYellow
        }
    }
    
    Write-Host "[?] Мусор успешно очищен!" -ForegroundColor Green
}

function Disable-UnnecessaryServices {
    Write-Host "n[*] Отключение ненужных служб..." -ForegroundColor Yellow
    Show-Progress -Activity "Отключение служб" -DurationMs 3000
    $services = @(
        "Fax", "XblGameSave", "WMPNetworkSvc"
    )
    foreach ($service in $services) {
        Get-Service -Name $service -ErrorAction SilentlyContinue | ForEach-Object {
            Set-Service -Name $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
            if ($_.Status -ne 'Stopped') {
                Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
            }
        }
    }
    Write-Host "[?] Ненужные службы отключены!" -ForegroundColor Green
}

function Show-SystemInfo {
    Write-Host "n[*] Информация о системе:" -ForegroundColor Yellow
    systeminfo | Out-Host
}

function Apply-AllTweaks {
    Disable-GameDVR
    Enable-UltimatePerformancePlan
    Disable-BackgroundApps
    Enable-HWAcceleratedGPU
    Reduce-MenuDelay
    Disable-VisualEffects
    Disable-Telemetry
    Write-Host "n[?] Все твики успешно применены!" -ForegroundColor Green
}

function Install-SingleApplication {
    param (
        [string]$Id,
        [string]$Name
    )
    Write-Host "n[*] Установка $Name..." -ForegroundColor Yellow
    Show-Progress -Activity "Установка $Name" -DurationMs 2000
    winget install --id $Id --silent --accept-package-agreements --accept-source-agreements -e
    Write-Host "[?] $Name успешно установлен!" -ForegroundColor Green
}

# Новая функция для меню установки приложений
function Applications-Menu {
    Check-Winget
    
    while ($true) {
        Clear-Host
        Write-Host "г============================================¬" -ForegroundColor Cyan
        Write-Host "¦         Установка приложений               ¦" -ForegroundColor Cyan
        Write-Host "L============================================-" -ForegroundColor Cyan
        Write-Host
        Write-Host " [1] Установить Discord" -ForegroundColor Green
        Write-Host " [2] Установить Steam" -ForegroundColor Green
        Write-Host " [3] Установить Google Chrome" -ForegroundColor Green
        Write-Host " [4] Установить 7-Zip" -ForegroundColor Green
        Write-Host " [0] Вернуться в главное меню" -ForegroundColor Red
        Write-Host
        $choice = Read-Host "Выберите опцию"
        
        switch ($choice) {
            "1" { Install-SingleApplication -Id "Discord.Discord" -Name "Discord"; Pause }
            "2" { Install-SingleApplication -Id "Valve.Steam" -Name "Steam"; Pause }
            "3" { Install-SingleApplication -Id "Google.Chrome" -Name "Google Chrome"; Pause }
            "4" { Install-SingleApplication -Id "7zip.7zip" -Name "7-Zip"; Pause }
            "0" { return }
            default {
                Write-Host "Неверный выбор! Попробуйте снова." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

function Exit-GameBooster {
    Clear-Host
    Write-Host "nnn"
    $text = "  Спасибо за использование GameBooster by rage!n  До скорых встреч!"
    foreach ($char in $text.ToCharArray()) {
        Write-Host $char -NoNewline -ForegroundColor Magenta
        Start-Sleep -Milliseconds 40
    }
    Write-Host "n"
    Pause
    exit
}

# === Главное меню ===

function Main-Menu {
    Show-TitleAnimation
    while ($true) {
        Clear-Host
        Write-Host "г============================================¬" -ForegroundColor Cyan
        Write-Host "¦        GameBooster by rage                 ¦" -ForegroundColor Cyan
        Write-Host "L============================================-" -ForegroundColor Cyan
        Write-Host
        Write-Host " [1] Отключить Game DVR" -ForegroundColor Green
        Write-Host " [2] Включить Ultimate Performance" -ForegroundColor Green
        Write-Host " [3] Отключить фоновые приложения" -ForegroundColor Green
        Write-Host " [4] Включить аппаратное ускорение GPU" -ForegroundColor Green
        Write-Host " [5] Уменьшить задержку меню" -ForegroundColor Green
        Write-Host " [6] Оптимизация визуальных эффектов" -ForegroundColor Green
        Write-Host " [7] Отключить телеметрию" -ForegroundColor Green
        Write-Host " [8] Очистка мусора" -ForegroundColor Cyan
        Write-Host " [9] Отключение ненужных служб" -ForegroundColor Cyan
        Write-Host " [10] Информация о системе" -ForegroundColor Blue
        Write-Host " [11] Применить все оптимизации" -ForegroundColor Yellow
        Write-Host " [12] Установка приложений" -ForegroundColor Yellow
        Write-Host " [0] Выход" -ForegroundColor Red
        Write-Host
        $choice = Read-Host "Выберите опцию"
        switch ($choice) {
            "1" { Disable-GameDVR; Pause }
            "2" { Enable-UltimatePerformancePlan; Pause }
            "3" { Disable-BackgroundApps; Pause }
            "4" { Enable-HWAcceleratedGPU; Pause }
            "5" { Reduce-MenuDelay; Pause }
            "6" { Disable-VisualEffects; Pause }
            "7" { Disable-Telemetry; Pause }
            "8" { Clear-JunkFiles; Pause }
            "9" { Disable-UnnecessaryServices; Pause }
            "10" { Show-SystemInfo; Pause }
            "11" { Apply-AllTweaks; Pause }
            "12" { Applications-Menu }
            "0" { Exit-GameBooster }
            default {
                Write-Host "Неверный выбор! Попробуйте снова." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# === Старт ===

Check-Admin
Main-Menu
