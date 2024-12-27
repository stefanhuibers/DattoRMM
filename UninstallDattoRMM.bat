@echo off
title Uninstall Datto RMM
cls
echo ===============================
echo  Uninstall Datto RMM
echo  Powered by Xantion ICT
echo ===============================
echo.
powershell.exe -ExecutionPolicy Bypass -File "Win32App\UninstallDattoRMM.ps1"
echo.
pause