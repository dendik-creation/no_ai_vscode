$tempDir = "$env:TEMP\vscode_competition_backup"
if (-Not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }

$baseUserDir = "$env:APPDATA\Code\User"
$storageJsonPath = "$baseUserDir\globalStorage\storage.json"

$aiExtensions = @(
    "GitHub.copilot", "GitHub.copilot-chat", "TabNine.tabnine-vscode",
    "Codeium.codeium", "Codeium.codeium-enterprise", "amazonwebservices.amazon-q-vscode",
    "sourcegraph.cody-ai", "Blackboxapp.blackbox", "Bito.Bito", "mintlify.document",
    "aminer.codegeex", "continue.continue", "phind.phind", "saoudrizwan.claude-dev",
    "rooveterinaryinc.roo-cline", "VisualStudioExptTeam.vscodeintellicode"
)

# 0. Check VSCode Has Installed
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Host "VSCode is not installed in your PC." -ForegroundColor Red
    exit
}
Write-Host "VSCode has been found." -ForegroundColor Green

$allProfiles = @()

$allProfiles += [PSCustomObject]@{
    Name = "Default"
    SettingsPath = "$baseUserDir\settings.json"
}

if (Test-Path $storageJsonPath) {
    try {
        $storageRaw = Get-Content -Path $storageJsonPath -Raw -ErrorAction Stop
        $storageData = $storageRaw | ConvertFrom-Json -ErrorAction Stop

        if ($null -ne $storageData.userDataProfiles) {
            foreach ($prof in $storageData.userDataProfiles) {
                $allProfiles += [PSCustomObject]@{
                    Name = $prof.name
                    SettingsPath = "$baseUserDir\profiles\$($prof.location)\settings.json"
                }
            }
        }
    } catch {
        Write-Host "Failed read profiles, switch to Default." -ForegroundColor Yellow
    }
}

Write-Host "`nScanning $($allProfiles.Count) profiles extension" -ForegroundColor Cyan

foreach ($profile in $allProfiles) {
    $safeName = $profile.Name -replace '[^a-zA-Z0-9]',''
    $extBackupFile = "$tempDir\removed_extensions_$safeName.txt"
    $settingsBackup = "$tempDir\settings_$safeName.backup.json"
    $currentSettingsPath = $profile.SettingsPath

    Write-Host "Validating $($profile.Name) profile extensions..."
    if ($profile.Name -eq "Default") {
        $installedExts = code --list-extensions
    } else {
        $installedExts = code --profile "$($profile.Name)" --list-extensions
    }

    $removedList = @()
    foreach ($ext in $aiExtensions) {
        if ($installedExts -match "(?i)^$ext$") {
            if ($profile.Name -eq "Default") {
                code --uninstall-extension $ext --force | Out-Null
            } else {
                code --profile "$($profile.Name)" --uninstall-extension $ext --force | Out-Null
            }
            Write-Host "- $ext Removed" -ForegroundColor Cyan
            $removedList += $ext
        }
    }

    if ($removedList.Count -gt 0) {
        $removedList | Out-File $extBackupFile -Encoding UTF8
        Write-Host "AI Extension successfully backed up." -ForegroundColor Green
    } else {
        Write-Host "No AI extension found." -ForegroundColor Green
    }

    if (Test-Path $currentSettingsPath) {
        if (-Not (Test-Path $settingsBackup)) {
            Copy-Item $currentSettingsPath $settingsBackup -Force
        }
    } else {
        $profileDir = Split-Path $currentSettingsPath -Parent
        if (-Not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir | Out-Null }
        "{}" | Out-File $currentSettingsPath -Encoding UTF8
    }

    $rawContent = Get-Content -Path $currentSettingsPath -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($rawContent)) { $rawContent = "{}" }

    $rawContent = $rawContent -replace '(?m)//.*$','' -replace '(?s)/\*.*?\*/',''
    $rawContent = $rawContent -replace ',\s*([}\]])', '$1'

    try {
        $settingsContent = $rawContent | ConvertFrom-Json
    } catch {
        Write-Host "   New settings.json config because current setting is invalid" -ForegroundColor Yellow
        $settingsContent = [PSCustomObject]@{}
    }

    if (-not $settingsContent) { $settingsContent = [PSCustomObject]@{} }

    $settingsContent | Add-Member -MemberType NoteProperty -Name "editor.inlineSuggest.enabled" -Value $false -Force
    $settingsContent | Add-Member -MemberType NoteProperty -Name "workbench.settings.enableNaturalLanguageSearch" -Value $false -Force
    $settingsContent | Add-Member -MemberType NoteProperty -Name "chat.agent.enabled" -Value $false -Force
    $settingsContent | Add-Member -MemberType NoteProperty -Name "github.copilot.nextEditSuggestions.enabled" -Value $false -Force

    $copilotConfig = [PSCustomObject]@{"*"=$false}
    $settingsContent | Add-Member -MemberType NoteProperty -Name "github.copilot.enable" -Value $copilotConfig -Force

    $settingsContent | ConvertTo-Json -Depth 10 | Out-File $currentSettingsPath -Encoding UTF8
    Write-Host "Built-in AI settings disabled." -ForegroundColor Green
}

Write-Host "`n[All AI features has been disabled]" -ForegroundColor Cyan
