$ScriptVersion = "1.1"
$GitHubUser = "crymory" # Çàìåíèòå íà âàøå èìÿ ïîëüçîâàòåëÿ GitHub
$RepoName = "GameBooster"
$BranchName = "main"
$ScriptName = "GameBooster.ps1"

# Óñòàíîâêà öâåòîâ äëÿ âûâîäà
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

# Ôóíêöèÿ äëÿ âûâîäà èíôîðìàöèè ñ öâåòîì
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorMessage "Windows 11 Optimizer v$ScriptVersion" $ColorInfo
Write-ColorMessage "-------------------------------------" $ColorInfo

# Ïðîâåðêà çàïóñêà îò èìåíè àäìèíèñòðàòîðà
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ColorMessage "Äëÿ ðàáîòû òðåáóþòñÿ ïðàâà àäìèíèñòðàòîðà! Ïåðåçàïóñòèòå ñêðèïò îò èìåíè àäìèíèñòðàòîðà." $ColorError
    Start-Sleep -Seconds 3
    exit
}

# Ôóíêöèÿ ïðîâåðêè îáíîâëåíèé äëÿ EXE-ôàéëà
function Check-ForUpdates {
    try {
        Write-ColorMessage "Ïðîâåðêà íàëè÷èÿ îáíîâëåíèé..." $ColorInfo
        
        # URL äëÿ ïðîâåðêè ïîñëåäíåé âåðñèè ñêðèïòà íà GitHub
        $VersionFileUrl = "https://raw.githubusercontent.com/$GitHubUser/$RepoName/$BranchName/version.txt"
        
        # Ïîëó÷åíèå âåðñèè ñ GitHub
        $OnlineVersion = (Invoke-WebRequest -Uri $VersionFileUrl -UseBasicParsing).Content.Trim()
        
        if ([version]$OnlineVersion -gt [version]$ScriptVersion) {
            Write-ColorMessage "Äîñòóïíà íîâàÿ âåðñèÿ: $OnlineVersion (ó âàñ: $ScriptVersion)" $ColorWarning
            $UpdateChoice = Read-Host "Õîòèòå îáíîâèòü ïðîãðàììó? (Ä/Í)"
            
            if ($UpdateChoice -eq "Ä" -or $UpdateChoice -eq "ä" -or $UpdateChoice -eq "Y" -or $UpdateChoice -eq "y") {
                # Ïóòü äëÿ âðåìåííîé çàãðóçêè ôàéëà
                $ExeDownloadUrl = "https://github.com/$GitHubUser/$RepoName/releases/download/v$OnlineVersion/GameBooster.exe"
                $TempFile = "$env:TEMP\GameBooster_new.exe"
                $CurrentExe = $MyInvocation.MyCommand.Path
                
                # Çàãðóçêà íîâîé âåðñèè
                Write-ColorMessage "Çàãðóçêà îáíîâëåíèÿ..." $ColorInfo
                Invoke-WebRequest -Uri $ExeDownloadUrl -OutFile $TempFile -UseBasicParsing
                
                # Ñîçäàíèå ñêðèïòà îáíîâëåíèÿ
                $UpdaterScript = @"
Start-Sleep -Seconds 3
Copy-Item -Path "$TempFile" -Destination "$CurrentExe" -Force
Remove-Item -Path "$TempFile" -Force
Start-Process -FilePath "$CurrentExe"
"@
                
                $UpdaterPath = "$env:TEMP\GameBoosterUpdater.ps1"
                $UpdaterScript | Out-File -FilePath $UpdaterPath -Force
                
                # Çàïóñê ñêðèïòà îáíîâëåíèÿ, êîòîðûé çàìåíèò òåêóùèé EXE è çàïóñòèò åãî ñíîâà
                Write-ColorMessage "Óñòàíîâêà îáíîâëåíèÿ. Ïîæàëóéñòà, ïîäîæäèòå..." $ColorInfo
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$UpdaterPath`"" -WindowStyle Hidden
                
                # Âûõîä èç òåêóùåãî ïðîöåññà
                exit
            }
        } else {
            Write-ColorMessage "Ó âàñ óñòàíîâëåíà ïîñëåäíÿÿ âåðñèÿ ïðîãðàììû ($ScriptVersion)." $ColorSuccess
        }
    } catch {
        Write-ColorMessage "Îøèáêà ïðè ïðîâåðêå îáíîâëåíèé: $_" $ColorError
    }
}

# Ôóíêöèÿ äëÿ ñîçäàíèÿ òî÷êè âîññòàíîâëåíèÿ
function Create-RestorePoint {
    Write-ColorMessage "Ñîçäàíèå òî÷êè âîññòàíîâëåíèÿ ñèñòåìû..." $ColorInfo
    
    # Ïðîâåðêà, âêëþ÷åíà ëè ñëóæáà çàùèòû ñèñòåìû
    $SysRestoreStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    
    if ($null -eq $SysRestoreStatus) {
        Write-ColorMessage "Âêëþ÷åíèå ñëóæáû çàùèòû ñèñòåìû..." $ColorInfo
        Enable-ComputerRestore -Drive "$env:SystemDrive"
    }
    
    # Ñîçäàíèå òî÷êè âîññòàíîâëåíèÿ
    Checkpoint-Computer -Description "Win11Optimizer Before Changes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    
    if ($?) {
        Write-ColorMessage "Òî÷êà âîññòàíîâëåíèÿ ñîçäàíà óñïåøíî." $ColorSuccess
    } else {
        Write-ColorMessage "Íå óäàëîñü ñîçäàòü òî÷êó âîññòàíîâëåíèÿ. Ïðîäîëæàåì áåç íå¸." $ColorWarning
    }
}

# Ôóíêöèÿ îïòèìèçàöèè ïðîèçâîäèòåëüíîñòè
function Optimize-Performance {
    Write-ColorMessage "`nÎïòèìèçàöèÿ ïðîèçâîäèòåëüíîñòè Windows 11..." $ColorInfo
    
    # Îòêëþ÷åíèå ëèøíèõ âèçóàëüíûõ ýôôåêòîâ
    Write-ColorMessage "Íàñòðîéêà âèçóàëüíûõ ýôôåêòîâ äëÿ ïîâûøåíèÿ ïðîèçâîäèòåëüíîñòè..." $ColorInfo
    $VisualFXPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    
    if (-not (Test-Path $VisualFXPath)) {
        New-Item -Path $VisualFXPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $VisualFXPath -Name "VisualFXSetting" -Type DWord -Value 2
    
    # Íàñòðîéêà ýëåêòðîïèòàíèÿ íà âûñîêóþ ïðîèçâîäèòåëüíîñòü
    Write-ColorMessage "Íàñòðîéêà ïëàíà ýëåêòðîïèòàíèÿ íà Âûñîêóþ ïðîèçâîäèòåëüíîñòü..." $ColorInfo
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    # Îòêëþ÷åíèå ôîíîâûõ ïðèëîæåíèé
    Write-ColorMessage "Îòêëþ÷åíèå íåíóæíûõ ôîíîâûõ ïðèëîæåíèé..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type DWord -Value 1
    
    # Îòêëþ÷åíèå èíäåêñàöèè äëÿ ïîâûøåíèÿ ïðîèçâîäèòåëüíîñòè äèñêà
    Write-ColorMessage "Íàñòðîéêà èíäåêñàöèè äèñêîâ..." $ColorInfo
    $IndexService = Get-Service -Name "WSearch"
    if ($IndexService.Status -eq "Running") {
        Stop-Service "WSearch" -Force
        Set-Service "WSearch" -StartupType Disabled
        Write-ColorMessage "Ñëóæáà èíäåêñàöèè îòêëþ÷åíà." $ColorSuccess
    } else {
        Write-ColorMessage "Ñëóæáà èíäåêñàöèè óæå îòêëþ÷åíà." $ColorInfo
    }
}

# Ôóíêöèÿ î÷èñòêè ñèñòåìû
function Clean-System {
    Write-ColorMessage "`nÎ÷èñòêà ñèñòåìû..." $ColorInfo
    
    # Î÷èñòêà âðåìåííûõ ôàéëîâ
    Write-ColorMessage "Î÷èñòêà âðåìåííûõ ôàéëîâ Windows..." $ColorInfo
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Î÷èñòêà êýøà DNS
    Write-ColorMessage "Î÷èñòêà êýøà DNS..." $ColorInfo
    ipconfig /flushdns | Out-Null
    
    # Äåôðàãìåíòàöèÿ äèñêà (òîëüêî äëÿ HDD)
    $DriveType = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } | Select-Object -ExpandProperty MediaType
    if ($DriveType -eq "HDD") {
        Write-ColorMessage "Çàïóñê äåôðàãìåíòàöèè ñèñòåìíîãî äèñêà (ýòî ìîæåò çàíÿòü âðåìÿ)..." $ColorInfo
        Optimize-Volume -DriveLetter C -Defrag
    } else {
        Write-ColorMessage "Îáíàðóæåí SSD äèñê. Äåôðàãìåíòàöèÿ íå òðåáóåòñÿ." $ColorInfo
    }
    
    # Î÷èñòêà êîðçèíû
    Write-ColorMessage "Î÷èñòêà êîðçèíû..." $ColorInfo
    $Shell = New-Object -ComObject Shell.Application
    $RecycleBin = $Shell.Namespace(0xA)
    $RecycleBin.Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }
    
    # Çàïóñê âñòðîåííîãî ñðåäñòâà î÷èñòêè äèñêà
    Write-ColorMessage "Çàïóñê ñðåäñòâà î÷èñòêè äèñêà Windows..." $ColorInfo
    Start-Process -FilePath cleanmgr.exe -ArgumentList "/sagerun:1" -Wait
}

# Ôóíêöèÿ îòêëþ÷åíèÿ òåëåìåòðèè è óëó÷øåíèÿ ïðèâàòíîñòè
function Improve-Privacy {
    Write-ColorMessage "`nÍàñòðîéêà ïðèâàòíîñòè è îòêëþ÷åíèå òåëåìåòðèè..." $ColorInfo
    
    # Âûêëþ÷åíèå ñáîðà äàííûõ òåëåìåòðèè
    Write-ColorMessage "Îòêëþ÷åíèå òåëåìåòðèè Windows..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    
    # Îòêëþ÷åíèå ñåðâèñîâ ñáîðà äàííûõ
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
            Write-ColorMessage "Ñëóæáà $Service îòêëþ÷åíà." $ColorSuccess
        }
    }
    
    # Îòêëþ÷åíèå çàäà÷ ñáîðà äàííûõ â ïëàíèðîâùèêå
    Write-ColorMessage "Îòêëþ÷åíèå çàäà÷ òåëåìåòðèè â ïëàíèðîâùèêå..." $ColorInfo
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
    
    # Îòêëþ÷åíèå ðåêëàìíîãî ID
    Write-ColorMessage "Îòêëþ÷åíèå ðåêëàìíîãî ID..." $ColorInfo
    $AdvertisingIdPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    if (-not (Test-Path $AdvertisingIdPath)) {
        New-Item -Path $AdvertisingIdPath -Force | Out-Null
    }
    Set-ItemProperty -Path $AdvertisingIdPath -Name "Enabled" -Type DWord -Value 0
}

