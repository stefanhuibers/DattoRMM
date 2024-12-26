param (
    [string]$SiteID
)

# Variables
$agentURL = "https://pinotage.centrastage.net/csm/profile/downloadAgent/$SiteID" 
$pathFile = "$env:TEMP\DRMMSetup.exe"

# Checks
if (Get-Service CagService -ErrorAction SilentlyContinue) { exit 0 } 
if (!$SiteID) { exit 1 }

# Download and install
try {
    (New-Object System.Net.WebClient).DownloadFile($AgentURL, $pathFile) 
    Start-Process $pathFile -Wait
    Get-Item -Path $pathFile | Remove-Item -Force
}
catch {
    exit 1
} 