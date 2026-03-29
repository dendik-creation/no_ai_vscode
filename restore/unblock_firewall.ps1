Remove-NetFirewallRule -DisplayName "VSCode_Block_Outbound" -ErrorAction SilentlyContinue | Out-Null
Remove-NetFirewallRule -DisplayName "VSCode_Block_Inbound" -ErrorAction SilentlyContinue | Out-Null

Write-Host "Firewall opened. VSCode can now access the internet." -ForegroundColor Green
