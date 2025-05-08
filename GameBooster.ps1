$ScriptVersion = "1.2"
$GitHubUser = "crymory" # Замените на ваше имя пользователя GitHub
$RepoName = "GameBooster"
$BranchName = "main"
$ScriptName = "GameBooster.ps1"

# Установка цветов для вывода
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

# Функция для вывода информации с цветом
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorMessage "Windows 11 Optimizer v$ScriptVersion" $ColorInfo
Write-ColorMessage "-------------------------------------" $ColorInfo

# Проверка запуска от имени администратора
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ColorMessage "Для работы требуются права администратора! Перезапустите скрипт от имени администратора." $ColorError
    Start-Sleep -Seconds 3
    exit
}

# Функция проверки обновлений для EXE-файла
function Check-ForUpdates {
    try {
        Write-ColorMessage "Проверка наличия обновлений..." $ColorInfo
        
        # URL для проверки последней версии скрипта на GitHub
        $VersionFileUrl = "https://raw.githubusercontent.com/$GitHubUser/$RepoName/$BranchName/version.txt"
        
        # Получение версии с GitHub
        $OnlineVersion = (Invoke-WebRequest -Uri $VersionFileUrl -UseBasicParsing).Content.Trim()
        
        if ([version]$OnlineVersion -gt [version]$ScriptVersion) {
            Write-ColorMessage "Доступна новая версия: $OnlineVersion (у вас: $ScriptVersion)" $ColorWarning
            $UpdateChoice = Read-Host "Хотите обновить программу? (Д/Н)"
            
            if ($UpdateChoice -eq "Д" -or $UpdateChoice -eq "д" -or $UpdateChoice -eq "Y" -or $UpdateChoice -eq "y") {
                # Путь для временной загрузки файла
                $ExeDownloadUrl = "https://github.com/$GitHubUser/$RepoName/releases/download/v$OnlineVersion/GameBooster.exe"
                $TempFile = "$env:TEMP\GameBooster_new.exe"
                $CurrentExe = $MyInvocation.MyCommand.Path
                
                # Загрузка новой версии
                Write-ColorMessage "Загрузка обновления..." $ColorInfo
                Invoke-WebRequest -Uri $ExeDownloadUrl -OutFile $TempFile -UseBasicParsing
                
                # Создание скрипта обновления
                $UpdaterScript = @"
Start-Sleep -Seconds 3
Copy-Item -Path "$TempFile" -Destination "$CurrentExe" -Force
Remove-Item -Path "$TempFile" -Force
Start-Process -FilePath "$CurrentExe"
"@
                
                $UpdaterPath = "$env:TEMP\GameBoosterUpdater.ps1"
                $UpdaterScript | Out-File -FilePath $UpdaterPath -Force
                
                # Запуск скрипта обновления, который заменит текущий EXE и запустит его снова
                Write-ColorMessage "Установка обновления. Пожалуйста, подождите..." $ColorInfo
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$UpdaterPath`"" -WindowStyle Hidden
                
                # Выход из текущего процесса
                exit
            }
        } else {
            Write-ColorMessage "У вас установлена последняя версия программы ($ScriptVersion)." $ColorSuccess
        }
    } catch {
        Write-ColorMessage "Ошибка при проверке обновлений: $_" $ColorError
    }
}

# Функция для создания точки восстановления
function Create-RestorePoint {
    Write-ColorMessage "Создание точки восстановления системы..." $ColorInfo
    
    # Проверка, включена ли служба защиты системы
    $SysRestoreStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    
    if ($null -eq $SysRestoreStatus) {
        Write-ColorMessage "Включение службы защиты системы..." $ColorInfo
        Enable-ComputerRestore -Drive "$env:SystemDrive"
    }
    
    # Создание точки восстановления
    Checkpoint-Computer -Description "Win11Optimizer Before Changes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    
    if ($?) {
        Write-ColorMessage "Точка восстановления создана успешно." $ColorSuccess
    } else {
        Write-ColorMessage "Не удалось создать точку восстановления. Продолжаем без неё." $ColorWarning
    }
}

# Функция оптимизации производительности
function Optimize-Performance {
    Write-ColorMessage "`nОптимизация производительности Windows 11..." $ColorInfo
    
    # Отключение лишних визуальных эффектов
    Write-ColorMessage "Настройка визуальных эффектов для повышения производительности..." $ColorInfo
    $VisualFXPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    
    if (-not (Test-Path $VisualFXPath)) {
        New-Item -Path $VisualFXPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $VisualFXPath -Name "VisualFXSetting" -Type DWord -Value 2
    
    # Настройка электропитания на высокую производительность
    Write-ColorMessage "Настройка плана электропитания на Высокую производительность..." $ColorInfo
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    # Отключение фоновых приложений
    Write-ColorMessage "Отключение ненужных фоновых приложений..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type DWord -Value 1
    
    # Отключение индексации для повышения производительности диска
    Write-ColorMessage "Настройка индексации дисков..." $ColorInfo
    $IndexService = Get-Service -Name "WSearch"
    if ($IndexService.Status -eq "Running") {
        Stop-Service "WSearch" -Force
        Set-Service "WSearch" -StartupType Disabled
        Write-ColorMessage "Служба индексации отключена." $ColorSuccess
    } else {
        Write-ColorMessage "Служба индексации уже отключена." $ColorInfo
    }
}

# Функция очистки системы
function Clean-System {
    Write-ColorMessage "`nОчистка системы..." $ColorInfo
    
    # Очистка временных файлов
    Write-ColorMessage "Очистка временных файлов Windows..." $ColorInfo
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Очистка кэша DNS
    Write-ColorMessage "Очистка кэша DNS..." $ColorInfo
    ipconfig /flushdns | Out-Null
    
    # Дефрагментация диска (только для HDD)
    $DriveType = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } | Select-Object -ExpandProperty MediaType
    if ($DriveType -eq "HDD") {
        Write-ColorMessage "Запуск дефрагментации системного диска (это может занять время)..." $ColorInfo
        Optimize-Volume -DriveLetter C -Defrag
    } else {
        Write-ColorMessage "Обнаружен SSD диск. Дефрагментация не требуется." $ColorInfo
    }
    
    # Очистка корзины
    Write-ColorMessage "Очистка корзины..." $ColorInfo
    $Shell = New-Object -ComObject Shell.Application
    $RecycleBin = $Shell.Namespace(0xA)
    $RecycleBin.Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }
    
    # Запуск встроенного средства очистки диска
    Write-ColorMessage "Запуск средства очистки диска Windows..." $ColorInfo
    Start-Process -FilePath cleanmgr.exe -ArgumentList "/sagerun:1" -Wait
}

# Функция отключения телеметрии и улучшения приватности
function Improve-Privacy {
    Write-ColorMessage "`nНастройка приватности и отключение телеметрии..." $ColorInfo
    
    # Выключение сбора данных телеметрии
    Write-ColorMessage "Отключение телеметрии Windows..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    
    # Отключение сервисов сбора данных
    $TelemetryServices = @(
        "DiagTrack",
        "dmwappushservice",
        "diagnosticshub.standardcollector.service"
    )
    
    foreach ($Service in $TelemetryServices) {
        $ServiceObj = Get-Service -Name $Service -ErrorAction SilentlyContinue
        if ($ServiceObj) {
            Stop-Service -Name $Service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $Service -StartupType Disabled
            Write-ColorMessage "Служба $Service отключена." $ColorSuccess
        }
    }
    
    # Отключение задач сбора данных в планировщике
    Write-ColorMessage "Отключение задач телеметрии в планировщике..." $ColorInfo
    $TelemetryTasks = @(
        "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
        "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
        "\Microsoft\Windows\Autochk\Proxy",
        "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
        "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
        "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    )
    
    foreach ($Task in $TelemetryTasks) {
        Disable-ScheduledTask -TaskPath $Task -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Отключение рекламного ID
    Write-ColorMessage "Отключение рекламного ID..." $ColorInfo
    $AdvertisingIdPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    if (-not (Test-Path $AdvertisingIdPath)) {
        New-Item -Path $AdvertisingIdPath -Force | Out-Null
    }
    Set-ItemProperty -Path $AdvertisingIdPath -Name "Enabled" -Type DWord -Value 0
}

# Функция оптимизации автозагрузки
function Optimize-Startup {
    Write-ColorMessage "`nОптимизация автозагрузки Windows..." $ColorInfo
    
    # Вывести список программ в автозагрузке
    Write-ColorMessage "Список программ в автозагрузке:" $ColorInfo
    
    $StartupItems = Get-CimInstance -ClassName Win32_StartupCommand | 
        Select-Object Name, Command, Location, User |
        Format-Table -AutoSize
    
    $StartupItems | Out-Host
    
    # Предложить отключение отдельных элементов автозагрузки
    Write-ColorMessage "Хотите отключить элементы из автозагрузки? (Д/Н)" $ColorWarning
    $OptimizeStartupChoice = Read-Host
    
    if ($OptimizeStartupChoice -eq "Д" -or $OptimizeStartupChoice -eq "д" -or $OptimizeStartupChoice -eq "Y" -or $OptimizeStartupChoice -eq "y") {
        Write-ColorMessage "Для отключения элементов автозагрузки будет запущен msconfig." $ColorInfo
        Write-ColorMessage "Перейдите во вкладку 'Автозагрузка' или 'Службы', чтобы управлять элементами." $ColorInfo
        Start-Process -FilePath msconfig.exe
    }
}

# Функция отключения ненужных служб
function Optimize-Services {
    Write-ColorMessage "`nОптимизация служб Windows..." $ColorInfo
    
    # Список служб, которые можно безопасно отключить для повышения производительности
    $ServicesToDisable = @(
        # Список служб, которые можно отключить
        @{Name = "SysMain"; DisplayName = "Superfetch"; Description = "Предварительная загрузка приложений в память"},
        @{Name = "MapsBroker"; DisplayName = "Диспетчер загруженных карт"; Description = "Скачивание карт"},
        @{Name = "lfsvc"; DisplayName = "Служба определения расположения"; Description = "Геолокационные сервисы"},
        @{Name = "XblGameSave"; DisplayName = "Сохранение игр Xbox Live"; Description = "Синхронизация сохранений Xbox"},
        @{Name = "XblAuthManager"; DisplayName = "Диспетчер проверки подлинности Xbox Live"; Description = "Аутентификация Xbox Live"},
        @{Name = "RetailDemo"; DisplayName = "Демонстрационный режим для розничной продажи"; Description = "Демонстрационный режим"}
    )
    
    # Вывод списка служб с описанием
    Write-ColorMessage "Список служб, которые можно отключить для повышения производительности:" $ColorInfo
    
    $i = 1
    foreach ($Service in $ServicesToDisable) {
        Write-ColorMessage "$i. $($Service.DisplayName) ($($Service.Name)) - $($Service.Description)" $ColorInfo
        $i++
    }
    
    # Спросить пользователя, какие службы отключать
    Write-ColorMessage "`nВведите номера служб, которые нужно отключить (через запятую), или 'всё' для отключения всех служб:" $ColorWarning
    $ServiceChoice = Read-Host
    
    # Обработка выбора пользователя
    if ($ServiceChoice -eq "всё" -or $ServiceChoice -eq "все") {
        foreach ($Service in $ServicesToDisable) {
            $ServiceObj = Get-Service -Name $Service.Name -ErrorAction SilentlyContinue
            if ($ServiceObj) {
                Stop-Service -Name $Service.Name -Force -ErrorAction SilentlyContinue
                Set-Service -Name $Service.Name -StartupType Disabled
                Write-ColorMessage "Служба $($Service.DisplayName) отключена." $ColorSuccess
            }
        }
    } else {
        $SelectedServices = $ServiceChoice -split "," | ForEach-Object { $_.Trim() }
        
        foreach ($Selection in $SelectedServices) {
            if ([int]::TryParse($Selection, [ref]$null)) {
                $Index = [int]$Selection - 1
                
                if ($Index -ge 0 -and $Index -lt $ServicesToDisable.Count) {
                    $ServiceToDisable = $ServicesToDisable[$Index]
                    $ServiceObj = Get-Service -Name $ServiceToDisable.Name -ErrorAction SilentlyContinue
                    
                    if ($ServiceObj) {
                        Stop-Service -Name $ServiceToDisable.Name -Force -ErrorAction SilentlyContinue
                        Set-Service -Name $ServiceToDisable.Name -StartupType Disabled
                        Write-ColorMessage "Служба $($ServiceToDisable.DisplayName) отключена." $ColorSuccess
                    }
                }
            }
        }
    }
}

# Функция настройки реестра для оптимизации системы
function Optimize-Registry {
    Write-ColorMessage "`nОптимизация реестра Windows..." $ColorInfo
    
    # Ускорение запуска приложений
    Write-ColorMessage "Оптимизация запуска приложений..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Type DWord -Value 3
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Type DWord -Value 0
    
    # Оптимизация кэширования файловой системы
    Write-ColorMessage "Оптимизация кэширования файловой системы..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Type DWord -Value 1
    
    # Ускорение меню
    Write-ColorMessage "Ускорение отклика меню..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0"
    
    # Отключение анимации
    Write-ColorMessage "Настройка анимации для повышения производительности..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value "0"
    
    # Отключение эффекта прозрачности
    Write-ColorMessage "Отключение эффекта прозрачности..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Type DWord -Value 0
    
    # Ускорение выключения системы
    Write-ColorMessage "Оптимизация времени выключения системы..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type String -Value "2000"
}

# Главное меню
function Show-Menu {
    Clear-Host
    Write-ColorMessage "Windows 11 Optimizer v$ScriptVersion" $ColorInfo
    Write-ColorMessage "-------------------------------------" $ColorInfo
    Write-ColorMessage "Выберите действие:" $ColorInfo
    Write-ColorMessage "1. Запустить все оптимизации" $ColorInfo
    Write-ColorMessage "2. Оптимизация производительности" $ColorInfo
    Write-ColorMessage "3. Очистка системы" $ColorInfo
    Write-ColorMessage "4. Настройка приватности" $ColorInfo
    Write-ColorMessage "5. Оптимизация автозагрузки" $ColorInfo
    Write-ColorMessage "6. Оптимизация служб" $ColorInfo
    Write-ColorMessage "7. Оптимизация реестра" $ColorInfo
    Write-ColorMessage "8. Проверить наличие обновлений" $ColorInfo
    Write-ColorMessage "9. Создать точку восстановления" $ColorInfo
    Write-ColorMessage "0. Выход" $ColorInfo
    Write-ColorMessage "-------------------------------------" $ColorInfo
    
    $Choice = Read-Host "Введите номер"
    
    switch ($Choice) {
        "1" {
            Create-RestorePoint
            Optimize-Performance
            Clean-System
            Improve-Privacy
            Optimize-Startup
            Optimize-Services
            Optimize-Registry
            Write-ColorMessage "`nВсе оптимизации выполнены успешно!" $ColorSuccess
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "2" {
            Optimize-Performance
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "3" {
            Clean-System
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "4" {
            Improve-Privacy
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "5" {
            Optimize-Startup
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "6" {
            Optimize-Services
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "7" {
            Optimize-Registry
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "8" {
            Check-ForUpdates
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "9" {
            Create-RestorePoint
            Read-Host "Нажмите Enter для возврата в меню"
            Show-Menu
        }
        "0" {
            Write-ColorMessage "Выход из программы..." $ColorInfo
            exit
        }
        default {
            Write-ColorMessage "Неверный выбор. Попробуйте снова." $ColorWarning
            Start-Sleep -Seconds 2
            Show-Menu
        }
    }
}

# Проверка обновлений при запуске
Check-ForUpdates

# Запуск главного меню
Show-Menu
