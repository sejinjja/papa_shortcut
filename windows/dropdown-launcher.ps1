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
        throw "Config 파일을 찾을 수 없습니다: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    $items = $raw | ConvertFrom-Json

    if ($null -eq $items -or $items.Count -eq 0) {
        throw "Config 항목이 비어 있습니다. $Path 를 확인하세요."
    }

    foreach ($item in $items) {
        if (-not $item.name -or -not $item.target) {
            throw "모든 항목에 name/target 이 필요합니다."
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

    # 프로그램 이름(notepad.exe) 같은 상대 명령도 허용하기 위해 존재 검사 실패해도 실행 시도
    try {
        Start-Process -FilePath $Target | Out-Null
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "실행 실패: $Target`n$($_.Exception.Message)",
            "Papa Shortcut",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
}

$shortcuts = Read-ShortcutConfig -Path $ConfigPath

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Papa Shortcut'
$form.Size = New-Object System.Drawing.Size(420, 90)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true

$combo = New-Object System.Windows.Forms.ComboBox
$combo.Location = New-Object System.Drawing.Point(12, 12)
$combo.Size = New-Object System.Drawing.Size(380, 24)
$combo.DropDownStyle = 'DropDownList'
$combo.Font = New-Object System.Drawing.Font('Malgun Gothic', 10)

$placeholder = '실행할 항목을 선택하세요'
[void]$combo.Items.Add($placeholder)
foreach ($item in $shortcuts) {
    [void]$combo.Items.Add($item.name)
}
$combo.SelectedIndex = 0

$combo.Add_SelectedIndexChanged({
    if ($combo.SelectedIndex -le 0) {
        return
    }

    $selectedName = $combo.SelectedItem.ToString()
    $selected = $shortcuts | Where-Object { $_.name -eq $selectedName } | Select-Object -First 1
    if ($null -ne $selected) {
        Open-Target -Target $selected.target
    }

    $combo.SelectedIndex = 0
})

$form.Controls.Add($combo)

[void]$form.ShowDialog()
