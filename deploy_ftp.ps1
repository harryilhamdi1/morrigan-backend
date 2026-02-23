# FTP Deploy Script for ESS Retail Frontend (FTPS/SSL)
$ftpHost = "ftp://145.79.14.165"
$ftpUser = "u636310276.ess-retail.online"
$ftpPass = "Vkhjhz12hf!"
$localRoot = $PSScriptRoot

$filesToUpload = @("index.html", "hub.html", "app.js", "data.js")
$foldersToUpload = @("css", "js", "apps")

function Upload-FtpFile($localPath, $remotePath) {
    try {
        $uri = "$ftpHost/$remotePath"
        $request = [System.Net.FtpWebRequest]::Create($uri)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $request.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)
        $request.UseBinary = $true
        $request.UsePassive = $true
        $request.EnableSsl = $true
        # Accept any SSL certificate
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

        $fileContent = [System.IO.File]::ReadAllBytes($localPath)
        $request.ContentLength = $fileContent.Length
        $stream = $request.GetRequestStream()
        $stream.Write($fileContent, 0, $fileContent.Length)
        $stream.Close()
        $response = $request.GetResponse()
        $response.Close()
        Write-Host "  OK $remotePath" -ForegroundColor Green
    }
    catch {
        Write-Host "  FAIL $remotePath : $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Create-FtpDirectory($remotePath) {
    try {
        $uri = "$ftpHost/$remotePath"
        $request = [System.Net.FtpWebRequest]::Create($uri)
        $request.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
        $request.Credentials = New-Object System.Net.NetworkCredential($ftpUser, $ftpPass)
        $request.UsePassive = $true
        $request.EnableSsl = $true
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        $response = $request.GetResponse()
        $response.Close()
    }
    catch {}
}

function Upload-FtpFolder($localFolder, $remoteBase) {
    Create-FtpDirectory $remoteBase
    $items = Get-ChildItem -Path $localFolder
    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            Upload-FtpFolder $item.FullName "$remoteBase/$($item.Name)"
        }
        else {
            Upload-FtpFile $item.FullName "$remoteBase/$($item.Name)"
        }
    }
}

Write-Host "`n FTP DEPLOY to ess-retail.online (SSL)`n" -ForegroundColor Cyan

Write-Host "Uploading files..." -ForegroundColor Yellow
foreach ($file in $filesToUpload) {
    $localPath = Join-Path $localRoot $file
    if (Test-Path $localPath) { Upload-FtpFile $localPath "public_html/$file" }
    else { Write-Host "  SKIP $file" -ForegroundColor DarkYellow }
}

Write-Host "`nUploading folders..." -ForegroundColor Yellow
foreach ($folder in $foldersToUpload) {
    $localPath = Join-Path $localRoot $folder
    if (Test-Path $localPath) {
        Write-Host "  Folder: $folder/" -ForegroundColor Cyan
        Upload-FtpFolder $localPath "public_html/$folder"
    }
}

Write-Host "`n DEPLOYMENT COMPLETE! https://ess-retail.online`n" -ForegroundColor Green
