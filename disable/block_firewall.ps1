$vscodePaths = @(
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "C:\Program Files\Microsoft VS Code\Code.exe",
    "C:\Program Files (x86)\Microsoft VS Code\Code.exe"
)

$targetPath = ""
foreach ($path in $vscodePaths) {
    if (Test-Path $path) { $targetPath = $path; break }
}

if ($targetPath -ne "") {
    Remove-NetFirewallRule -DisplayName "VSCode_Block_Outbound" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "VSCode_Block_Inbound" -ErrorAction SilentlyContinue

    New-NetFirewallRule -DisplayName "VSCode_Block_Outbound" -Direction Outbound -Program $targetPath -Action Block -Profile Any | Out-Null
    New-NetFirewallRule -DisplayName "VSCode_Block_Inbound" -Direction Inbound -Program $targetPath -Action Block -Profile Any | Out-Null

    Write-Host "Now VSCode can't access internet" -ForegroundColor Green
} else {
    Write-Host "VSCode not found!" -ForegroundColor Red
}
