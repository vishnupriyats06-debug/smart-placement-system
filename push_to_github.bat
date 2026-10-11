@echo off
title Push Smart Placement System to GitHub & Auto-Deploy
color 0B
cls
echo ================================================================
echo    SMART PLACEMENT SYSTEM - 1-CLICK REDEPLOY TO GITHUB & RENDER
echo ================================================================
echo.

:: 1. Check for Git
set "GIT_EXE=%TEMP%\mingit\cmd\git.exe"
if not exist "%GIT_EXE%" (
    where git >nul 2>nul
    if %errorlevel% equ 0 (
        set "GIT_EXE=git"
    ) else (
        echo [ERROR] Git was not found!
        pause
        exit /b 1
    )
)

:: 2. Rebuild SmartPlacementSystem.war automatically from WebContent
echo [1/4] Packaging updated SmartPlacementSystem.war...
where jar >nul 2>nul
if %errorlevel% equ 0 (
    pushd WebContent
    jar -cf ..\SmartPlacementSystem.war *
    popd
    echo       Package created successfully.
) else (
    echo       [NOTE] jar command not in PATH, using current WAR file.
)

:: 3. Sync to local XAMPP if present
if exist "C:\xampp\tomcat\webapps" (
    echo [2/4] Syncing to local XAMPP Tomcat...
    copy /y "SmartPlacementSystem.war" "C:\xampp\tomcat\webapps\SmartPlacementSystem.war" >nul 2>nul
    xcopy /s /e /y /q "WebContent\*" "C:\xampp\tomcat\webapps\SmartPlacementSystem\" >nul 2>nul
)

:: 4. Stage and commit changes to Git
echo [3/4] Staging & Committing changes to Git...
"%GIT_EXE%" add .
set "COMMIT_MSG=Updated SmartPlacementSystem - %date% %time%"
"%GIT_EXE%" commit -m "%COMMIT_MSG%"

:: 5. Push to GitHub
echo [4/4] Pushing to GitHub...
"%GIT_EXE%" push origin main

echo.
echo ================================================================
if %errorlevel% equ 0 (
    echo  [SUCCESS] All changes pushed to GitHub!
    echo.
    echo  - Your live hosting (Render) will now auto-detect this push
    echo    and redeploy your site in 1 to 2 minutes.
    echo  - Live URL: https://smart-placement-system-g7ew.onrender.com/
) else (
    echo  [NOTE] If push failed, please check your network connection.
)
echo ================================================================
echo.
pause
