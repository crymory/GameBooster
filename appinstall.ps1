# Загрузка необходимых сборок для создания формы
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Создание формы
$form = New-Object System.Windows.Forms.Form
$form.Text = "GameBooster by rage"
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false

# Добавление иконки
$iconBase64 = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAVESURBVFhH7ZZrTFNnGMf/p5RyK9JWWltvUKAIFTBemCiI8bIYl8VsGZqw6Rcn2SLLlsVkH7Yv+7Qvi8mWzC3RuGVkY5tmuikmLgp4mbIpIio3HYJcC7SU3s7pOT1dP+RsSbfJEpP9k6fve973fc/z/N/nPe85By+/WL4AQQF/E74KeFPQBWhsbARN0zAajWhpaYHf7ydqHA4HVCoV1tbWuAjsdjsUCgXy8vKg1WpRXFyM1NRUos/JyYFIJCJ8O3YqQNYsLS3h4MGDqKioQGdnJ9ra2rjVZ8jMzER9fT3q6uqIvbi4GLOzs0hLSyN2aWkpKioqqKqqQkJCAqqrq1FTU8OtPmNHAlpaWtDc3IympibodDq4XC60t7cTvVgshkajwebmJnmUSiX0ej3i4+Oh0WigVCphs9mItaenB3q9noSCXC7nVrfwRgKk0ilcuHABs9Y5KKQbsD0xISVahXdOnUJJSQlKSkpw9OhRdHR0oLS0FCdPniTXs2fPkqD09HQSgszMTHJNSkrCwYMH0d3dzZ12wWsFtLa24tSpUzh58iR5k0fLSxALNuCTiXHoxHBTyXB3+BHG7Q6SZ4YFk8mEoaEhGAwGEovFYrKWlJQEhUJBYsIwMjKC1dVV+JYcGBoeQUREBJKTk/H48WMsLCyQNIaGhhL9tgICgQCio6PRcP48xJQfJrMRnwn4+EYgRJZcBD4twi3pOs7evILlFQsMBgMGBgaIiJ6eHtBCPo61diGzcg1fVVdh5c4GIrPl2Lj5JyQfz+K/jzmKfhfEqOHxeDAyMoJAJA8Lfi+G3A689UU7/piawvCvy3D7PGjIz0fMXjHC7lKILoxjdHQUN27cQMXhEhT/ug9CWRZEMikEi3OInryJvKFvkTT1C9dTANWpUyAkEgmy9u3DkiCIcYsJVWlpSIqLQ4VOB3N6OtnPTkhAiUSCWJEIbrsdXo8LAsYPfmAAHJEUgcgYhFBCcFIvMexCMBhEW1sbKisr0draisOHD2NtdBqzZgvyc3KREhWF+KhoRMUoQUdEYT0iCl6pDDylCpRcAV9IJMIjo9GQloOlKB38yiT4wvVgwkJA+QWI9i4jbOUZeKw7QBAECY5er8fJE3Xo77+PCcsikpVK7I+PxR65DDy+AGExcRDEJ4K5P4Bg93dAfw+47WcwYzbCIojDIU0+IrlcM6NduLOygluffw9HlpnrLXDZAQYzo9MVYWhoGFPzvyFeroLOuAw9T4jyXbHIi+ZhbGoUmJgA7swCbheweA9+0wqiimgEPSIiQMIPgq9aRsjkGPzJWVxvgcsOBAIBBAL+QKyRQJy1Gt8NL+Jz2zxS3Gswrjkxw1B47PUh8NdvwO9/BRv9oNd98EbEQWmwQDw9D58nNDh5LsgTrJgyeXDfFIS4MIXrLRQI2I+RQCAgX0TsZ5XnpXDs/jfwWl2gz38KpcWJ5OAwOJMVlFgKgTgGfMYLn8MOvzuA+NAQ6H0xmFsRQSZtwF6qkOvtNSRB7JdQVVWVwGqdw1//jMNgmMTY2Biuz1RB9qEA9MIs6MkpMDIZxvR6yNYt2M94IRJJIXQHSdj4YX54fGKIJMVcLyEEXigge0c8eJkLcxiZWYPJZEJnXz+WHA7oUhKhWHNDxfgQxfMizLKMgCcapqVUjC/yYHOLIY6qhUByATHhUYga68dO2VYAi91uB7O2DJdnDQN9PRiddGJ5xYL6Bjl02SlwLsyRFPB5VOAWAyHEWBUyYdwow+jdMIjCIxEm02F1cXd/cDsWwPLk8TRW7H4Mjf+OhdXnP1I7ZUcCvpv5FfyQcFCUACKFDOlRbyCAxVsB/y/+BTNFSoeYhXUTAAAAAElFTkSuQmCC"
$iconBytes = [Convert]::FromBase64String($iconBase64)
$ms = New-Object System.IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
$ms.Write($iconBytes, 0, $iconBytes.Length)
$icon = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap($ms)).GetHIcon())
$form.Icon = $icon

