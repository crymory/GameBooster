Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Создание формы
$form = New-Object System.Windows.Forms.Form
$form.Text = "System Latency Monitor"
$form.Size = New-Object System.Drawing.Size(450,400)
$form.StartPosition = "CenterScreen"

# Метка CPU
$cpuLabel = New-Object System.Windows.Forms.Label
$cpuLabel.Location = New-Object System.Drawing.Point(20,20)
$cpuLabel.Size = New-Object System.Drawing.Size(400,30)
$cpuLabel.Font = New-Object System.Drawing.Font("Consolas",11)
$cpuLabel.Text = "CPU: ... "
$form.Controls.Add($cpuLabel)

# Метка GPU
$gpuLabel = New-Object System.Windows.Forms.Label
$gpuLabel.Location = New-Object System.Drawing.Point(20,60)
$gpuLabel.Size = New-Object System.Drawing.Size(400,30)
$gpuLabel.Font = New-Object System.Drawing.Font("Consolas",11)
$gpuLabel.Text = "GPU: ..."
$form.Controls.Add($gpuLabel)

# Кнопка для сбора CPU/GPU
$checkButton = New-Object System.Windows.Forms.Button
$checkButton.Location = New-Object System.Drawing.Point(20,100)
$checkButton.Size = New-Object System.Drawing.Size(150,30)
$checkButton.Text = "Check CPU/GPU"
$form.Controls.Add($checkButton)

$checkButton.Add_Click({
    # CPU через Get-Counter
    $cpu = (Get-Counter "\Processor(_Total)\% Processor Time").CounterSamples[0].CookedValue
    $cpuLabel.Text = "CPU: {0} %" -f [math]::Round($cpu, 2)

    # GPU (если есть)
    try {
        $gpuCounter = "\GPU Engine(*)\Utilization Percentage"
        $gpuData = Get-Counter -Counter $gpuCounter -ErrorAction Stop
        $gpuValues = $gpuData.CounterSamples | Where-Object { $_.InstanceName -match "engtype_3d" }
        if ($gpuValues.Count -gt 0) {
            $gpuAvg = ($gpuValues | Measure-Object -Property CookedValue -Average).Average
            $gpuLabel.Text = "GPU: {0} %" -f [math]::Round($gpuAvg, 2)
        } else {
            $gpuLabel.Text = "GPU: No 3D activity detected"
        }
    } catch {
        $gpuLabel.Text = "GPU: Not available"
    }
})

# Мышиная задержка
$mouseLabel = New-Object System.Windows.Forms.Label
$mouseLabel.Location = New-Object System.Drawing.Point(20,160)
$mouseLabel.Size = New-Object System.Drawing.Size(400,30)
$mouseLabel.Font = New-Object System.Drawing.Font("Consolas",11)
$mouseLabel.Text = "Mouse Latency: ..."
$form.Controls.Add($mouseLabel)

# Кнопка теста мышки
$mouseButton = New-Object System.Windows.Forms.Button
$mouseButton.Location = New-Object System.Drawing.Point(20,200)
$mouseButton.Size = New-Object System.Drawing.Size(150,40)
$mouseButton.Text = "Mouse Latency Test"
$form.Controls.Add($mouseButton)

# Счётчик нажатий и массив задержек
$global:clickCount = 0
$global:latencies = @()
$global:startTime = $null

$mouseButton.Add_MouseDown({
    $global:startTime = Get-Date
})

$mouseButton.Add_MouseUp({
    if ($global:startTime) {
        $endTime = Get-Date
        $latency = ($endTime - $global:startTime).TotalMilliseconds
        $global:latencies += $latency
        $global:startTime = $null
        $global:clickCount++

        if ($global:clickCount -eq 10) {
            $avg = ($global:latencies | Measure-Object -Average).Average
            $min = ($global:latencies | Measure-Object -Minimum).Minimum
            $max = ($global:latencies | Measure-Object -Maximum).Maximum

            $mouseLabel.Text = "Mouse Latency (ms): Avg={0}  Min={1}  Max={2}" -f `
                [math]::Round($avg,2), [math]::Round($min,2), [math]::Round($max,2)

            $global:clickCount = 0
            $global:latencies = @()
        } else {
            $mouseLabel.Text = "Click $global:clickCount of 10..."
        }
    }
})

# Запуск формы
[void]$form.ShowDialog()
