if (Get-Service CagService -ErrorAction SilentlyContinue) {
    Write-Output "Datto RMM Agent already installed on this device"
    exit 0
} else {
    Write-Output "Datto RMM Agent not installed on this device"
    exit 1
}