# Панель заголовка
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$headerPanel.Height = 70
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(65, 105, 225)

$headerLabel = New-Object System.Windows.Forms.Label
$headerLabel.Text = "Установщик приложений"
$headerLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$headerLabel.ForeColor = [System.Drawing.Color]::White
$headerLabel.AutoSize = $true
$headerLabel.Location = New-Object System.Drawing.Point(20, 18)
$headerPanel.Controls.Add($headerLabel)

# Информационная область
$infoPanel = New-Object System.Windows.Forms.Panel
$infoPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$infoPanel.Height = 60
$infoPanel.BackColor = [System.Drawing.Color]::FromArgb(235, 235, 235)

$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "Выберите приложения для установки из списка ниже. Вы можете выбрать несколько приложений."
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
$infoLabel.AutoSize = $false
$infoLabel.Size = New-Object System.Drawing.Size(660, 50)
$infoLabel.Location = New-Object System.Drawing.Point(20, 10)
$infoPanel.Controls.Add($infoLabel)

# Список приложений
$appListPanel = New-Object System.Windows.Forms.Panel
$appListPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$appListPanel.BackColor = [System.Drawing.Color]::White
$appListPanel.Padding = New-Object System.Windows.Forms.Padding(20)

# Создание списка приложений
$apps = @(
    @{Name="Google Chrome"; Description="Популярный веб-браузер"; Icon="🌐"; Url="https://dl.google.com/chrome/install/latest/chrome_installer.exe"; CommandLine="/silent /install"},
    @{Name="Mozilla Firefox"; Description="Надежный и быстрый браузер"; Icon="🦊"; Url="https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=ru"; CommandLine="-ms"},
    @{Name="Steam"; Description="Популярная платформа для игр"; Icon="🎮"; Url="https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"; CommandLine="/S"},
    @{Name="Discord"; Description="Платформа для общения геймеров"; Icon="💬"; Url="https://discord.com/api/downloads/distributions/app/installers/latest?channel=stable&platform=win&arch=x86"; CommandLine="-s"},
    @{Name="Epic Games Launcher"; Description="Магазин игр от Epic Games"; Icon="🎯"; Url="https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi"; CommandLine="/quiet"},
    @{Name="Uplay (Ubisoft Connect)"; Description="Лаунчер игр от Ubisoft"; Icon="🎲"; Url="https://ubi.li/4vxt9"; CommandLine="/S"},
    @{Name="Origin"; Description="Лаунчер игр от EA"; Icon="🎪"; Url="https://www.dm.origin.com/download"; CommandLine="/silent"},
    @{Name="Battle.net"; Description="Лаунчер игр от Blizzard"; Icon="⚔️"; Url="https://www.battle.net/download/getInstallerForGame?os=win&gameProgram=BATTLENET_APP"; CommandLine="--lang=ruRU --installpath=C:\Program Files (x86)\Battle.net\ --silent"},
    @{Name="GOG Galaxy"; Description="Платформа для игр без DRM"; Icon="🌌"; Url="https://content-system.gog.com/open_link/download?path=/open/galaxy/client/2.0.14.257/setup_galaxy_2.0.14.257.exe"; CommandLine="/VERYSILENT /NORESTART /NOCANCEL"},
    @{Name="TeamSpeak"; Description="Приложение для голосового общения"; Icon="🎙️"; Url="https://files.teamspeak-services.com/releases/client/3.5.6/TeamSpeak3-Client-win64-3.5.6.exe"; CommandLine="/S"},
    @{Name="Spotify"; Description="Стриминговый сервис музыки"; Icon="🎵"; Url="https://download.spotify.com/SpotifyFullSetup.exe"; CommandLine="/silent"},
    @{Name="VLC media player"; Description="Популярный медиаплеер"; Icon="📺"; Url="https://get.videolan.org/vlc/3.0.16/win64/vlc-3.0.16-win64.exe"; CommandLine="/S"},
    @{Name="7-Zip"; Description="Архиватор файлов"; Icon="📦"; Url="https://www.7-zip.org/a/7z1900-x64.exe"; CommandLine="/S"},
    @{Name="OBS Studio"; Description="Программа для записи экрана и стриминга"; Icon="📹"; Url="https://github.com/obsproject/obs-studio/releases/download/27.0.1/OBS-Studio-27.0.1-Full-Installer-x64.exe"; CommandLine="/S"},
    @{Name="Telegram"; Description="Мессенджер"; Icon="✈️"; Url="https://telegram.org/dl/desktop/win64"; CommandLine="/VERYSILENT /NORESTART"}
)