# Ôóíêöèÿ îïòèìèçàöèè àâòîçàãðóçêè
function Optimize-Startup {
    Write-ColorMessage "`nÎïòèìèçàöèÿ àâòîçàãðóçêè Windows..." $ColorInfo
    
    # Âûâåñòè ñïèñîê ïðîãðàìì â àâòîçàãðóçêå
    Write-ColorMessage "Ñïèñîê ïðîãðàìì â àâòîçàãðóçêå:" $ColorInfo
    
    $StartupItems = Get-CimInstance -ClassName Win32_StartupCommand | 
        Select-Object Name, Command, Location, User |
        Format-Table -AutoSize
    
    $StartupItems | Out-Host
    
    # Ïðåäëîæèòü îòêëþ÷åíèå îòäåëüíûõ ýëåìåíòîâ àâòîçàãðóçêè
    Write-ColorMessage "Õîòèòå îòêëþ÷èòü ýëåìåíòû èç àâòîçàãðóçêè? (Ä/Í)" $ColorWarning
    $OptimizeStartupChoice = Read-Host
    
    if ($OptimizeStartupChoice -eq "Ä" -or $OptimizeStartupChoice -eq "ä" -or $OptimizeStartupChoice -eq "Y" -or $OptimizeStartupChoice -eq "y") {
        Write-ColorMessage "Äëÿ îòêëþ÷åíèÿ ýëåìåíòîâ àâòîçàãðóçêè áóäåò çàïóùåí msconfig." $ColorInfo
        Write-ColorMessage "Ïåðåéäèòå âî âêëàäêó 'Àâòîçàãðóçêà' èëè 'Ñëóæáû', ÷òîáû óïðàâëÿòü ýëåìåíòàìè." $ColorInfo
        Start-Process -FilePath msconfig.exe
    }
}

