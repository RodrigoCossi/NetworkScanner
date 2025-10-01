@echo off
:: Network Scanner Launcher

title Network Scanner
color 0B

echo.
echo ========================================
echo            Network Scanner
echo ========================================
echo.
echo Starting comprehensive network analysis...
echo - Auto-installing Ookla Speedtest CLI if needed
echo - Detailed speed test with bufferbloat analysis
echo - Complete connectivity assessment
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0NetworkScanner.ps1"

echo.
echo Analysis complete! 
echo.
pause
exit
