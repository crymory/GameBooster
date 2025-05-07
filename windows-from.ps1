Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# === Global Variables ===
$global:isAdmin = $false
$global:hasWinget = $false

# === Utility Functions ===
function Check-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Check-Winget {
    return (Get-Command winget -ErrorAction SilentlyContinue) -ne $null
}

function Show-Progress {
    param (
        [string]$Activity,
        [int]$DurationMs
    )
    
    $progressBar.Maximum = 100
    $progressBar.Value = 0
    $statusLabel.Text = $Activity
    
    $steps = 20
    $delay = $DurationMs / $steps
    $stepSize = 100 / $steps
    
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = $delay
    
    $currentStep = 0
    $timer.Add_Tick({
        $currentStep++
        if ($currentStep -le $steps) {
            $progressBar.Value = [Math]::Min([int]($currentStep * $stepSize), 100)
            $statusLabel.Text = "$Activity - $([int]($currentStep * $stepSize))%"
            $form.Refresh()
        } else {
            $timer.Stop()
            $timer.Dispose()
            $progressBar.Value = 100
            $statusLabel.Text = "Готово!"
            $form.Refresh()
        }
    })
    
    $timer.Start()
    
    # Wait for the timer to complete
    while ($progressBar.Value -lt 100) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 10
    }
    
    Start-Sleep -Milliseconds 500
    $progressBar.Value = 0
    $statusLabel.Text = "GameBooster by rage"
}

function Execute-WithProgress {
    param (
        [string]$ActivityText,
        [int]$DurationMs,
        [scriptblock]$ScriptBlock
    )
    
    # Update status
    $statusLabel.Text = $ActivityText
    $form.Refresh()
    
    # Start progress bar animation
    Show-Progress -Activity $ActivityText -DurationMs $DurationMs
    
    # Execute the actual function
    try {
        & $ScriptBlock
        Add-Log -Text "$ActivityText - Успешно" -Color "Green"
    }
    catch {
        Add-Log -Text "$ActivityText - Ошибка: $_" -Color "Red"
    }
}

function Add-Log {
    param (
        [string]$Text,
        [string]$Color = "Black"
    )
    
    $logTextBox.SelectionStart = $logTextBox.TextLength
    $logTextBox.SelectionLength = 0
    $logTextBox.SelectionColor = [System.Drawing.Color]::FromName($Color)
    $logTextBox.AppendText("$(Get-Date -Format 'HH:mm:ss') - $Text`r`n")
    $logTextBox.ScrollToCaret()
}

# === Optimization Functions ===
function Disable-GameDVR {
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
}

function Enable-UltimatePerformancePlan {
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
}

function Disable-BackgroundApps {
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if (Test-Path $path) {
        Set-ItemProperty -Path $path -Name "GlobalUserDisabled" -Value 1 -ErrorAction SilentlyContinue
    }
}

function Enable-HWAcceleratedGPU {
    $path = "HKCU:\Software\Microsoft\Avalon.Graphics"
    if (-not (Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    Set-ItemProperty -Path $path -Name "DisableHWAcceleration" -Value 0 -Force
}

function Reduce-MenuDelay {
    $path = "HKCU:\Control Panel\Desktop"
    if (Test-Path $path) {
        Set-ItemProperty -Path $path -Name "MenuShowDelay" -Value 0
    }
}

function Disable-VisualEffects {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2
    }
}

function Disable-Telemetry {
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
}

function Clear-JunkFiles {
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
                    Add-Log -Text "Невозможно удалить: $($item.FullName)" -Color "DarkYellow"
                }
            }
        }
        else {
            Add-Log -Text "Путь не существует: $path" -Color "DarkYellow"
        }
    }
}

function Disable-UnnecessaryServices {
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
}

function Install-SingleApplication {
    param (
        [string]$Id,
        [string]$Name
    )
    try {
        winget install --id $Id --silent --accept-package-agreements --accept-source-agreements -e
        Add-Log -Text "$Name успешно установлен!" -Color "Green"
    }
    catch {
        Add-Log -Text "Ошибка при установке $Name: $_" -Color "Red"
    }
}

