#!/bin/bash
###############################################################################
# MANUAL DEPLOYMENT - Upload from Local Machine
# Since pre-built files aren't in Git, we'll upload directly
###############################################################################

echo "=========================================="
echo "CloudPG - Manual Deployment Guide"
echo "=========================================="
echo ""

cat << 'EOF'

OPTION 1: SCP FROM YOUR WINDOWS MACHINE
========================================

Step 1: Open PowerShell on your Windows machine

Step 2: Navigate to project directory:
cd C:\MyFolder\Mytest\pgworld-master

Step 3: Create zip files:
Compress-Archive -Path pgworld-master\build\web\* -DestinationPath admin-build.zip
Compress-Archive -Path pgworldtenant-master\build\web\* -DestinationPath tenant-build.zip

Step 4: Copy to EC2 (replace with your key file path):
scp -i "YOUR_KEY.pem" admin-build.zip ec2-user@54.227.101.30:/tmp/
scp -i "YOUR_KEY.pem" tenant-build.zip ec2-user@54.227.101.30:/tmp/

Step 5: SSH to EC2:
ssh -i "YOUR_KEY.pem" ec2-user@54.227.101.30

Step 6: On EC2, run these commands:

# Backup current deployment
sudo mkdir -p /var/www/backups/$(date +%Y%m%d_%H%M%S)
sudo cp -r /var/www/admin /var/www/backups/$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true
sudo cp -r /var/www/tenant /var/www/backups/$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true

# Extract and deploy admin
cd /tmp
unzip -q admin-build.zip -d admin-build
sudo rm -rf /var/www/admin
sudo mkdir -p /var/www/admin
sudo cp -r admin-build/* /var/www/admin/
sudo chown -R nginx:nginx /var/www/admin 2>/dev/null || sudo chown -R www-data:www-data /var/www/admin
sudo chmod -R 755 /var/www/admin

# Extract and deploy tenant
unzip -q tenant-build.zip -d tenant-build
sudo rm -rf /var/www/tenant
sudo mkdir -p /var/www/tenant
sudo cp -r tenant-build/* /var/www/tenant/
sudo chown -R nginx:nginx /var/www/tenant 2>/dev/null || sudo chown -R www-data:www-data /var/www/tenant
sudo chmod -R 755 /var/www/tenant

# Restart nginx
sudo systemctl restart nginx

# Cleanup
rm -rf /tmp/admin-build* /tmp/tenant-build*

echo "✅ Deployment complete!"
echo "Admin: http://54.227.101.30/admin/"
echo "Tenant: http://54.227.101.30/tenant/"


OPTION 2: USE WinSCP (Easier for Windows)
==========================================

1. Download WinSCP: https://winscp.net/
2. Connect to EC2:
   - Host: 54.227.101.30
   - User: ec2-user
   - Use your .pem key file
3. Upload:
   - pgworld-master/build/web/* → /tmp/admin/
   - pgworldtenant-master/build/web/* → /tmp/tenant/
4. In terminal (via WinSCP or SSH):
   sudo rm -rf /var/www/admin /var/www/tenant
   sudo mv /tmp/admin /var/www/admin
   sudo mv /tmp/tenant /var/www/tenant
   sudo chown -R nginx:nginx /var/www/admin /var/www/tenant
   sudo systemctl restart nginx


OPTION 3: Direct Git Push of Build Files
=========================================

We'll force-add build files to a deployment branch:

# On Windows machine:
cd C:\MyFolder\Mytest\pgworld-master
git checkout -b deployment-with-builds
git add -f pgworld-master/build/web/
git add -f pgworldtenant-master/build/web/
git commit -m "Add pre-built files for deployment"
git push -f origin deployment-with-builds

# Then on EC2:
cd /tmp
git clone https://github.com/siddam01/pgni.git pgworld-deploy
cd pgworld-deploy
git checkout deployment-with-builds

sudo rm -rf /var/www/admin /var/www/tenant
sudo cp -r pgworld-master/build/web /var/www/admin
sudo cp -r pgworldtenant-master/build/web /var/www/tenant
sudo chown -R nginx:nginx /var/www/admin /var/www/tenant
sudo systemctl restart nginx

EOF

