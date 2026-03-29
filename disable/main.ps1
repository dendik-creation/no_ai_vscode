$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script can run only as administrator." -ForegroundColor Yellow
    exit
}

Write-Host "Checking connection..." -ForegroundColor Cyan
if (!(Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet)) {
    Write-Host "No internet connection detected. Please connect to the internet and try again." -ForegroundColor Red
    pause
    exit
}
Write-Host "Internet connection established." -ForegroundColor Green

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n[Disabling AI features VSCode...]" -ForegroundColor Cyan
& "$scriptDir\disable_ai.ps1"
Write-Host ""

Write-Host "`n[Blocking VSCode firewall...]" -ForegroundColor Yellow
& "$scriptDir\block_firewall.ps1"
Write-Host ""

Write-Host "`n[Say goodbye for AI in VSCode]" -ForegroundColor Cyan
exit
