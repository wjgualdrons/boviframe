# scripts\build_android.ps1
# Usage: .\scripts\build_android.ps1
# Builds Android release APK and AAB. Requires flutter in PATH (Windows PowerShell).

param()

function Assert-Command($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Error "$name not found in PATH. Install Flutter and add to PATH."; exit 1
  }
}

Assert-Command flutter

Write-Host "Running flutter pub get"
flutter pub get

Write-Host "Building release APK"
flutter build apk --release
$apkPath = Join-Path -Path "build\app\outputs\flutter-apk" -ChildPath "app-release.apk"
if (Test-Path $apkPath) { Write-Host "APK created: $apkPath" } else { Write-Warning "APK not found at $apkPath" }

Write-Host "Building App Bundle (AAB)"
flutter build appbundle --release
$aabPath = Join-Path -Path "build\app\outputs\bundle\release" -ChildPath "app-release.aab"
if (Test-Path $aabPath) { Write-Host "AAB created: $aabPath" } else { Write-Warning "AAB not found at $aabPath" }

Write-Host "Done. To install the APK on a device: adb install -r $apkPath"