function Apply-AllTweaks {
    Execute-WithProgress -ActivityText "Отключение GameDVR" -DurationMs 2500 -ScriptBlock { Disable-GameDVR }
    Execute-WithProgress -ActivityText "Включение Ultimate Performance" -DurationMs 2500 -ScriptBlock { Enable-UltimatePerformancePlan }
    Execute-WithProgress -ActivityText "Отключение фоновых приложений" -DurationMs 2500 -ScriptBlock { Disable-BackgroundApps }
    Execute-WithProgress -ActivityText "Включение аппаратного ускорения GPU" -DurationMs 2500 -ScriptBlock { Enable-HWAcceleratedGPU }
    Execute-WithProgress -ActivityText "Уменьшение задержки меню" -DurationMs 2500 -ScriptBlock { Reduce-MenuDelay }
    Execute-WithProgress -ActivityText "Оптимизация визуальных эффектов" -DurationMs 2500 -ScriptBlock { Disable-VisualEffects }
    Execute-WithProgress -ActivityText "Отключение телеметрии Microsoft" -DurationMs 3500 -ScriptBlock { Disable-Telemetry }
    Execute-WithProgress -ActivityText "Отключение ненужных служб" -DurationMs 3000 -ScriptBlock { Disable-UnnecessaryServices }
    
    Add-Log -Text "Все оптимизации успешно применены!" -Color "Green"
}

