param(
    [string]$ConfigPath = "$PSScriptRoot/shortcuts.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Read-ShortcutConfig {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $items = $raw | ConvertFrom-Json

    if ($null -eq $items -or $items.Count -eq 0) {
        throw "Config is empty. Check: $Path"
    }

    foreach ($item in $items) {
        if (-not $item.name -or -not $item.target) {
            throw "Each item requires both name and target."
        }
    }

    return $items
}

function Open-Target {
    param([string]$Target)

    if ($Target -match '^(https?://)') {
        Start-Process $Target | Out-Null
        return
    }

    # Allow relative commands such as notepad.exe even when no literal path exists
    try {
        Start-Process -FilePath $Target | Out-Null
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Launch failed: $Target`n$($_.Exception.Message)",
            "Papa Shortcut",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

$shortcuts = Read-ShortcutConfig -Path $ConfigPath

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Papa Shortcut'
$form.Size = New-Object System.Drawing.Size(560, 420)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.KeyPreview = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 247, 250)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(16, 14)
$titleLabel.Size = New-Object System.Drawing.Size(520, 24)
$titleLabel.Text = '빠른 실행 런처'
$titleLabel.Font = New-Object System.Drawing.Font('Malgun Gothic', 12, [System.Drawing.FontStyle]::Bold)

$searchLabel = New-Object System.Windows.Forms.Label
$searchLabel.Location = New-Object System.Drawing.Point(16, 48)
$searchLabel.Size = New-Object System.Drawing.Size(80, 22)
$searchLabel.Text = '검색:'
$searchLabel.Font = New-Object System.Drawing.Font('Malgun Gothic', 9)

$searchBox = New-Object System.Windows.Forms.TextBox
$searchBox.Location = New-Object System.Drawing.Point(16, 70)
$searchBox.Size = New-Object System.Drawing.Size(520, 28)
$searchBox.Font = New-Object System.Drawing.Font('Malgun Gothic', 10)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(16, 108)
$listBox.Size = New-Object System.Drawing.Size(520, 210)
$listBox.Font = New-Object System.Drawing.Font('Malgun Gothic', 10)
$null = $listBox.Items.AddRange([object[]]($shortcuts | ForEach-Object { $_.name }))
if ($listBox.Items.Count -gt 0) {
    $listBox.SelectedIndex = 0
}

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(16, 325)
$statusLabel.Size = New-Object System.Drawing.Size(520, 28)
$statusLabel.Text = 'Enter 또는 더블클릭으로 실행 | Esc로 종료'
$statusLabel.Font = New-Object System.Drawing.Font('Malgun Gothic', 9)
$statusLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)

$launchButton = New-Object System.Windows.Forms.Button
$launchButton.Location = New-Object System.Drawing.Point(366, 352)
$launchButton.Size = New-Object System.Drawing.Size(82, 32)
$launchButton.Text = '실행'
$launchButton.Font = New-Object System.Drawing.Font('Malgun Gothic', 9)
$launchButton.BackColor = [System.Drawing.Color]::FromArgb(50, 120, 255)
$launchButton.ForeColor = [System.Drawing.Color]::White
$launchButton.FlatStyle = 'Flat'

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(454, 352)
$closeButton.Size = New-Object System.Drawing.Size(82, 32)
$closeButton.Text = '닫기'
$closeButton.Font = New-Object System.Drawing.Font('Malgun Gothic', 9)

$filteredShortcuts = @($shortcuts)

function Update-ShortcutList {
    param(
        [string]$Keyword,
        [System.Windows.Forms.ListBox]$TargetList,
        [array]$AllShortcuts,
        [ref]$FilteredResult,
        [System.Windows.Forms.Label]$Status
    )

    $trimmed = $Keyword.Trim()
    if ([string]::IsNullOrEmpty($trimmed)) {
        $FilteredResult.Value = @($AllShortcuts)
    }
    else {
        $FilteredResult.Value = @($AllShortcuts | Where-Object {
            $_.name -like "*$trimmed*" -or $_.target -like "*$trimmed*"
        })
    }

    $TargetList.BeginUpdate()
    $TargetList.Items.Clear()
    foreach ($item in $FilteredResult.Value) {
        [void]$TargetList.Items.Add($item.name)
    }
    $TargetList.EndUpdate()

    if ($TargetList.Items.Count -gt 0) {
        $TargetList.SelectedIndex = 0
        $Status.Text = "검색 결과: $($TargetList.Items.Count)개"
    }
    else {
        $Status.Text = '검색 결과가 없습니다.'
    }
}

$runSelectedShortcut = {
    if ($listBox.SelectedIndex -lt 0 -or $filteredShortcuts.Count -eq 0) {
        $statusLabel.Text = '실행할 항목을 먼저 선택하세요.'
        return
    }

    $selectedName = $listBox.SelectedItem.ToString()
    $selected = $filteredShortcuts | Where-Object { $_.name -eq $selectedName } | Select-Object -First 1
    if ($null -eq $selected) {
        $statusLabel.Text = '선택 항목을 찾지 못했습니다. 다시 시도하세요.'
        return
    }

    Open-Target -Target $selected.target
    $statusLabel.Text = "실행됨: $($selected.name)"
}

$searchBox.Add_TextChanged({
    Update-ShortcutList -Keyword $searchBox.Text -TargetList $listBox -AllShortcuts $shortcuts -FilteredResult ([ref]$filteredShortcuts) -Status $statusLabel
})

$listBox.Add_DoubleClick($runSelectedShortcut)
$listBox.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        & $runSelectedShortcut
        $e.Handled = $true
    }
})

$launchButton.Add_Click($runSelectedShortcut)
$closeButton.Add_Click({ $form.Close() })

$form.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $form.Close()
        $e.Handled = $true
    }
})

$form.Controls.Add($titleLabel)
$form.Controls.Add($searchLabel)
$form.Controls.Add($searchBox)
$form.Controls.Add($listBox)
$form.Controls.Add($statusLabel)
$form.Controls.Add($launchButton)
$form.Controls.Add($closeButton)

[void]$form.ShowDialog()