# Подготовка элементов интерфейса для списка приложений
$checkBoxes = @()
$y = 10
$idCounter = 0

# Создание чекбоксов для каждого приложения
foreach ($app in $apps) {
    $checkBox = New-Object System.Windows.Forms.CheckBox
    $checkBox.Text = "$($app.Icon) $($app.Name)"
    $checkBox.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $checkBox.Size = New-Object System.Drawing.Size(200, 24)
    $checkBox.Location = New-Object System.Drawing.Point(10, $y)
    $checkBox.Tag = $idCounter
    $checkBoxes += $checkBox
    
    $descLabel = New-Object System.Windows.Forms.Label
    $descLabel.Text = $app.Description
    $descLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $descLabel.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    $descLabel.Size = New-Object System.Drawing.Size(400, 24)
    $descLabel.Location = New-Object System.Drawing.Point(220, $y + 3)
    
    $appListPanel.Controls.Add($checkBox)
    $appListPanel.Controls.Add($descLabel)
    
    $y += 35
    $idCounter++
}

# Создание FlowLayoutPanel для управляющих кнопок
$buttonsPanel = New-Object System.Windows.Forms.Panel
$buttonsPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$buttonsPanel.Height = 70
$buttonsPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

# Кнопка "Выбрать все"
$selectAllButton = New-Object System.Windows.Forms.Button
$selectAllButton.Text = "Выбрать все"
$selectAllButton.Size = New-Object System.Drawing.Size(120, 35)
$selectAllButton.Location = New-Object System.Drawing.Point(20, 20)
$selectAllButton.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$selectAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$selectAllButton.Add_Click({
    foreach ($checkBox in $checkBoxes) {
        $checkBox.Checked = $true
    }
})

# Кнопка "Отменить все"
$deselectAllButton = New-Object System.Windows.Forms.Button
$deselectAllButton.Text = "Отменить все"
$deselectAllButton.Size = New-Object System.Drawing.Size(120, 35)
$deselectAllButton.Location = New-Object System.Drawing.Point(150, 20)
$deselectAllButton.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
$deselectAllButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$deselectAllButton.Add_Click({
    foreach ($checkBox in $checkBoxes) {
        $checkBox.Checked = $false
    }
})