function Check-SystemOptimization {
    $statusLabel.Text = "Проверка оптимизации системы..."
    $form.Refresh()
    
    # Список служб и параметров для проверки
    $totalChecks = 8
    $passedChecks = 0
    
    # 1. Проверка GameDVR
    $gameDvrPath1 = "HKCU:\System\GameConfigStore"
    $gameDvrPath2 = "HKCU:\Software\Microsoft\GameBar"
    
    $gameDvrDisabled = $true
    
    if ((Test-Path $gameDvrPath1) -and 
        ((Get-ItemProperty -Path $gameDvrPath1 -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue).GameDVR_Enabled -ne 0)) {
        $gameDvrDisabled = $false
    }
    
    if ((Test-Path $gameDvrPath2) -and 
        ((Get-ItemProperty -Path $gameDvrPath2 -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue).GameDVR_Enabled -ne 0)) {
        $gameDvrDisabled = $false
    }
    
    if ($gameDvrDisabled) {
        Add-Log -Text "GameDVR: ОТКЛЮЧЕН" -Color "Green"
        $passedChecks++
    } else {
        Add-Log -Text "GameDVR: ВКЛЮЧЕН" -Color "Red"
    }
    
    # 2. Проверка схемы электропитания
    $powerPlan = powercfg /GetActiveScheme
    if ($powerPlan -like "*e9a42b02-d5df-448d-aa00-03f14749eb61*") {
        Add-Log -Text "Ultimate Performance: ВКЛЮЧЕН" -Color "Green"
        $passedChecks++
    } else {
        Add-Log -Text "Ultimate Performance: ОТКЛЮЧЕН" -Color "Red"
    }
    
    # 3. Проверка фоновых приложений
    $backgroundAppsPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if ((Test-Path $backgroundAppsPath) -and 
        ((Get-ItemProperty -Path $backgroundAppsPath -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue).GlobalUserDisabled -eq 1)) {
        Add-Log -Text "Фоновые приложения: ОТКЛЮЧЕНЫ" -Color "Green"
        $passedChecks++
    } else {
        Add-Log -Text "Фоновые приложения: ВКЛЮЧЕНЫ" -Color "Red"
    }
    
    # 4. Проверка аппаратного ускорения GPU
    $hwAccPath = "HKCU:\Software\Microsoft\Avalon.Graphics"
    if ((Test-Path $hwAccPath) -and 
        ((Get-ItemProperty -Path $hwAccPath -Name "DisableHWAcceleration" -ErrorAction SilentlyContinue).DisableHWAcceleration -eq 0)) {
        Add-Log -Text "Аппаратное ускорение GPU: ВКЛЮЧЕНО" -Color "Green"
        $passedChecks++
    } else {
        Add-Log -Text "Аппаратное ускорение GPU: ОТКЛЮЧЕНО" -Color "Red"
    }
    
    # 5. Проверка задержки меню
    $menuDelayPath = "HKCU:\Control Panel\Desktop"
    if ((Test-Path $menuDelayPath) -and 
        ((Get-ItemProperty -Path $menuDelayPath -Name "MenuShowDelay" -ErrorAction SilentlyContinue).MenuShowDelay -eq 0)) {
        Add-Log -Text "Задержка меню: ОПТИМИЗИРОВАНО" -Color "Green"
        $passedChecks++
    } else {
        Add-Log -Text "Задержка меню: НЕ ОПТИМИЗИРОВАНО" -Color "Red"
    }
    
    # 6. Проверка визуальных эффектов
    $visualFxPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if ((Test-Path $visualFxPath) -and 
        ((Get-ItemProperty -Path $visualFxPath -Name "VisualFXSetting" -ErrorAction SilentlyContinue).VisualFXSetting -eq 2)) {
        Add-Log -Text "Визуальные эффекты: ОПТИМИЗИРОВАНО" -Color "Green"
        $passedChecks++
    } else {
        Add-Log -Text "Визуальные эффекты: НЕ ОПТИМИЗИРОВАНО" -Color "Red"
    }
    
    # 7. Проверка телеметрии
    $telemetryServices = @("DiagTrack", "dmwappushservice")
    $telemetryDisabled = $true
    
    foreach ($service in $telemetryServices) {
        $serviceObj = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($serviceObj -and ($serviceObj.Status -ne 'Stopped' -or $serviceObj.StartType -ne 'Disabled')) {
            $telemetryDisabled = $false
        }
    }
    
    if ($telemetryDisabled) {
        Add-Log -Text "Телеметрия: ОТКЛЮЧЕНА" -Color "Green"
        $passedChecks++
    } else {
        Add-Log -Text "Телеметрия: ВКЛЮЧЕНА" -Color "Red"
    }
    
    # 8. Проверка ненужных служб
    $unnecessaryServices = @("Fax", "XblGameSave", "WMPNetworkSvc")
    $servicesDisabled = $true
    
    foreach ($service in $unnecessaryServices) {
        $serviceObj = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($serviceObj -and ($serviceObj.Status -ne 'Stopped' -or $serviceObj.StartType -ne 'Disabled')) {
            $servicesDisabled = $false
        }
    }
    
    if ($servicesDisabled) {
        Add-Log -Text "Ненужные службы: ОТКЛЮЧЕНЫ" -Color "Green"
        $passedChecks++
    } else {
        Add-Log -Text "Ненужные службы: ВКЛЮЧЕНЫ" -Color "Red"
    }
    
    # Расчет процента оптимизации
    $optimizationPercent = [math]::Round(($passedChecks / $totalChecks) * 100)
    
    # Определение цвета в зависимости от процента
    if ($optimizationPercent -ge 80) {
        $color = "Green"  # Зеленый для хорошей оптимизации
    } elseif ($optimizationPercent -ge 50) {
        $color = "Yellow"  # Желтый для средней оптимизации
    } else {
        $color = "Red"  # Красный для плохой оптимизации
    }
    
    Add-Log -Text "Общий процент оптимизации системы: $optimizationPercent%" -Color $color
    
    # Рекомендации на основе результатов
    if ($optimizationPercent -lt 100) {
        Add-Log -Text "Рекомендация: Выполните 'Применить все оптимизации' для полной оптимизации системы" -Color "Yellow"
    } else {
        Add-Log -Text "Ваша система полностью оптимизирована для игр!" -Color "Green"
    }
    
    $statusLabel.Text = "GameBooster by rage"
}

