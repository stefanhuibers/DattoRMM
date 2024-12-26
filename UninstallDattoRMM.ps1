# Uninstall
Start-Process -FilePath "C:\Program Files (x86)\CentraStage\uninst.exe" -Wait -Verb RunAs
Remove-Item -LiteralPath "C:\Program Files\CentraStage" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\Program Files (x86)\CentraStage" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\Windows\System32\config\systemprofile\AppData\Local\CentraStage" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -LiteralPath "C:\Windows\SysWOW64\config\systemprofile\AppData\Local\CentraStage" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item "Registry::HKEY_CLASSES_ROOT\cag" -Force -Recurse -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "Registry::HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" -Name "CentraStage" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "Registry::HKLM\Software\Microsoft\Windows\CurrentVersion\Run" -Name "CentraStage" -Force -ErrorAction SilentlyContinue