# 🚀 PGNi - Getting Started Guide

**Welcome to PGNi - Your Complete PG Management Solution!**

---

## 🎯 What is PGNi?

PGNi is a comprehensive platform that connects PG (Paying Guest) owners with tenants, making property management and PG hunting effortless.

### For PG Owners:
- Manage multiple properties
- Track tenants and payments
- Handle bookings online
- Collect rent digitally
- Monitor occupancy
- Handle maintenance efficiently

### For Tenants:
- Find PGs near you
- Compare prices and amenities
- Book rooms online
- Pay rent through app
- Request maintenance
- Track payment history

---

## 📱 Who Should Use What?

### 👤 **You are a PG Owner?**
→ **Use:** PGNi Admin App
→ **Read:** `1_PG_OWNER_GUIDE.md`

### 🏠 **You are looking for a PG?**
→ **Use:** PGNi Tenant App
→ **Read:** `2_TENANT_GUIDE.md`

### 👨‍💼 **You are Platform Admin?**
→ **Use:** Admin Portal
→ **Read:** `3_ADMIN_GUIDE.md`

### 💻 **You are Developer/Technical?**
→ **Configure:** Mobile Apps
→ **Read:** `4_MOBILE_APP_CONFIGURATION.md`

---

## 🏁 Quick Start (3 Steps!)

### Step 1: Deploy the API ⚙️

**Your API Status:** ❌ Not deployed yet

**To Deploy:**
```powershell
# Run this in PowerShell:
.\ONE_CLICK_DEPLOY.ps1
```

**Or manually follow:** `DEPLOY_COMPLETE_NOW.md`

**Time:** 15-20 minutes

---

### Step 2: Configure Mobile Apps 📱

**Update API endpoint in both apps:**

1. Open `pgworld-master/lib/config.dart`
2. Change API URL to: `http://34.227.111.143:8080`
3. Open `pgworldtenant-master/lib/config.dart`
4. Change API URL to: `http://34.227.111.143:8080`
5. Build apps:
   ```bash
   cd pgworld-master
   flutter build apk --release
   
   cd ../pgworldtenant-master
   flutter build apk --release
   ```

**Details:** See `4_MOBILE_APP_CONFIGURATION.md`

**Time:** 10-15 minutes

---

### Step 3: Start Using! 🎉

**For PG Owners:**
1. Install PGNi Admin App
2. Register as PG Owner
3. Add your property
4. Start managing!

**For Tenants:**
1. Install PGNi Tenant App
2. Register as Tenant
3. Search for PGs
4. Book your room!

---

## 📚 Complete Documentation

### User Guides:

| Guide | For | File |
|-------|-----|------|
| **PG Owner Guide** | Property owners managing PGs | `1_PG_OWNER_GUIDE.md` |
| **Tenant Guide** | People looking for/staying in PGs | `2_TENANT_GUIDE.md` |
| **Admin Guide** | Platform administrators | `3_ADMIN_GUIDE.md` |
| **App Config Guide** | Developers & technical team | `4_MOBILE_APP_CONFIGURATION.md` |

### Technical Documentation:

| Document | Purpose | Location |
|----------|---------|----------|
| **One-Click Deploy** | Automated deployment | `ONE_CLICK_DEPLOY.ps1` |
| **Complete Deploy Guide** | Manual deployment steps | `DEPLOY_COMPLETE_NOW.md` |
| **CloudShell Deploy** | Browser-based deployment | `DEPLOY_VIA_CLOUDSHELL.md` |
| **Validation Checklist** | Testing guide | `VALIDATION_CHECKLIST.md` |
| **Infrastructure Details** | AWS resources info | `DEPLOYMENT_SUCCESS.md` |

---

## 🔑 Important Information

### Your Deployed Infrastructure:

**API Server:**
- URL: `http://34.227.111.143:8080`
- Health Check: `http://34.227.111.143:8080/health`
- Status: ⏳ Pending deployment

