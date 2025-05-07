$ScriptVersion = "1.0"
$GitHubUser = "crymory" # �������� �� ���� ��� ������������ GitHub
$RepoName = "GameBooster"
$BranchName = "main"
$ScriptName = "GameBooster.ps1"

# ��������� ������ ��� ������
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"

# ������� ��� ������ ���������� � ������
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorMessage "Windows 11 Optimizer v$ScriptVersion" $ColorInfo
Write-ColorMessage "-------------------------------------" $ColorInfo

# �������� ������� �� ����� ��������������
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-ColorMessage "��� ������ ��������� ����� ��������������! ������������� ������ �� ����� ��������������." $ColorError
    Start-Sleep -Seconds 3
    exit
}

# ������� �������� ���������� ��� EXE-�����
function Check-ForUpdates {
    try {
        Write-ColorMessage "�������� ������� ����������..." $ColorInfo
        
        # URL ��� �������� ��������� ������ ������� �� GitHub
        $VersionFileUrl = "https://raw.githubusercontent.com/$GitHubUser/$RepoName/$BranchName/version.txt"
        
        # ��������� ������ � GitHub
        $OnlineVersion = (Invoke-WebRequest -Uri $VersionFileUrl -UseBasicParsing).Content.Trim()
        
        if ([version]$OnlineVersion -gt [version]$ScriptVersion) {
            Write-ColorMessage "�������� ����� ������: $OnlineVersion (� ���: $ScriptVersion)" $ColorWarning
            $UpdateChoice = Read-Host "������ �������� ���������? (�/�)"
            
            if ($UpdateChoice -eq "�" -or $UpdateChoice -eq "�" -or $UpdateChoice -eq "Y" -or $UpdateChoice -eq "y") {
                # ���� ��� ��������� �������� �����
                $ExeDownloadUrl = "https://github.com/$GitHubUser/$RepoName/releases/download/v$OnlineVersion/GameBooster.exe"
                $TempFile = "$env:TEMP\GameBooster_new.exe"
                $CurrentExe = $MyInvocation.MyCommand.Path
                
                # �������� ����� ������
                Write-ColorMessage "�������� ����������..." $ColorInfo
                Invoke-WebRequest -Uri $ExeDownloadUrl -OutFile $TempFile -UseBasicParsing
                
                # �������� ������� ����������
                $UpdaterScript = @"
Start-Sleep -Seconds 3
Copy-Item -Path "$TempFile" -Destination "$CurrentExe" -Force
Remove-Item -Path "$TempFile" -Force
Start-Process -FilePath "$CurrentExe"
"@
                
                $UpdaterPath = "$env:TEMP\GameBoosterUpdater.ps1"
                $UpdaterScript | Out-File -FilePath $UpdaterPath -Force
                
                # ������ ������� ����������, ������� ������� ������� EXE � �������� ��� �����
                Write-ColorMessage "��������� ����������. ����������, ���������..." $ColorInfo
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$UpdaterPath`"" -WindowStyle Hidden
                
                # ����� �� �������� ��������
                exit
            }
        } else {
            Write-ColorMessage "� ��� ����������� ��������� ������ ��������� ($ScriptVersion)." $ColorSuccess
        }
    } catch {
        Write-ColorMessage "������ ��� �������� ����������: $_" $ColorError
    }
}

# ������� ��� �������� ����� ��������������
function Create-RestorePoint {
    Write-ColorMessage "�������� ����� �������������� �������..." $ColorInfo
    
    # ��������, �������� �� ������ ������ �������
    $SysRestoreStatus = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
    
    if ($null -eq $SysRestoreStatus) {
        Write-ColorMessage "��������� ������ ������ �������..." $ColorInfo
        Enable-ComputerRestore -Drive "$env:SystemDrive"
    }
    
    # �������� ����� ��������������
    Checkpoint-Computer -Description "Win11Optimizer Before Changes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
    
    if ($?) {
        Write-ColorMessage "����� �������������� ������� �������." $ColorSuccess
    } else {
        Write-ColorMessage "�� ������� ������� ����� ��������������. ���������� ��� ��." $ColorWarning
    }
}

# ������� ����������� ������������������
function Optimize-Performance {
    Write-ColorMessage "`n����������� ������������������ Windows 11..." $ColorInfo
    
    # ���������� ������ ���������� ��������
    Write-ColorMessage "��������� ���������� �������� ��� ��������� ������������������..." $ColorInfo
    $VisualFXPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    
    if (-not (Test-Path $VisualFXPath)) {
        New-Item -Path $VisualFXPath -Force | Out-Null
    }
    
    Set-ItemProperty -Path $VisualFXPath -Name "VisualFXSetting" -Type DWord -Value 2
    
    # ��������� �������������� �� ������� ������������������
    Write-ColorMessage "��������� ����� �������������� �� ������� ������������������..." $ColorInfo
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    
    # ���������� ������� ����������
    Write-ColorMessage "���������� �������� ������� ����������..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type DWord -Value 1
    
    # ���������� ���������� ��� ��������� ������������������ �����
    Write-ColorMessage "��������� ���������� ������..." $ColorInfo
    $IndexService = Get-Service -Name "WSearch"
    if ($IndexService.Status -eq "Running") {
        Stop-Service "WSearch" -Force
        Set-Service "WSearch" -StartupType Disabled
        Write-ColorMessage "������ ���������� ���������." $ColorSuccess
    } else {
        Write-ColorMessage "������ ���������� ��� ���������." $ColorInfo
    }
}

# ������� ������� �������
function Clean-System {
    Write-ColorMessage "`n������� �������..." $ColorInfo
    
    # ������� ��������� ������
    Write-ColorMessage "������� ��������� ������ Windows..." $ColorInfo
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # ������� ���� DNS
    Write-ColorMessage "������� ���� DNS..." $ColorInfo
    ipconfig /flushdns | Out-Null
    
    # �������������� ����� (������ ��� HDD)
    $DriveType = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq 0 } | Select-Object -ExpandProperty MediaType
    if ($DriveType -eq "HDD") {
        Write-ColorMessage "������ �������������� ���������� ����� (��� ����� ������ �����)..." $ColorInfo
        Optimize-Volume -DriveLetter C -Defrag
    } else {
        Write-ColorMessage "��������� SSD ����. �������������� �� ���������." $ColorInfo
    }
    
    # ������� �������
    Write-ColorMessage "������� �������..." $ColorInfo
    $Shell = New-Object -ComObject Shell.Application
    $RecycleBin = $Shell.Namespace(0xA)
    $RecycleBin.Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }
    
    # ������ ����������� �������� ������� �����
    Write-ColorMessage "������ �������� ������� ����� Windows..." $ColorInfo
    Start-Process -FilePath cleanmgr.exe -ArgumentList "/sagerun:1" -Wait
}

# ������� ���������� ���������� � ��������� �����������
function Improve-Privacy {
    Write-ColorMessage "`n��������� ����������� � ���������� ����������..." $ColorInfo
    
    # ���������� ����� ������ ����������
    Write-ColorMessage "���������� ���������� Windows..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Type DWord -Value 0
    
    # ���������� �������� ����� ������
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
            Write-ColorMessage "������ $Service ���������." $ColorSuccess
        }
    }
    
    # ���������� ����� ����� ������ � ������������
    Write-ColorMessage "���������� ����� ���������� � ������������..." $ColorInfo
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
    
    # ���������� ���������� ID
    Write-ColorMessage "���������� ���������� ID..." $ColorInfo
    $AdvertisingIdPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    if (-not (Test-Path $AdvertisingIdPath)) {
        New-Item -Path $AdvertisingIdPath -Force | Out-Null
    }
    Set-ItemProperty -Path $AdvertisingIdPath -Name "Enabled" -Type DWord -Value 0
}

