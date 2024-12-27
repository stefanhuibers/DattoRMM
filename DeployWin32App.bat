@echo off
title Deploy Win32App Datto RMM
cls
echo ===============================
echo  Deploy Win32App Datto RMM
echo  Powered by Xantion ICT
echo ===============================
echo.
set /p SiteId=Please enter the Site ID: 
echo.
powershell.exe -ExecutionPolicy Bypass -File "DeployWin32App.ps1"
echo.
pause