# Ôóíêöèÿ îòêëþ÷åíèÿ íåíóæíûõ ñëóæá
function Optimize-Services {
    Write-ColorMessage "`nÎïòèìèçàöèÿ ñëóæá Windows..." $ColorInfo
    
    # Ñïèñîê ñëóæá, êîòîðûå ìîæíî áåçîïàñíî îòêëþ÷èòü äëÿ ïîâûøåíèÿ ïðîèçâîäèòåëüíîñòè
    $ServicesToDisable = @(
        # Ñïèñîê ñëóæá, êîòîðûå ìîæíî îòêëþ÷èòü
        @{Name = "SysMain"; DisplayName = "Superfetch"; Description = "Ïðåäâàðèòåëüíàÿ çàãðóçêà ïðèëîæåíèé â ïàìÿòü"},
        @{Name = "MapsBroker"; DisplayName = "Äèñïåò÷åð çàãðóæåííûõ êàðò"; Description = "Ñêà÷èâàíèå êàðò"},
        @{Name = "lfsvc"; DisplayName = "Ñëóæáà îïðåäåëåíèÿ ðàñïîëîæåíèÿ"; Description = "Ãåîëîêàöèîííûå ñåðâèñû"},
        @{Name = "XblGameSave"; DisplayName = "Ñîõðàíåíèå èãð Xbox Live"; Description = "Ñèíõðîíèçàöèÿ ñîõðàíåíèé Xbox"},
        @{Name = "XblAuthManager"; DisplayName = "Äèñïåò÷åð ïðîâåðêè ïîäëèííîñòè Xbox Live"; Description = "Àóòåíòèôèêàöèÿ Xbox Live"},
        @{Name = "RetailDemo"; DisplayName = "Äåìîíñòðàöèîííûé ðåæèì äëÿ ðîçíè÷íîé ïðîäàæè"; Description = "Äåìîíñòðàöèîííûé ðåæèì"}
    )
    
    # Âûâîä ñïèñêà ñëóæá ñ îïèñàíèåì
    Write-ColorMessage "Ñïèñîê ñëóæá, êîòîðûå ìîæíî îòêëþ÷èòü äëÿ ïîâûøåíèÿ ïðîèçâîäèòåëüíîñòè:" $ColorInfo
    
    $i = 1
    foreach ($Service in $ServicesToDisable) {
        Write-ColorMessage "$i. $($Service.DisplayName) ($($Service.Name)) - $($Service.Description)" $ColorInfo
        $i++
    }
    
    # Ñïðîñèòü ïîëüçîâàòåëÿ, êàêèå ñëóæáû îòêëþ÷àòü
    Write-ColorMessage "`nÂâåäèòå íîìåðà ñëóæá, êîòîðûå íóæíî îòêëþ÷èòü (÷åðåç çàïÿòóþ), èëè 'âñ¸' äëÿ îòêëþ÷åíèÿ âñåõ ñëóæá:" $ColorWarning
    $ServiceChoice = Read-Host
    
    # Îáðàáîòêà âûáîðà ïîëüçîâàòåëÿ
    if ($ServiceChoice -eq "âñ¸" -or $ServiceChoice -eq "âñå") {
        foreach ($Service in $ServicesToDisable) {
            $ServiceObj = Get-Service -Name $Service.Name -ErrorAction SilentlyContinue
            if ($ServiceObj) {
                Stop-Service -Name $Service.Name -Force -ErrorAction SilentlyContinue
                Set-Service -Name $Service.Name -StartupType Disabled
                Write-ColorMessage "Ñëóæáà $($Service.DisplayName) îòêëþ÷åíà." $ColorSuccess
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
                        Write-ColorMessage "Ñëóæáà $($ServiceToDisable.DisplayName) îòêëþ÷åíà." $ColorSuccess
                    }
                }
            }
        }
    }
}

