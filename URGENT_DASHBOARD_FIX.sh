#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        URGENT FIX: Add Hostels to Admin Dashboard             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ADMIN_DIR="/home/ec2-user/pgni/pgworld-master"

cd "$ADMIN_DIR"

echo -e "${BLUE}[1/6] Creating backup...${NC}"
BACKUP_DIR="dashboard_backup_$(date +%Y%m%d_%H%M%S)"
cp -r lib "$BACKUP_DIR"
echo -e "${GREEN}✓ Backup created: $BACKUP_DIR${NC}"

echo ""
echo -e "${BLUE}[2/6] Adding Hostels import to dashboard.dart...${NC}"
# Add hostels import after line 6
sed -i '6a import '"'"'./hostels.dart'"'"';' lib/screens/dashboard.dart
echo -e "${GREEN}✓ Import added${NC}"

echo ""
echo -e "${BLUE}[3/6] Adding Hostels card to dashboard...${NC}"
# Create a temporary file with the new Hostels card
cat > /tmp/hostels_card.txt << 'CARD_EOF'
                        new GestureDetector(
                          child: new Card(
                            child: new Container(
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                              child: new Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  new Expanded(
                                    child: new Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: new BoxDecoration(
                                        color: HexColor("#4A90E2"),
                                        shape: BoxShape.circle,
                                      ),
                                      child: new Icon(
                                        Icons.business,
                                        size: 25,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  new Text(
                                    "Hostels",
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: Colors.black,
                                    ),
                                  ),
                                  new Text("Management",
                                      style: new TextStyle(
                                        fontSize: 17,
                                        color: Colors.grey,
                                      )),
                                ],
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              new MaterialPageRoute(
                                  builder: (context) => new HostelsActivity()),
                            );
                          },
                        ),
CARD_EOF

# Insert the Hostels card after the Users card (around line 256)
# We'll insert it after "new GestureDetector," that contains "UsersActivity"
sed -i '/new UsersActivity(null)/,/},/ {
  /},/a \
                        new GestureDetector(\
                          child: new Card(\
                            child: new Container(\
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),\
                              child: new Column(\
                                mainAxisAlignment: MainAxisAlignment.start,\
                                crossAxisAlignment: CrossAxisAlignment.center,\
                                children: <Widget>[\
                                  new Expanded(\
                                    child: new Container(\
                                      padding: EdgeInsets.all(10),\
                                      decoration: new BoxDecoration(\
                                        color: HexColor("#4A90E2"),\
                                        shape: BoxShape.circle,\
                                      ),\
                                      child: new Icon(\
                                        Icons.business,\
                                        size: 25,\
                                        color: Colors.white,\
                                      ),\
                                    ),\
                                  ),\
                                  new Text(\
                                    "Hostels",\
                                    style: TextStyle(\
                                      fontSize: 25,\
                                      color: Colors.black,\
                                    ),\
                                  ),\
                                  new Text("Management",\
                                      style: new TextStyle(\
                                        fontSize: 17,\
                                        color: Colors.grey,\
                                      )),\
                                ],\
                              ),\
                            ),\
                          ),\
                          onTap: () {\
                            Navigator.push(\
                              context,\
                              new MaterialPageRoute(\
                                  builder: (context) => new HostelsActivity()),\
                            );\
                          },\
                        ),
}' lib/screens/dashboard.dart

echo -e "${GREEN}✓ Hostels card added to dashboard${NC}"

echo ""
echo -e "${BLUE}[4/6] Verifying changes...${NC}"
if grep -q "HostelsActivity" lib/screens/dashboard.dart; then
    echo -e "${GREEN}✓ HostelsActivity found in dashboard${NC}"
else
    echo -e "${RED}✗ Failed to add HostelsActivity${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[5/6] Building Admin app...${NC}"
export DART_VM_OPTIONS="--old_gen_heap_size=6144"
flutter clean
flutter pub get
flutter build web --release --base-href="/admin/" --no-source-maps --dart-define=dart.vm.product=true

if [ ! -d "build/web" ]; then
    echo -e "${RED}✗ Build failed!${NC}"
    echo ""
    echo "Restoring from backup..."
    rm -rf lib
    mv "$BACKUP_DIR" lib
    exit 1
fi

FILE_COUNT=$(find build/web -type f | wc -l)
echo -e "${GREEN}✓ Admin app built successfully ($FILE_COUNT files)${NC}"

echo ""
echo -e "${BLUE}[6/6] Deploying to Nginx...${NC}"
sudo rm -rf /usr/share/nginx/html/admin/*
sudo cp -r build/web/* /usr/share/nginx/html/admin/
sudo chown -R nginx:nginx /usr/share/nginx/html/admin/
sudo chmod -R 755 /usr/share/nginx/html/admin/

# Fix SELinux if needed
if command -v sestatus &> /dev/null; then
    sudo chcon -R -t httpd_sys_content_t /usr/share/nginx/html/admin/
fi

sudo systemctl reload nginx
echo -e "${GREEN}✓ Deployed to Nginx${NC}"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    DEPLOYMENT COMPLETE! ✓                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}📱 ACCESS YOUR ADMIN PORTAL:${NC}"
echo ""
echo "   URL:      http://54.227.101.30/admin/"
echo "   Login:    admin@example.com"
echo "   Password: admin123"
echo ""
echo -e "${YELLOW}🎯 WHAT'S NEW:${NC}"
echo ""
echo "   ✅ Hostels Management card added to dashboard"
echo "   ✅ Click the Hostels card to access full CRUD operations"
echo "   ✅ Add, Edit, Delete hostels"
echo "   ✅ Manage amenities"
echo ""
echo -e "${BLUE}📋 NEXT STEPS:${NC}"
echo ""
echo "   1. Hard refresh your browser (Ctrl+Shift+R)"
echo "   2. You should now see 6 cards including Hostels"
echo "   3. Click Hostels to start managing your PGs!"
echo ""
echo "═══════════════════════════════════════════════════════════════"

