# Advanced FTP Deploy using WinSCP Portable
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$WinSCPLink = "https://winscp.net/download/WinSCP-6.1.2-Automation.zip"
$WinSCPDir = Join-Path $PSScriptRoot "WinSCP"
$ZipFile = Join-Path $PSScriptRoot "winscp.zip"
$ScriptFile = Join-Path $PSScriptRoot "winscp_script.txt"

Write-Host "Downloading WinSCP Automation tools..." -ForegroundColor Cyan
if (-not (Test-Path $WinSCPDir)) {
    Invoke-WebRequest -Uri $WinSCPLink -OutFile $ZipFile
    Expand-Archive -Path $ZipFile -DestinationPath $WinSCPDir -Force
    Remove-Item $ZipFile
}

$ftpHost = "ftp.ess-retail.online"
$ftpUser = "u636310276.harryilhamdi"
$ftpPass = "Vkhjhz12hf!"

# Create WinSCP Script
$scriptContent = @"
open ftp://${ftpUser}:${ftpPass}@${ftpHost}/ -implicit=0
cd /public_html
lcd `"$PSScriptRoot`"
put index.html
put hub.html
put app.js
put data.js
put css\
put js\
put apps\
exit
"@

Set-Content -Path $ScriptFile -Value $scriptContent

Write-Host "`nStarting FTP Upload via WinSCP..." -ForegroundColor Yellow
$winscpExe = Join-Path $WinSCPDir "WinSCP.com"
& $winscpExe /script=$ScriptFile

Write-Host "`nDone!" -ForegroundColor Green