# Ôóíêöèÿ íàñòðîéêè ðååñòðà äëÿ îïòèìèçàöèè ñèñòåìû
function Optimize-Registry {
    Write-ColorMessage "`nÎïòèìèçàöèÿ ðååñòðà Windows..." $ColorInfo
    
    # Óñêîðåíèå çàïóñêà ïðèëîæåíèé
    Write-ColorMessage "Îïòèìèçàöèÿ çàïóñêà ïðèëîæåíèé..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Type DWord -Value 3
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Type DWord -Value 0
    
    # Îïòèìèçàöèÿ êýøèðîâàíèÿ ôàéëîâîé ñèñòåìû
    Write-ColorMessage "Îïòèìèçàöèÿ êýøèðîâàíèÿ ôàéëîâîé ñèñòåìû..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Type DWord -Value 1
    
    # Óñêîðåíèå ìåíþ
    Write-ColorMessage "Óñêîðåíèå îòêëèêà ìåíþ..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0"
    
    # Îòêëþ÷åíèå àíèìàöèè
    Write-ColorMessage "Íàñòðîéêà àíèìàöèè äëÿ ïîâûøåíèÿ ïðîèçâîäèòåëüíîñòè..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value "0"
    
    # Îòêëþ÷åíèå ýôôåêòà ïðîçðà÷íîñòè
    Write-ColorMessage "Îòêëþ÷åíèå ýôôåêòà ïðîçðà÷íîñòè..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Type DWord -Value 0
    
    # Óñêîðåíèå âûêëþ÷åíèÿ ñèñòåìû
    Write-ColorMessage "Îïòèìèçàöèÿ âðåìåíè âûêëþ÷åíèÿ ñèñòåìû..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type String -Value "2000"
}