function Show-SystemInfo {
    $statusLabel.Text = "Получение информации о системе..."
    $form.Refresh()
    
    Add-Log -Text "=== ИНФОРМАЦИЯ О СИСТЕМЕ ===" -Color "Blue"
    
    try {
        $sysinfo = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, OSArchitecture
        $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, MaxClockSpeed
        $gpu = Get-CimInstance -ClassName Win32_VideoController | Select-Object Name, VideoModeDescription, DriverVersion
        $ram = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'" | Select-Object DeviceID, Size, FreeSpace
        
        Add-Log -Text "ОС: $($sysinfo.Caption) $($sysinfo.Version) $($sysinfo.OSArchitecture)" -Color "DarkBlue"
        Add-Log -Text "Процессор: $($cpu.Name)" -Color "DarkBlue"
        Add-Log -Text "Ядра: $($cpu.NumberOfCores), Частота: $([Math]::Round($cpu.MaxClockSpeed/1000, 2)) ГГц" -Color "DarkBlue"
        Add-Log -Text "Видеокарта: $($gpu.Name)" -Color "DarkBlue"
        Add-Log -Text "Разрешение: $($gpu.VideoModeDescription)" -Color "DarkBlue"
        Add-Log -Text "Версия драйвера: $($gpu.DriverVersion)" -Color "DarkBlue"
        Add-Log -Text "Оперативная память: $([Math]::Round($ram.Sum / 1GB, 2)) ГБ" -Color "DarkBlue"
        Add-Log -Text "Диск C: Всего: $([Math]::Round($disk.Size / 1GB, 2)) ГБ, Свободно: $([Math]::Round($disk.FreeSpace / 1GB, 2)) ГБ" -Color "DarkBlue"
    }
    catch {
        Add-Log -Text "Ошибка при получении информации о системе: $_" -Color "Red"
    }
    
    $statusLabel.Text = "GameBooster by rage"
}

