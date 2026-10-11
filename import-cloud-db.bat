@echo off
title TiDB Cloud Database Importer
cls
echo ========================================================
echo   TiDB Cloud Database Importer - Smart Placement System
echo ========================================================
echo.
java -cp "WebContent/WEB-INF/lib/*;WebContent/WEB-INF/classes" com.placement.CloudDBImporter
echo.
pause
