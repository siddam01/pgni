# Quick deployment script for Windows PowerShell
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "🚀 DEPLOYING HOSTELS MODULE TO EC2" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

$commands = @"
cd /home/ec2-user/pgworld-master && \
echo '📥 [1/6] Pulling latest code...' && \
git pull origin main && \
cd pgworld-master && \
echo '🧹 [2/6] Cleaning previous build...' && \
flutter clean && \
echo '📦 [3/6] Installing dependencies...' && \
flutter pub get && \
echo '🔨 [4/6] Building web app...' && \
flutter build web --release --base-href='/admin/' --no-source-maps && \
echo '🚀 [5/6] Deploying to Nginx...' && \
sudo rm -rf /usr/share/nginx/html/admin/* && \
sudo cp -r build/web/* /usr/share/nginx/html/admin/ && \
sudo chown -R nginx:nginx /usr/share/nginx/html/admin && \
sudo chmod -R 755 /usr/share/nginx/html/admin && \
echo '♻️  [6/6] Reloading Nginx...' && \
sudo systemctl reload nginx && \
echo '' && \
echo '✅ DEPLOYMENT COMPLETE!' && \
echo '🌐 Access: http://54.227.101.30/admin/' && \
echo '' && \
echo '📊 Verification:' && \
curl -I http://localhost/admin/ 2>&1 | grep 'HTTP' && \
echo '' && \
echo '📁 Files deployed:' && \
ls -lh /usr/share/nginx/html/admin/ | head -10
"@

Write-Host "Connecting to EC2 and deploying..." -ForegroundColor Yellow
Write-Host ""

# Note: This would require SSH client. For Windows, we'll create the command to run manually
Write-Host "⚠️  Please run this command in your terminal:" -ForegroundColor Yellow
Write-Host ""
Write-Host "ssh ec2-user@54.227.101.30 -T << 'ENDSSH'" -ForegroundColor Green
Write-Host $commands -ForegroundColor Green
Write-Host "ENDSSH" -ForegroundColor Green
Write-Host ""
Write-Host "OR use Git Bash / WSL / PuTTY with the above commands" -ForegroundColor Yellow