# Кнопка "Установить"
$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Установить"
$installButton.Size = New-Object System.Drawing.Size(120, 35)
$installButton.Location = New-Object System.Drawing.Point(550, 20)
$installButton.BackColor = [System.Drawing.Color]::FromArgb(65, 105, 225)
$installButton.ForeColor = [System.Drawing.Color]::White
$installButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$installButton.Add_Click({
    # Получение выбранных приложений
    $selectedApps = @()
    for ($i = 0; $i -lt $checkBoxes.Count; $i++) {
        if ($checkBoxes[$i].Checked) {
            $selectedApps += $apps[$i]
        }
    }
    
    # Проверка наличия выбранных приложений
    if ($selectedApps.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Пожалуйста, выберите хотя бы одно приложение для установки.", "Нет выбранных приложений", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    # Создание прогресс-диалога
    $progressForm = New-Object System.Windows.Forms.Form
    $progressForm.Text = "Установка приложений"
    $progressForm.Size = New-Object System.Drawing.Size(400, 150)
    $progressForm.StartPosition = "CenterScreen"
    $progressForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $progressForm.MaximizeBox = $false
    $progressForm.MinimizeBox = $false
    
    $progressLabel = New-Object System.Windows.Forms.Label
    $progressLabel.Location = New-Object System.Drawing.Point(10, 20)
    $progressLabel.Size = New-Object System.Drawing.Size(370, 20)
    $progressLabel.Text = "Подготовка к установке..."
    $progressForm.Controls.Add($progressLabel)
    
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Location = New-Object System.Drawing.Point(10, 50)
    $progressBar.Size = New-Object System.Drawing.Size(370, 23)
    $progressBar.Style = "Continuous"
    $progressForm.Controls.Add($progressBar)
    
    $statusLabel = New-Object System.Windows.Forms.Label
    $statusLabel.Location = New-Object System.Drawing.Point(10, 80)
    $statusLabel.Size = New-Object System.Drawing.Size(370, 20)
    $statusLabel.Text = "Ожидание..."
    $progressForm.Controls.Add($statusLabel)
    
    # Показать прогресс-диалог без блокировки
    $progressForm.Show()
    $progressForm.Refresh()
    
    # Настройка прогресс-бара
    $progressBar.Minimum = 0
    $progressBar.Maximum = $selectedApps.Count
    $progressBar.Value = 0
    
    # Установка выбранных приложений
    $tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "AppInstaller")
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir | Out-Null
    }
    
    $installCount = 0
    $failedApps = @()
    
    foreach ($app in $selectedApps) {
        try {
            $progressLabel.Text = "Загрузка $($app.Name)..."
            $statusLabel.Text = "Загрузка файла установки..."
            $progressForm.Refresh()
            
            $outFile = [System.IO.Path]::Combine($tempDir, "$($app.Name -replace '\s+', '_').exe")
            
            # Загрузка файла установщика
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($app.Url, $outFile)
            
            $progressLabel.Text = "Установка $($app.Name)..."
            $statusLabel.Text = "Запуск установщика..."
            $progressForm.Refresh()
            
            # Запуск установщика
            $process = Start-Process -FilePath $outFile -ArgumentList $app.CommandLine -PassThru
            $statusLabel.Text = "Ожидание завершения установки..."
            $progressForm.Refresh()
            
            # Ожидание завершения установки (с таймаутом 5 минут)
            $process.WaitForExit(300000)
            
            # Очистка
            Remove-Item -Path $outFile -Force -ErrorAction SilentlyContinue
            
            $installCount++
        }
        catch {
            $failedApps += $app.Name
            $statusLabel.Text = "Ошибка установки $($app.Name)"
            $progressForm.Refresh()
            Start-Sleep -Seconds 2
        }
        
        $progressBar.Value++
        $progressForm.Refresh()
    }
    
    $progressForm.Close()
    
    # Вывод результатов установки
    if ($failedApps.Count -gt 0) {
        $message = "Установка завершена. Успешно установлено: $installCount из $($selectedApps.Count) приложений.`n`nНе удалось установить:`n" + ($failedApps -join "`n")
        [System.Windows.Forms.MessageBox]::Show($message, "Результат установки", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Все выбранные приложения ($installCount) были успешно установлены!", "Установка завершена", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    
    # Очистка временной директории
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
})

# Добавление кнопок на панель
$buttonsPanel.Controls.Add($selectAllButton)
$buttonsPanel.Controls.Add($deselectAllButton)
$buttonsPanel.Controls.Add($installButton)

# Создание ScrollBar для списка приложений
$scrollPanel = New-Object System.Windows.Forms.Panel
$scrollPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$scrollPanel.AutoScroll = $true
$scrollPanel.Controls.Add($appListPanel)

# Добавление всех панелей на форму
$form.Controls.Add($buttonsPanel)
$form.Controls.Add($scrollPanel)
$form.Controls.Add($infoPanel)
$form.Controls.Add($headerPanel)

# Отображение формы
$form.ShowDialog()