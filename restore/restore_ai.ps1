$tempDir = "$env:TEMP\vscode_competition_backup"
$baseUserDir = "$env:APPDATA\Code\User"
$storageJsonPath = "$baseUserDir\globalStorage\storage.json"

# 0. Check VSCode Has Installed
if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Host "VSCode is not installed in your PC." -ForegroundColor Red
    exit
}
Write-Host "VSCode has been found." -ForegroundColor Green

# 1. Get all profiles
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

Write-Host "`nRestoring $($allProfiles.Count) profiles..." -ForegroundColor Cyan

foreach ($profile in $allProfiles) {
    $safeName = $profile.Name -replace '[^a-zA-Z0-9]',''
    $extBackupFile = "$tempDir\removed_extensions_$safeName.txt"
    $settingsBackup = "$tempDir\settings_$safeName.backup.json"
    $currentSettingsPath = $profile.SettingsPath

    Write-Host "`nRestoring $($profile.Name) profile..." -ForegroundColor Yellow

    # restore settings
    if (Test-Path $settingsBackup) {
        Copy-Item $settingsBackup $currentSettingsPath -Force
        Remove-Item $settingsBackup -Force
        Write-Host "Settings.json restored from backup." -ForegroundColor Green
    } else {
        Write-Host "No settings backup found for this profile." -ForegroundColor DarkGray
    }

    # reinstall extensions
    if (Test-Path $extBackupFile) {
        Write-Host "Reinstalling extensions. This might take a while..." -ForegroundColor Cyan
        $removedList = Get-Content $extBackupFile

        foreach ($ext in $removedList) {
            Write-Host "- Installing $ext..."
            if ($profile.Name -eq "Default") {
                code --install-extension $ext --force | Out-Null
            } else {
                code --profile "$($profile.Name)" --install-extension $ext --force | Out-Null
            }
        }

        # remove txt backup extensions
        Remove-Item $extBackupFile -Force
        Write-Host "Extensions successfully reinstalled." -ForegroundColor Green
    } else {
        Write-Host "No extension backup found. Nothing to install." -ForegroundColor DarkGray
    }
}

Write-Host "`n[All AI features and settings have been restored]" -ForegroundColor Cyan