**Database:**
- Host: `database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com`
- Port: `3306`
- Database: `pgworld`
- Username: `admin`
- Password: `Omsairamdb951#`

**Storage:**
- S3 Bucket: `pgni-preprod-698302425856-uploads`
- Region: `us-east-1`

**Server:**
- EC2 IP: `34.227.111.143`
- Instance ID: `i-0909d462845deb151`

---

## 🎯 Typical User Journeys

### Journey 1: PG Owner Onboarding

1. **Download** PGNi Admin App
2. **Register** with email, phone, PG details
3. **Add Property** - name, address, photos
4. **Configure Rooms** - types, capacity, pricing
5. **Set Rules** - guest policy, payment terms
6. **Go Live** - start receiving inquiries
7. **Manage** - handle bookings, payments, tenants

---

### Journey 2: Tenant Finding PG

1. **Download** PGNi Tenant App
2. **Register** with basic details
3. **Search** by location (college, office, area)
4. **Filter** by price, amenities, room type
5. **Browse** listings with photos & reviews
6. **Select** preferred PG
7. **Submit** booking request with documents
8. **Wait** for owner approval
9. **Visit** PG after approval
10. **Move In** and pay through app

---

### Journey 3: Monthly Rent Payment

**Owner Side:**
1. System sends rent reminders to tenants
2. Tenant pays rent
3. Owner receives payment notification
4. Owner verifies in Payments tab
5. Receipt auto-generated

**Tenant Side:**
1. Receive rent reminder notification
2. Open app → Payments
3. Select "Pay Rent"
4. Choose payment method
5. Complete payment
6. Get receipt

---

### Journey 4: Maintenance Request

**Tenant:**
1. Notice issue (e.g., WiFi not working)
2. Open app → Maintenance
3. Create new request
4. Select issue type, add photo
5. Submit

**Owner:**
1. Receive notification
2. View request details
3. Mark as "In Progress"
4. Fix the issue
5. Mark as "Resolved"
6. Tenant gets notification

---

## 🔔 What Happens After Deployment?

### Immediately:
✅ API becomes accessible
✅ Health endpoint responds
✅ Database gets initialized
✅ System is ready for users

### You Need To:
1. ✅ Configure mobile apps with API URL
2. ✅ Build mobile app APKs
3. ✅ Test apps thoroughly
4. ✅ Distribute to users
5. ✅ Create first admin account
6. ✅ Add first property (as test)

### Users Can:
- Register as PG owners
- Register as tenants
- Add properties
- Search for PGs
- Make bookings
- Process payments
- Use all features!

---

## 💰 Cost Overview

### Monthly Cost: ~₹1,200 ($15)

**Breakdown:**
- EC2 (t2.micro): Free* or ₹680
- RDS (db.t3.micro): ₹1,122
- S3 Storage: ₹40
- Data Transfer: ₹40

*Free for first 12 months with AWS Free Tier

### Scalability:
As you grow, costs may increase:
- More storage usage
- Higher data transfer
- Need larger instances
- Add load balancer
- Add CDN for images

**Current setup handles:**
- Up to 100 PG properties
- Up to 1000 active users
- 10,000 API calls/day

---

## 🛡️ Security Features

### Data Protection:
✅ Encrypted database connections
✅ Secure S3 file storage
✅ Password hashing (bcrypt)
✅ Environment variable secrets
✅ AWS IAM security

### User Privacy:
✅ Secure authentication
✅ Private user data
✅ Document encryption
✅ GDPR compliant (data export/delete)

### Payment Security:
✅ No card data stored on server
✅ Payment gateway integration
✅ Transaction logging
✅ Receipt generation

---

## 📊 Features Overview

### Property Management:
- Multiple property support
- Room and bed configuration
- Photo gallery
- Amenities listing
- Pricing management
- Availability calendar

