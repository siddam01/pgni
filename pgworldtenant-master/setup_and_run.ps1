# Flutter Setup and Run Script
Set-Location "C:\MyFolder\Mytest\pgworld-master\pgworldtenant-master"
$env:PATH = "C:\flutter\bin;" + $env:PATH

Write-Host "Current Directory: $(Get-Location)"
Write-Host "Flutter Version:"
flutter --version

Write-Host "Checking pubspec.yaml:"
if (Test-Path "pubspec.yaml") {
    Write-Host "✓ pubspec.yaml found"
}
else {
    Write-Host "✗ pubspec.yaml not found"
    exit 1
}

Write-Host "Running Flutter on Chrome..."
flutter run -d chrome --web-port=8080
