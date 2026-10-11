@echo off
title Smart Placement System - Public URL Tunnel
cls
echo ===================================================
echo   Smart Placement System - Public Tunnel Launcher
echo ===================================================
echo.
echo Make sure Tomcat is running on port 8080.
echo Creating secure HTTPS tunnel...
echo.
"%~dp0cloudflared.exe" tunnel --url http://localhost:8080
pause