function Show-AboutInfo {
    [System.Windows.Forms.MessageBox]::Show(
        "GameBooster by rage`n`nВерсия: 1.0`n`nПрограмма для оптимизации Windows для игр",
        "О программе",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

# === GUI Setup ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "GameBooster by rage"
$form.Size = New-Object System.Drawing.Size(800, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Windows.Forms.Application]::ExecutablePath)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false

# Status Bar
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "GameBooster by rage"
$statusStrip.Items.Add($statusLabel)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ToolStripProgressBar
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$statusStrip.Items.Add($progressBar)

# Title Panel
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Dock = [System.Windows.Forms.DockStyle]::Top
$titlePanel.Height = 60
$titlePanel.BackColor = [System.Drawing.Color]::FromArgb(44, 62, 80)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "GameBooster by rage"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(20, 15)
$titlePanel.Controls.Add($titleLabel)

# Tab Control
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Dock = [System.Windows.Forms.DockStyle]::Fill
$tabControl.Appearance = [System.Windows.Forms.TabAppearance]::FlatButtons
$tabControl.Padding = New-Object System.Drawing.Point(6, 8)
$tabControl.Font = New-Object System.Drawing.Font("Segoe UI", 10)

# Tab 1: Optimization
$tabOptimization = New-Object System.Windows.Forms.TabPage
$tabOptimization.Text = "Оптимизация"
$tabOptimization.Padding = New-Object System.Windows.Forms.Padding(10)

$optimizationPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$optimizationPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$optimizationPanel.Height = 240
$optimizationPanel.AutoScroll = $true
$optimizationPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
$optimizationPanel.WrapContents = $true

# Create optimization buttons
$buttonConfigs = @(
    @{Text="Отключить Game DVR"; Action={Execute-WithProgress -ActivityText "Отключение GameDVR" -DurationMs 2500 -ScriptBlock { Disable-GameDVR }}},
    @{Text="Включить Ultimate Performance"; Action={Execute-WithProgress -ActivityText "Включение Ultimate Performance" -DurationMs 2500 -ScriptBlock { Enable-UltimatePerformancePlan }}},
    @{Text="Отключить фоновые приложения"; Action={Execute-WithProgress -ActivityText "Отключение фоновых приложений" -DurationMs 2500 -ScriptBlock { Disable-BackgroundApps }}},
    @{Text="Включить ускорение GPU"; Action={Execute-WithProgress -ActivityText "Включение аппаратного ускорения GPU" -DurationMs 2500 -ScriptBlock { Enable-HWAcceleratedGPU }}},
    @{Text="Уменьшить задержку меню"; Action={Execute-WithProgress -ActivityText "Уменьшение задержки меню" -DurationMs 2500 -ScriptBlock { Reduce-MenuDelay }}},
    @{Text="Оптимизировать визуальные эффекты"; Action={Execute-WithProgress -ActivityText "Оптимизация визуальных эффектов" -DurationMs 2500 -ScriptBlock { Disable-VisualEffects }}},
    @{Text="Отключить телеметрию"; Action={Execute-WithProgress -ActivityText "Отключение телеметрии Microsoft" -DurationMs 3500 -ScriptBlock { Disable-Telemetry }}},
    @{Text="Отключить ненужные службы"; Action={Execute-WithProgress -ActivityText "Отключение ненужных служб" -DurationMs 3000 -ScriptBlock { Disable-UnnecessaryServices }}},
    @{Text="Очистка мусора"; Action={Execute-WithProgress -ActivityText "Очистка временных файлов" -DurationMs 3000 -ScriptBlock { Clear-JunkFiles }}}
)

foreach ($config in $buttonConfigs) {
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $config.Text
    $button.Width = 230
    $button.Height = 40
    $button.Margin = New-Object System.Windows.Forms.Padding(10)
    $button.BackColor = [System.Drawing.Color]::FromArgb(26, 188, 156)
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.Add_Click($config.Action)
    $optimizationPanel.Controls.Add($button)
}

# Apply All Tweaks Button
$allOptimizePanel = New-Object System.Windows.Forms.Panel
$allOptimizePanel.Dock = [System.Windows.Forms.DockStyle]::Top
$allOptimizePanel.Height = 70
$allOptimizePanel.Padding = New-Object System.Windows.Forms.Padding(10)

$allOptimizeButton = New-Object System.Windows.Forms.Button
$allOptimizeButton.Text = "Применить все оптимизации"
$allOptimizeButton.Dock = [System.Windows.Forms.DockStyle]::Fill
$allOptimizeButton.BackColor = [System.Drawing.Color]::FromArgb(241, 196, 15)
$allOptimizeButton.ForeColor = [System.Drawing.Color]::White
$allOptimizeButton.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$allOptimizeButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$allOptimizeButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$allOptimizeButton.Add_Click({ Apply-AllTweaks })
$allOptimizePanel.Controls.Add($allOptimizeButton)

# Log Panel
$logPanel = New-Object System.Windows.Forms.Panel
$logPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$logPanel.Padding = New-Object System.Windows.Forms.Padding(10)

$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "Журнал операций:"
$logLabel.Dock = [System.Windows.Forms.DockStyle]::Top
$logLabel.Height = 25
$logLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$logPanel.Controls.Add($logLabel)

$logTextBox = New-Object System.Windows.Forms.RichTextBox
$logTextBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$logTextBox.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$logTextBox.ReadOnly = $true
$logTextBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logPanel.Controls.Add($logTextBox)

# Tab 2: Applications
$tabApplications = New-Object System.Windows.Forms.TabPage
$tabApplications.Text = "Приложения"
$tabApplications.Padding = New-Object System.Windows.Forms.Padding(10)

$appsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$appsPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$appsPanel.AutoScroll = $true
$appsPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
$appsPanel.WrapContents = $true
$appsPanel.Padding = New-Object System.Windows.Forms.Padding(20)

# Create application buttons
$appConfigs = @(
    @{Text="Discord"; Icon="🎮"; Id="Discord.Discord"},
    @{Text="Steam"; Icon="🎲"; Id="Valve.Steam"},
    @{Text="Google Chrome"; Icon="🌐"; Id="Google.Chrome"},
    @{Text="7-Zip"; Icon="📦"; Id="7zip.7zip"},
    @{Text="VLC Media Player"; Icon="🎬"; Id="VideoLAN.VLC"},
    @{Text="Notepad++"; Icon="📝"; Id="Notepad++.Notepad++"},
    @{Text="Mozilla Firefox"; Icon="🦊"; Id="Mozilla.Firefox"},
    @{Text="OBS Studio"; Icon="📹"; Id="OBS.OBSStudio"},
    @{Text="TeamSpeak"; Icon="🎧"; Id="TeamSpeakSystems.TeamSpeakClient"},
    @{Text="Epic Games"; Icon="🎯"; Id="EpicGames.EpicGamesLauncher"},
    @{Text="Visual Studio Code"; Icon="💻"; Id="Microsoft.VisualStudioCode"},
    @{Text="uTorrent"; Icon="📥"; Id="BitTorrent.uTorrent"}
)

foreach ($app in $appConfigs) {
    $appCard = New-Object System.Windows.Forms.Panel
    $appCard.Width = 200
    $appCard.Height = 100
    $appCard.BackColor = [System.Drawing.Color]::White
    $appCard.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $appCard.Margin = New-Object System.Windows.Forms.Padding(15)
    
    $iconLabel = New-Object System.Windows.Forms.Label
    $iconLabel.Text = $app.Icon
    $iconLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 24)
    $iconLabel.AutoSize = $true
    $iconLabel.Location = New-Object System.Drawing.Point(80, 10)
    $appCard.Controls.Add($iconLabel)
    
    $nameLabel = New-Object System.Windows.Forms.Label
    $nameLabel.Text = $app.Text
    $nameLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $nameLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $nameLabel.Width = 200
    $nameLabel.Location = New-Object System.Drawing.Point(0, 50)
    $appCard.Controls.Add($nameLabel)
    
    $installButton = New-Object System.Windows.Forms.Button
    $installButton.Text = "Установить"
    $installButton.Width = 120
    $installButton.Height = 25
    $installButton.Location = New-Object System.Drawing.Point(40, 70)
    $installButton.BackColor = [System.Drawing.Color]::FromArgb(52, 152, 219)
    $installButton.ForeColor = [System.Drawing.Color]::White
    $installButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $installButton.Cursor = [System.Windows.Forms.Cursors]::Hand
    $installButton.Tag = $app
    $installButton.Add_Click({
        $appInfo = $this.Tag
        Execute-WithProgress -ActivityText "Установка $($appInfo.Text)" -DurationMs 2000 -ScriptBlock { 
            Install-SingleApplication -Id $appInfo.Id -Name $appInfo.Text 
        }
    })
    $appCard.Controls.Add($installButton)
    
    $appsPanel.Controls.Add($appCard)
}

