@echo off
echo Setting up PG/Hostel Management System...
echo.

echo Checking if Flutter is installed...
flutter --version >nul 2>&1
if errorlevel 1 (
    echo Flutter is not installed. Please run setup-windows.ps1 first.
    echo Or install Flutter manually from: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
) else (
    echo Flutter is installed!
    flutter --version
)

echo.
echo Checking if Go is installed...
go version >nul 2>&1
if errorlevel 1 (
    echo Go is not installed. Please run setup-windows.ps1 first.
    echo Or install Go manually from: https://golang.org/dl/
    pause
    exit /b 1
) else (
    echo Go is installed!
    go version
)

echo.
echo Installing Flutter dependencies for Main App...
cd /d "%~dp0"
flutter pub get
if errorlevel 1 (
    echo Error installing Flutter dependencies
    pause
    exit /b 1
)

echo.
echo Installing Flutter dependencies for Tenant App...
cd /d "%~dp0..\pgworldtenant-master"
flutter pub get
if errorlevel 1 (
    echo Error installing Flutter dependencies for Tenant App
    pause
    exit /b 1
)

echo.
echo Installing Go dependencies for Backend API...
cd /d "%~dp0..\pgworld-api-master"
if not exist go.mod (
    echo Initializing Go module...
    go mod init pgworld-api
)
go mod tidy
if errorlevel 1 (
    echo Error installing Go dependencies
    pause
    exit /b 1
)

echo.
echo Setup completed successfully!
echo.
echo To run the applications:
echo 1. Backend API: cd pgworld-api-master && go run main.go
echo 2. Main App: cd pgworld-master && flutter run
echo 3. Tenant App: cd pgworldtenant-master && flutter run
echo.
pause