# ������� ����������� ������������
function Optimize-Startup {
    Write-ColorMessage "`n����������� ������������ Windows..." $ColorInfo
    
    # ������� ������ �������� � ������������
    Write-ColorMessage "������ �������� � ������������:" $ColorInfo
    
    $StartupItems = Get-CimInstance -ClassName Win32_StartupCommand | 
        Select-Object Name, Command, Location, User |
        Format-Table -AutoSize
    
    $StartupItems | Out-Host
    
    # ���������� ���������� ��������� ��������� ������������
    Write-ColorMessage "������ ��������� �������� �� ������������? (�/�)" $ColorWarning
    $OptimizeStartupChoice = Read-Host
    
    if ($OptimizeStartupChoice -eq "�" -or $OptimizeStartupChoice -eq "�" -or $OptimizeStartupChoice -eq "Y" -or $OptimizeStartupChoice -eq "y") {
        Write-ColorMessage "��� ���������� ��������� ������������ ����� ������� msconfig." $ColorInfo
        Write-ColorMessage "��������� �� ������� '������������' ��� '������', ����� ��������� ����������." $ColorInfo
        Start-Process -FilePath msconfig.exe
    }
}

# ������� ���������� �������� �����
function Optimize-Services {
    Write-ColorMessage "`n����������� ����� Windows..." $ColorInfo
    
    # ������ �����, ������� ����� ��������� ��������� ��� ��������� ������������������
    $ServicesToDisable = @(
        # ������ �����, ������� ����� ���������
        @{Name = "SysMain"; DisplayName = "Superfetch"; Description = "��������������� �������� ���������� � ������"},
        @{Name = "MapsBroker"; DisplayName = "��������� ����������� ����"; Description = "���������� ����"},
        @{Name = "lfsvc"; DisplayName = "������ ����������� ������������"; Description = "�������������� �������"},
        @{Name = "XblGameSave"; DisplayName = "���������� ��� Xbox Live"; Description = "������������� ���������� Xbox"},
        @{Name = "XblAuthManager"; DisplayName = "��������� �������� ����������� Xbox Live"; Description = "�������������� Xbox Live"},
        @{Name = "RetailDemo"; DisplayName = "���������������� ����� ��� ��������� �������"; Description = "���������������� �����"}
    )
    
    # ����� ������ ����� � ���������
    Write-ColorMessage "������ �����, ������� ����� ��������� ��� ��������� ������������������:" $ColorInfo
    
    $i = 1
    foreach ($Service in $ServicesToDisable) {
        Write-ColorMessage "$i. $($Service.DisplayName) ($($Service.Name)) - $($Service.Description)" $ColorInfo
        $i++
    }
    
    # �������� ������������, ����� ������ ���������
    Write-ColorMessage "`n������� ������ �����, ������� ����� ��������� (����� �������), ��� '��' ��� ���������� ���� �����:" $ColorWarning
    $ServiceChoice = Read-Host
    
    # ��������� ������ ������������
    if ($ServiceChoice -eq "��" -or $ServiceChoice -eq "���") {
        foreach ($Service in $ServicesToDisable) {
            $ServiceObj = Get-Service -Name $Service.Name -ErrorAction SilentlyContinue
            if ($ServiceObj) {
                Stop-Service -Name $Service.Name -Force -ErrorAction SilentlyContinue
                Set-Service -Name $Service.Name -StartupType Disabled
                Write-ColorMessage "������ $($Service.DisplayName) ���������." $ColorSuccess
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
                        Write-ColorMessage "������ $($ServiceToDisable.DisplayName) ���������." $ColorSuccess
                    }
                }
            }
        }
    }
}