# Tab 3: System
$tabSystem = New-Object System.Windows.Forms.TabPage
$tabSystem.Text = "System"
$tabSystem.Padding = New-Object System.Windows.Forms.Padding(10)

$systemPanel = New-Object System.Windows.Forms.Panel
$systemPanel.Dock = [System.Windows.Forms.DockStyle]::Fill

# System buttons
$btnCheckOptimization = New-Object System.Windows.Forms.Button
$btnCheckOptimization.Text = "Проверить оптимизацию системы"
$btnCheckOptimization.Width = 300
$btnCheckOptimization.Height = 50
$btnCheckOptimization.Location = New-Object System.Drawing.Point(200, 40)
$btnCheckOptimization.BackColor = [System.Drawing.Color]::FromArgb(142, 68, 173)
$btnCheckOptimization.ForeColor = [System.Drawing.Color]::White
$btnCheckOptimization.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnCheckOptimization.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckOptimization.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnCheckOptimization.Add_Click({ Check-SystemOptimization })
$systemPanel.Controls.Add($btnCheckOptimization)

$btnSystemInfo = New-Object System.Windows.Forms.Button
$btnSystemInfo.Text = "Информация о системе"
$btnSystemInfo.Width = 300
$btnSystemInfo.Height = 50
$btnSystemInfo.Location = New-Object System.Drawing.Point(200, 110)
$btnSystemInfo.BackColor = [System.Drawing.Color]::FromArgb(52, 152, 219)
$btnSystemInfo.ForeColor = [System.Drawing.Color]::White
$btnSystemInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$btnSystemInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSystemInfo.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnSystemInfo.Add_Click({ Show-SystemInfo })
$systemPanel.Controls.Add($btnSystemInfo)

