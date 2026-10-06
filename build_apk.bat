@echo off
echo Building ResQNav APK locally...
echo.

REM Navigate to project directory
cd /d "%~dp0"

REM Clean previous builds
echo Cleaning previous builds...
call flutter clean

REM Get dependencies
echo Getting dependencies...
call flutter pub get

REM Build APK
echo Building APK...
call flutter build apk --no-tree-shake-icons

REM Check if build succeeded
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo.
    echo SUCCESS! APK built successfully!
    echo.
    echo APK Location: %cd%\build\app\outputs\flutter-apk\app-release.apk
    echo.
    pause
) else (
    echo.
    echo ERROR: APK build failed!
    echo.
    pause
)