# ������� ��������� ������� ��� ����������� �������
function Optimize-Registry {
    Write-ColorMessage "`n����������� ������� Windows..." $ColorInfo
    
    # ��������� ������� ����������
    Write-ColorMessage "����������� ������� ����������..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Type DWord -Value 3
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Type DWord -Value 0
    
    # ����������� ����������� �������� �������
    Write-ColorMessage "����������� ����������� �������� �������..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsDisableLastAccessUpdate" -Type DWord -Value 1
    
    # ��������� ����
    Write-ColorMessage "��������� ������� ����..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Type String -Value "0"
    
    # ���������� ��������
    Write-ColorMessage "��������� �������� ��� ��������� ������������������..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Type String -Value "0"
    
    # ���������� ������� ������������
    Write-ColorMessage "���������� ������� ������������..." $ColorInfo
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Type DWord -Value 0
    
    # ��������� ���������� �������
    Write-ColorMessage "����������� ������� ���������� �������..." $ColorInfo
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name "WaitToKillServiceTimeout" -Type String -Value "2000"
}

# ������� ����
function Show-Menu {
    Clear-Host
    Write-ColorMessage "Windows 11 Optimizer v$ScriptVersion" $ColorInfo
    Write-ColorMessage "-------------------------------------" $ColorInfo
    Write-ColorMessage "�������� ��������:" $ColorInfo
    Write-ColorMessage "1. ��������� ��� �����������" $ColorInfo
    Write-ColorMessage "2. ����������� ������������������" $ColorInfo
    Write-ColorMessage "3. ������� �������" $ColorInfo
    Write-ColorMessage "4. ��������� �����������" $ColorInfo
    Write-ColorMessage "5. ����������� ������������" $ColorInfo
    Write-ColorMessage "6. ����������� �����" $ColorInfo
    Write-ColorMessage "7. ����������� �������" $ColorInfo
    Write-ColorMessage "8. ��������� ������� ����������" $ColorInfo
    Write-ColorMessage "9. ������� ����� ��������������" $ColorInfo
    Write-ColorMessage "0. �����" $ColorInfo
    Write-ColorMessage "-------------------------------------" $ColorInfo
    
    $Choice = Read-Host "������� �����"
    
    switch ($Choice) {
        "1" {
            Create-RestorePoint
            Optimize-Performance
            Clean-System
            Improve-Privacy
            Optimize-Startup
            Optimize-Services
            Optimize-Registry
            Write-ColorMessage "`n��� ����������� ��������� �������!" $ColorSuccess
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "2" {
            Optimize-Performance
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "3" {
            Clean-System
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "4" {
            Improve-Privacy
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "5" {
            Optimize-Startup
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "6" {
            Optimize-Services
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "7" {
            Optimize-Registry
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "8" {
            Check-ForUpdates
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "9" {
            Create-RestorePoint
            Read-Host "������� Enter ��� �������� � ����"
            Show-Menu
        }
        "0" {
            Write-ColorMessage "����� �� ���������..." $ColorInfo
            exit
        }
        default {
            Write-ColorMessage "�������� �����. ���������� �����." $ColorWarning
            Start-Sleep -Seconds 2
            Show-Menu
        }
    }
}

# �������� ���������� ��� �������
Check-ForUpdates

# ������ �������� ����
Show-Menu