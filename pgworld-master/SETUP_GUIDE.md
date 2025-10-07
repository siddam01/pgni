# PG/Hostel Management System - Setup Guide

## Prerequisites Installation (Windows)

### 1. Install Flutter SDK

#### Step-by-step Flutter Installation:

1. **Download Flutter SDK**

   ```powershell
   # Download from: https://docs.flutter.dev/get-started/install/windows
   # Extract to: C:\flutter
   ```

2. **Add to PATH Environment Variable**

   ```powershell
   # Add C:\flutter\bin to your PATH
   # Open System Properties > Environment Variables > Path > New > C:\flutter\bin
   ```

3. **Verify Installation**
   ```powershell
   flutter doctor
   ```

### 2. Install Go (for Backend API)

#### Step-by-step Go Installation:

1. **Download Go**

   ```powershell
   # Download from: https://golang.org/dl/
   # Install go1.21.x.windows-amd64.msi
   ```

2. **Verify Installation**
   ```powershell
   go version
   ```

### 3. Install Dependencies

#### Flutter Main App Dependencies:

```powershell
cd "c:\MyFolder\Mytest\pgworld-master\pgworld-master"
flutter pub get
```

#### Flutter Tenant App Dependencies:

```powershell
cd "c:\MyFolder\Mytest\pgworld-master\pgworldtenant-master"
flutter pub get
```

#### Go Backend Dependencies:

```powershell
cd "c:\MyFolder\Mytest\pgworld-master\pgworld-api-master"
go mod init pgworld-api
go mod tidy
```

## Quick Installation Script (Windows)

### Download Flutter SDK

```powershell
# Run this in PowerShell as Administrator
$flutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.16.0-stable.zip"
$tempPath = "$env:TEMP\flutter.zip"
$extractPath = "C:\flutter"

# Download Flutter
Invoke-WebRequest -Uri $flutterUrl -OutFile $tempPath
Expand-Archive -Path $tempPath -DestinationPath "C:\" -Force

# Add to PATH (requires restart or new terminal)
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*C:\flutter\bin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\flutter\bin", "User")
}
```

### Download Go

```powershell
# Download and install Go
$goUrl = "https://go.dev/dl/go1.21.5.windows-amd64.msi"
$tempPath = "$env:TEMP\go.msi"
Invoke-WebRequest -Uri $goUrl -OutFile $tempPath
Start-Process msiexec.exe -ArgumentList "/i $tempPath /quiet" -Wait
```

## Running the Applications

### 1. Start Backend API

```bash
cd pgworld-api-master
# Set environment variables
export dbConfig="user:password@tcp(localhost:3306)/database"
export connectionPool="10"
export s3Bucket="your-s3-bucket"
# ... other env vars

go run main.go
```

### 2. Run Flutter Apps

```bash
# Main Management App
cd pgworld-master
flutter run

# Tenant App
cd pgworldtenant-master
flutter run
```

## Environment Setup Required

### Database (MySQL)

- Create database schema
- Configure connection string
- Run migrations if available

### AWS Services

- S3 bucket for file storage
- API Gateway setup
- Lambda functions (optional)

### External Services

- Razorpay account for payments
- OneSignal for push notifications
- Firebase for analytics

## Development Tools

- VS Code with Flutter/Dart extensions
- Android Studio for Android development
- Xcode for iOS development (macOS only)
