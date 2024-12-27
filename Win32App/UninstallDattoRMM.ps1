# Pre-checks
if (-not (Test-Path "C:\Program Files (x86)\CentraStage\uninst.exe")) {
    Write-Host "Datto RMM Agent is not installed on this device." -ForegroundColor Yellow
} else {
    # Uninstall
    try {
        Start-Process -FilePath "C:\Program Files (x86)\CentraStage\uninst.exe" -Wait -Verb RunAs
    } catch {
        Write-Host "Failed to uninstall Datto RMM Agent: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Remove remaining files and registry keys
Remove-Item -LiteralPath "C:\Program Files\CentraStage" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\Program Files (x86)\CentraStage" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\Windows\System32\config\systemprofile\AppData\Local\CentraStage" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\CentraStage" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "Registry::HKEY_CLASSES_ROOT\cag" -Force -Recurse -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "Registry::HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" -Name "CentraStage" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "Registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Run" -Name "CentraStage" -Force -ErrorAction SilentlyContinue
Write-Host "Uninstallation complete." -ForegroundColor Green