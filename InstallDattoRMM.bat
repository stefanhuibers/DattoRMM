@echo off
title Install Datto RMM
cls
echo ===============================
echo  Install Datto RMM
echo  Powered by Xantion ICT
echo ===============================
echo.
set /p SiteId=Please enter the Site ID: 
echo.
powershell.exe -ExecutionPolicy Bypass -File "Win32App\InstallDattoRMM.ps1" -SiteId %SiteId%
echo.
pause