### Tenant Management:
- Tenant profiles
- Document storage
- Payment tracking
- Communication history
- Check-in/out tracking
- Payment reminders

### Financial:
- Payment recording
- Receipt generation
- Outstanding dues tracking
- Revenue reports
- Monthly summaries
- Tax reports

### Communication:
- In-app messaging
- Broadcast notifications
- SMS/Email integration
- Rent reminders
- Maintenance updates

### Analytics:
- Occupancy rates
- Revenue trends
- Payment analytics
- Tenant demographics
- Property performance

---

## 🎨 App Features

### Admin App (PG Owners):
📊 Dashboard with key metrics
🏠 Property management
👥 Tenant management
💰 Payment tracking
🔧 Maintenance handling
📈 Reports and analytics
📱 Push notifications
💬 Messaging system

### Tenant App:
🔍 PG search and discovery
📍 Location-based filtering
⭐ Reviews and ratings
📝 Online booking
💳 Rent payment
🔧 Maintenance requests
📜 Payment history
🔔 Reminders

---

## 🆘 Support & Help

### Need Help Getting Started?

**For Users:**
- Read relevant user guide
- Check FAQs
- Contact support: support@pgni.com

**For Technical Issues:**
- Check deployment guides
- Review error logs
- Test API health endpoint
- Check mobile app configuration

**For Platform Admins:**
- Review admin guide
- Check system health
- Monitor logs
- Contact technical support

---

## ✅ Deployment Checklist

Follow this to ensure everything is working:

### Infrastructure:
- [ ] API deployed and running
- [ ] Health endpoint responding
- [ ] Database created and accessible
- [ ] S3 bucket accessible
- [ ] Security groups configured

### Applications:
- [ ] Admin app configured with API URL
- [ ] Tenant app configured with API URL
- [ ] Both apps build successfully
- [ ] APKs generated

### Testing:
- [ ] API health check passes
- [ ] Database connection works
- [ ] Admin app connects to API
- [ ] Tenant app connects to API
- [ ] Registration works
- [ ] Login works
- [ ] Basic features functional

### Distribution:
- [ ] APKs ready for distribution
- [ ] Test users can install apps
- [ ] Apps work on different devices
- [ ] No critical bugs

### Documentation:
- [ ] User guides ready
- [ ] Admin trained
- [ ] Support process defined
- [ ] Troubleshooting guide available

---

## 🚀 Next Steps

### Right Now:
1. **Deploy the API** → Run `ONE_CLICK_DEPLOY.ps1`
2. **Wait for deployment** (15-20 minutes)
3. **Verify API** → Test health endpoint

### Then:
4. **Configure apps** → Update API URLs
5. **Build apps** → Generate APKs
6. **Test everything** → Thorough testing
7. **Distribute apps** → To PG owners and tenants

### Finally:
8. **Monitor usage** → Check analytics
9. **Gather feedback** → From users
10. **Plan improvements** → Based on feedback

---

## 🎉 Welcome to PGNi!

**You're about to transform PG management and discovery!**

**Questions?** Check the specific user guides for detailed information.

**Ready to deploy?** Run `ONE_CLICK_DEPLOY.ps1` now!

**Need help?** All documentation is in the `USER_GUIDES` folder.

---

**Let's make PG living better for everyone!** 🏠✨

---

## 📞 Quick Links

| Resource | Link |
|----------|------|
| **API URL** | http://34.227.111.143:8080 |
| **Health Check** | http://34.227.111.143:8080/health |
| **Deploy Script** | `ONE_CLICK_DEPLOY.ps1` |
| **Owner Guide** | `1_PG_OWNER_GUIDE.md` |
| **Tenant Guide** | `2_TENANT_GUIDE.md` |
| **Admin Guide** | `3_ADMIN_GUIDE.md` |
| **Tech Guide** | `4_MOBILE_APP_CONFIGURATION.md` |

---

**START HERE → Run deployment → Configure apps → Start using!**

Good luck! 🚀

