Write-Host "Building ResQNav APK locally..." -ForegroundColor Green
Write-Host ""

# Navigate to script directory
Set-Location $PSScriptRoot

# Clean previous builds
Write-Host "Step 1: Cleaning previous builds..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host "Step 2: Getting dependencies..." -ForegroundColor Yellow
flutter pub get 2>&1 | Where-Object { $_ -notmatch "deprecated|migrat" }

# Build APK
Write-Host "Step 3: Building APK (this may take 2-5 minutes)..." -ForegroundColor Yellow
flutter build apk --no-tree-shake-icons 2>&1 | Where-Object { $_ -notmatch "deprecated|migrat" }

# Check if build succeeded
$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkPath) {
    Write-Host ""
    Write-Host "SUCCESS! APK built successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "APK Location: $(Get-Item $apkPath | Select-Object -ExpandProperty FullName)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "File Size: $((Get-Item $apkPath).Length / 1MB)MB" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host "1. Connect your Android device via USB"
    Write-Host "2. Enable USB Debugging on your device"
    Write-Host "3. Run: adb install build\app\outputs\flutter-apk\app-release.apk"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: APK build failed!" -ForegroundColor Red
    Write-Host ""
}

Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