# Ãëàâíîå ìåíþ
function Show-Menu {
    Clear-Host
    Write-ColorMessage "Windows 11 Optimizer v$ScriptVersion" $ColorInfo
    Write-ColorMessage "-------------------------------------" $ColorInfo
    Write-ColorMessage "Âûáåðèòå äåéñòâèå:" $ColorInfo
    Write-ColorMessage "1. Çàïóñòèòü âñå îïòèìèçàöèè" $ColorInfo
    Write-ColorMessage "2. Îïòèìèçàöèÿ ïðîèçâîäèòåëüíîñòè" $ColorInfo
    Write-ColorMessage "3. Î÷èñòêà ñèñòåìû" $ColorInfo
    Write-ColorMessage "4. Íàñòðîéêà ïðèâàòíîñòè" $ColorInfo
    Write-ColorMessage "5. Îïòèìèçàöèÿ àâòîçàãðóçêè" $ColorInfo
    Write-ColorMessage "6. Îïòèìèçàöèÿ ñëóæá" $ColorInfo
    Write-ColorMessage "7. Îïòèìèçàöèÿ ðååñòðà" $ColorInfo
    Write-ColorMessage "8. Ïðîâåðèòü íàëè÷èå îáíîâëåíèé" $ColorInfo
    Write-ColorMessage "9. Ñîçäàòü òî÷êó âîññòàíîâëåíèÿ" $ColorInfo
    Write-ColorMessage "0. Âûõîä" $ColorInfo
    Write-ColorMessage "-------------------------------------" $ColorInfo
    
    $Choice = Read-Host "Ââåäèòå íîìåð"
    
    switch ($Choice) {
        "1" {
            Create-RestorePoint
            Optimize-Performance
            Clean-System
            Improve-Privacy
            Optimize-Startup
            Optimize-Services
            Optimize-Registry
            Write-ColorMessage "`nÂñå îïòèìèçàöèè âûïîëíåíû óñïåøíî!" $ColorSuccess
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "2" {
            Optimize-Performance
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "3" {
            Clean-System
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "4" {
            Improve-Privacy
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "5" {
            Optimize-Startup
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "6" {
            Optimize-Services
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "7" {
            Optimize-Registry
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "8" {
            Check-ForUpdates
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "9" {
            Create-RestorePoint
            Read-Host "Íàæìèòå Enter äëÿ âîçâðàòà â ìåíþ"
            Show-Menu
        }
        "0" {
            Write-ColorMessage "Âûõîä èç ïðîãðàììû..." $ColorInfo
            exit
        }
        default {
            Write-ColorMessage "Íåâåðíûé âûáîð. Ïîïðîáóéòå ñíîâà." $ColorWarning
            Start-Sleep -Seconds 2
            Show-Menu
        }
    }
}

# Ïðîâåðêà îáíîâëåíèé ïðè çàïóñêå
Check-ForUpdates

# Çàïóñê ãëàâíîãî ìåíþ
Show-Menu
