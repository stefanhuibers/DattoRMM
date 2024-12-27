param (
    [string]$SiteId
)

# Variables
$agentURL = "https://pinotage.centrastage.net/csm/profile/downloadAgent/$SiteID" 
$pathFile = "$env:TEMP\DRMMSetup.exe"

# Pre-checks
if (Get-Service CagService -ErrorAction SilentlyContinue) { 
    Write-Host "CagService is already running."
    Write-Host "Exiting script."
    exit 0 
} 
if (!$SiteID) { 
    Write-Host "SiteID is not provided."
    Write-Host "Exiting script."
    exit 1 
}

# Download
try {
    Write-Host "Downloading agent."
    (New-Object System.Net.WebClient).DownloadFile($AgentURL, $pathFile) 
    if (Test-Path $pathFile) {
        Write-Host "Download complete."
    } else {
        Write-Host "Download failed."
        Write-Host "Exiting script."
        exit 1
    }
}
catch {
    Write-Host "Download failed."
    Write-Host "Exiting script."
    exit 1
}

# Install
Write-Host "Installing agent."
Start-Process $pathFile
$timeout = 120
$elapsed = 0
while (-not (Get-Service -Name "CagService" -ErrorAction SilentlyContinue) -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 5
    $elapsed += 5
}

# Check
if ($elapsed -ge $timeout) {
    Write-Host "Installation failed."
    Write-Host "Exiting script."
    exit 1
} else {
    Write-Host "Installation complete."
}

# Cleanup
try {
    Write-Host "Removing setup file."
    Get-Item -Path $pathFile | Remove-Item -Force -ErrorAction Stop
    Write-Host "Setup file removed."        
} catch {
    Write-Host "Error removing setup file."
    Write-Host "Exiting script."
    exit 1
}
Write-Host "Exiting script."
exit 0