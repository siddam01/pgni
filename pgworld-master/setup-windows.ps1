# PG/Hostel Management System - Windows Setup Script
# Run this in PowerShell as Administrator

Write-Host "Setting up PG/Hostel Management System..." -ForegroundColor Green

# Function to check if command exists
function Test-Command($cmdname) {
    return [bool](Get-Command -Name $cmdname -ErrorAction SilentlyContinue)
}

# Check if Flutter is installed
if (Test-Command "flutter") {
    Write-Host "Flutter is already installed" -ForegroundColor Yellow
    flutter --version
}
else {
    Write-Host "Installing Flutter..." -ForegroundColor Blue
    
    # Download Flutter
    $flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.0-stable.zip"
    $tempPath = "$env:TEMP\flutter.zip"
    $extractPath = "C:\flutter"
    
    try {
        Write-Host "Downloading Flutter SDK..." -ForegroundColor Blue
        Invoke-WebRequest -Uri $flutterUrl -OutFile $tempPath
        
        Write-Host "Extracting Flutter SDK..." -ForegroundColor Blue
        Expand-Archive -Path $tempPath -DestinationPath "C:\" -Force
        
        # Add to PATH
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
        if ($currentPath -notlike "*C:\flutter\bin*") {
            Write-Host "Adding Flutter to PATH..." -ForegroundColor Blue
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\flutter\bin", "User")
        }
        
        Write-Host "Flutter installed successfully!" -ForegroundColor Green
        Write-Host "Please restart your terminal or VS Code to use Flutter commands" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Error installing Flutter: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Check if Go is installed
if (Test-Command "go") {
    Write-Host "Go is already installed" -ForegroundColor Yellow
    go version
}
else {
    Write-Host "Installing Go..." -ForegroundColor Blue
    
    try {
        # Download Go
        $goUrl = "https://go.dev/dl/go1.21.5.windows-amd64.msi"
        $tempPath = "$env:TEMP\go.msi"
        
        Write-Host "Downloading Go..." -ForegroundColor Blue
        Invoke-WebRequest -Uri $goUrl -OutFile $tempPath
        
        Write-Host "Installing Go..." -ForegroundColor Blue
        Start-Process msiexec.exe -ArgumentList "/i $tempPath /quiet" -Wait
        
        Write-Host "Go installed successfully!" -ForegroundColor Green
        Write-Host "Please restart your terminal or VS Code to use Go commands" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Error installing Go: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Install additional tools
Write-Host "Installing additional development tools..." -ForegroundColor Blue

# Check if Chocolatey is installed
if (Test-Command "choco") {
    Write-Host "Installing Git via Chocolatey..." -ForegroundColor Blue
    choco install git -y
    
    Write-Host "Installing Android SDK via Chocolatey..." -ForegroundColor Blue
    choco install android-sdk -y
}
else {
    Write-Host "Chocolatey not found. Please install Git and Android SDK manually" -ForegroundColor Yellow
    Write-Host "Git: https://git-scm.com/download/win" -ForegroundColor Yellow
    Write-Host "Android Studio: https://developer.android.com/studio" -ForegroundColor Yellow
}

Write-Host "Setup completed! Please restart your terminal/VS Code and run:" -ForegroundColor Green
Write-Host "flutter doctor" -ForegroundColor Cyan
Write-Host "go version" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Restart VS Code/Terminal" -ForegroundColor White
Write-Host "2. Run 'flutter doctor' to verify Flutter installation" -ForegroundColor White
Write-Host "3. Run 'go version' to verify Go installation" -ForegroundColor White
Write-Host "4. Install Android Studio for Android development" -ForegroundColor White
Write-Host "5. Run 'flutter doctor' again to check Android setup" -ForegroundColor White
