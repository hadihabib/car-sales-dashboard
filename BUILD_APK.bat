@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
    echo Flutter not found. Use GitHub Actions instead.
    pause
    exit /b 1
)

if not exist android (
    flutter create . --platforms=android
    if errorlevel 1 goto error
)

flutter pub get
if errorlevel 1 goto error

flutter build apk --release
if errorlevel 1 goto error

echo.
echo APK READY:
echo build\app\outputs\flutter-apk\app-release.apk
pause
exit /b 0

:error
echo BUILD FAILED.
pause
exit /b 1