# System Logo and Info
$systemLogoPanel = New-Object System.Windows.Forms.Panel
$systemLogoPanel.Width = 700
$systemLogoPanel.Height = 200
$systemLogoPanel.Location = New-Object System.Drawing.Point(50, 220)
$systemLogoPanel.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 245)
$systemLogoPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

$logoLabel = New-Object System.Windows.Forms.Label
$logoLabel.Text = "🚀"
$logoLabel.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 48)
$logoLabel.AutoSize = $true
$logoLabel.Location = New-Object System.Drawing.Point(30, 50)
$systemLogoPanel.Controls.Add($logoLabel)

$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "GameBooster by rage`n`nОптимизируйте вашу систему для максимальной производительности в играх!`n`nПроверьте статус оптимизации и получите рекомендации по улучшению."
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
$infoLabel.Width = 500
$infoLabel.Height = 140
$infoLabel.Location = New-Object System.Drawing.Point(150, 30)
$systemLogoPanel.Controls.Add($infoLabel)

$systemPanel.Controls.Add($systemLogoPanel)

# Add tabs to control
$tabControl.Controls.Add($tabOptimization)
$tabControl.Controls.Add($tabApplications)
$tabControl.Controls.Add($tabSystem)

# Add panels to optimization tab
$tabOptimization.Controls.Add($logPanel)
$tabOptimization.Controls.Add($allOptimizePanel)
$tabOptimization.Controls.Add($optimizationPanel)

# Add panels to applications tab
$tabApplications.Controls.Add($appsPanel)

# Add panels to system tab
$tabSystem.Controls.Add($systemPanel)

# Menu Strip
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(44, 62, 80)
$menuStrip.ForeColor = [System.Drawing.Color]::White

$fileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "Файл"
$fileMenu.ForeColor = [System.Drawing.Color]::White

$exitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$exitMenuItem.Text = "Выход"
$exitMenuItem.Add_Click({ $form.Close() })
$fileMenu.DropDownItems.Add($exitMenuItem)

$helpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$helpMenu.Text = "Справка"
$helpMenu.ForeColor = [System.Drawing.Color]::White

$aboutMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$aboutMenuItem.Text = "О программе"
$aboutMenuItem.Add_Click({ Show-AboutInfo })
$helpMenu.DropDownItems.Add($aboutMenuItem)

$menuStrip.Items.Add($fileMenu)
$menuStrip.Items.Add($helpMenu)

# Add controls to form
$form.Controls.Add($tabControl)
$form.Controls.Add($titlePanel)
$form.Controls.Add($menuStrip)
$form.Controls.Add($statusStrip)
$form.MainMenuStrip = $menuStrip

# === Startup ===

# Check Admin Rights
$global:isAdmin = Check-Admin
if (-not $global:isAdmin) {
    [System.Windows.Forms.MessageBox]::Show(
        "Для правильной работы программы требуются права администратора.`n`nПожалуйста, запустите программу от имени администратора.",
        "Требуются права администратора",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
}

# Check Winget
$global:hasWinget = Check-Winget
if (-not $global:hasWinget) {
    [System.Windows.Forms.MessageBox]::Show(
        "Winget не обнаружен в системе.`n`nДля установки приложений через вкладку 'Приложения', установите App Installer из Microsoft Store.",
        "Winget не найден",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}

# Welcome message
Add-Log -Text "Добро пожаловать в GameBooster by rage!" -Color "Green"
Add-Log -Text "Выберите действие для оптимизации вашей системы." -Color "Blue"

if (-not $global:isAdmin) {
    Add-Log -Text "ВНИМАНИЕ: Программа запущена без прав администратора. Некоторые функции могут быть недоступны." -Color "Red"
}

# Start the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
