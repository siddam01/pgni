# 👨‍💼 PGNi - Admin/Super User Complete Guide

**System Administration Guide for PGNi Platform**

---

## 🎯 Admin Role Overview

As an Admin, you have full control over:
- Platform configuration
- User management (Owners & Tenants)
- System monitoring
- Reports and analytics
- Payment oversight
- Support tickets
- Content moderation

---

## 🔐 Admin Access

### Login Credentials

**Admin Portal URL:** http://34.227.111.143:8080/admin

**Initial Setup:**
- Username: `admin`
- Password: Set during first deployment
- **Change immediately after first login!**

### Security Best Practices

✅ Use strong password (min 12 characters)
✅ Enable two-factor authentication
✅ Don't share admin credentials
✅ Log out after session
✅ Use VPN when accessing remotely
✅ Review access logs regularly

---

## 🏠 Dashboard Overview

### Admin Dashboard Shows:

**System Health**
- API Status: 🟢 Running
- Database: 🟢 Connected
- S3 Storage: 🟢 Available
- Server Load: XX%
- Memory Usage: XX%

**Key Metrics**
- Total PG Owners: XXX
- Total Tenants: XXX
- Active Bookings: XXX
- Total Properties: XXX
- Today's Revenue: ₹XX,XXX
- Month's Revenue: ₹X,XX,XXX

**Recent Activity**
- New registrations
- New bookings
- Payments processed
- Support tickets
- System alerts

---

## 👥 User Management

### Manage PG Owners

**View All Owners:**
1. Go to **"Users"** → **"PG Owners"**
2. See list with:
   - Name
   - Email
   - Phone
   - Properties count
   - Status (Active/Suspended)
   - Join date

**Owner Details:**
- Click on any owner to see:
  - Full profile
  - Properties list
  - Financial summary
  - Tenant count
  - Payment history
  - Verification status
  - Documents

**Actions:**
- ✅ **Verify Owner** - Mark as verified
- 🔒 **Suspend Account** - Temporarily disable
- 🗑️ **Delete Account** - Permanent removal
- 📧 **Send Email** - Contact owner
- 📊 **View Reports** - Owner's analytics

**Verification Process:**
1. Review submitted documents:
   - ID Proof
   - Property ownership proof
   - Bank details
2. Verify phone and email
3. Check property authenticity
4. Mark as verified
5. Owner gets verified badge

### Manage Tenants

**View All Tenants:**
1. Go to **"Users"** → **"Tenants"**
2. See list with:
   - Name
   - Current PG
   - Payment status
   - Account status
   - Join date

**Tenant Actions:**
- View profile details
- Check payment history
- View booking history
- Handle complaints
- Suspend/Delete account
- Send notifications

---

## 🏢 Property Management

### View All Properties

1. Go to **"Properties"**
2. See all listed PGs:
   - Property name
   - Owner name
   - Location
   - Total rooms/beds
   - Occupancy rate
   - Status (Active/Inactive)
   - Verification status

### Property Verification

**Review Process:**
1. Click on property
2. Check:
   - ✅ Photos quality
   - ✅ Address accuracy
   - ✅ Amenities claimed
   - ✅ Pricing reasonable
   - ✅ House rules appropriate
   - ✅ Legal compliance
3. Actions:
   - **Approve** - Goes live
   - **Reject** - With reason
   - **Request Changes** - Ask owner to edit

### Property Moderation

**Flag Issues:**
- Misleading information
- Inappropriate photos
- Fake listing
- Overpricing
- Safety concerns

**Actions:**
- Contact owner for clarification
- Request corrections
- Suspend listing if serious
- Remove if fraudulent

### Featured Properties

**Promote Properties:**
1. Select high-quality properties
2. Mark as **"Featured"**
3. Appears in top search results
4. Can be paid feature (premium listing)

---

## 💰 Financial Management

### Payment Overview

**Dashboard:**
- Total transactions today
- Total revenue this month
- Pending settlements
- Failed payments
- Refunds processed

### Transaction Management

**View All Transactions:**
1. Go to **"Payments"** → **"Transactions"**
2. Filter by:
   - Date range
   - Transaction type
   - Status
   - Amount range
   - User

**Transaction Details:**
- Transaction ID
- Date & time
- From (Tenant)
- To (Owner)
- Amount
- Payment method
- Status
- Commission (if applicable)

### Settlements

**Owner Payouts:**
If platform handles payments:
1. Go to **"Settlements"**
2. See pending payouts
3. Review and approve
4. Process bank transfers
5. Mark as settled

### Commission Management

**Set Commission Rates:**
1. Settings → **"Commission"**
2. Set percentage per transaction
3. Can vary by:
   - Owner tier
   - Property type
   - Location
4. Save configuration

### Reports

**Generate Financial Reports:**
- Daily revenue report
- Monthly summary
- Owner-wise breakdown
- Transaction analysis
- Commission earned
- Pending settlements
- Refund report

**Export Options:**
- Excel/CSV
- PDF
- Email scheduled reports

---

## 📊 Analytics & Reports

### Platform Analytics

**User Analytics:**
- New registrations (daily/monthly)
- Active users
- User retention rate
- Churn rate
- User demographics

**Booking Analytics:**
- Total bookings
- Conversion rate
- Booking sources
- Popular locations
- Peak booking times
- Average booking value

**Property Analytics:**
- Total listings
- Active vs inactive
- Occupancy rates
- Most viewed properties
- Best performing owners
- Location-wise distribution

**Revenue Analytics:**
- Daily/Monthly revenue
- Revenue by location
- Revenue by property type
- Average transaction value
- Commission earned
- Growth trends

### Custom Reports

**Create Reports:**
1. Go to **"Reports"** → **"Custom"**
2. Select:
   - Report type
   - Date range
   - Filters
   - Metrics
3. Generate
4. Schedule (daily/weekly/monthly)
5. Email recipients

---

## 🎫 Support Ticket Management

### View Tickets

1. Go to **"Support"**
2. See all tickets:
   - 🔴 **Critical** - Within 1 hour
   - 🟡 **High** - Within 4 hours
   - 🟢 **Medium** - Within 24 hours
   - ⚪ **Low** - Within 48 hours

### Handle Tickets

**Ticket Details:**
- Ticket ID
- User (Owner/Tenant)
- Category
- Issue description
- Attachments
- Status
- Created date
- Assigned to

**Actions:**
1. **Assign** - To team member
2. **Update** - Add notes
3. **Escalate** - To senior admin
4. **Resolve** - Close ticket
5. **Reopen** - If issue persists

### Common Issues

**Owner Issues:**
- Account verification
- Payment not received
- Property not visible
- App bugs
- Feature requests

**Tenant Issues:**
- Booking problems
- Payment failures
- Maintenance not addressed
- Owner disputes
- App issues

**Resolution:**
- Investigate issue
- Contact relevant parties
- Apply fixes if technical
- Mediate disputes
- Follow up until resolved

---

## ⚙️ System Configuration

### General Settings

1. **Platform Settings:**
   - Platform name
   - Logo
   - Primary color theme
   - Default currency
   - Date/time format
   - Language options

2. **Email Configuration:**
   - SMTP settings
   - Email templates
   - Sender details
   - Notification emails

3. **SMS Configuration:**
   - SMS gateway
   - Templates
   - Sender ID

4. **Payment Gateway:**
   - Razorpay/Stripe credentials
   - Merchant ID
   - API keys
   - Webhook URLs
   - Test/Live mode

### Feature Toggles

**Enable/Disable Features:**
- Online payments
- Booking requests
- Maintenance tracking
- Messaging system
- Reviews and ratings
- Featured listings
- Commission system

### API Configuration

**View/Update:**
- API endpoint: `http://34.227.111.143:8080`
- API keys
- Rate limits
- Allowed origins (CORS)
- Webhook URLs

### Database Management

**Database Info:**
- Host: `database-pgni.cezawkgguojl.us-east-1.rds.amazonaws.com`
- Database: `pgworld`
- Status: Connected

**Actions:**
- View tables
- Run queries (carefully!)
- Backup database
- Restore from backup
- View logs

### Storage Management

**S3 Bucket:**
- Bucket: `pgni-preprod-698302425856-uploads`
- Usage: XX GB
- Files count: XXX

**Manage:**
- View uploaded files
- Delete unused files
- Set retention policies
- Monitor usage

---

## 🔔 Notifications & Alerts

### System Alerts

**Monitor:**
- Server down alerts
- High CPU usage
- Database errors
- Payment gateway issues
- Storage full warnings
- Security threats

**Alert Channels:**
- Email
- SMS
- Push notification
- Slack/Teams integration

### User Notifications

**Send Platform-wide:**
1. Go to **"Notifications"** → **"Broadcast"**
2. Select audience:
   - All users
   - Only owners
   - Only tenants
   - Verified users
   - By location
3. Compose message
4. Schedule or send now
5. Track delivery

**Use Cases:**
- System maintenance notice
- New feature announcement
- Festival wishes
- Policy updates
- Important alerts

---

## 📋 Content Moderation

### Review Content

**Photos:**
- Review uploaded property photos
- Flag inappropriate images
- Reject poor quality
- Request replacements

**Descriptions:**
- Check property descriptions
- Remove offensive content
- Verify claims
- Ensure accuracy

**Reviews:**
- Monitor user reviews
- Remove fake reviews
- Handle disputes
- Maintain authenticity

### Reported Content

**Handle Reports:**
1. User reports inappropriate content
2. Review reported item
3. Investigate
4. Take action:
   - Remove content
   - Warn user
   - Suspend account
   - Ban user (if serious)
5. Notify reporter

---

## 🛡️ Security & Compliance

### Security Monitoring

**Check Logs:**
- Login attempts
- Failed authentications
- API access logs
- Suspicious activities
- IP blacklist

**Actions:**
- Block suspicious IPs
- Reset compromised accounts
- Enable 2FA for users
- Review permissions

### Data Privacy

**GDPR/Data Protection:**
- User data export
- Right to be forgotten
- Data retention policies
- Privacy policy updates
- Consent management

### Backup & Recovery

**Regular Backups:**
- Daily automated backups
- Manual backup option
- Backup retention: 30 days
- Test recovery quarterly

**Disaster Recovery:**
- Have recovery plan
- Document procedures
- Test regularly
- Keep contacts updated

---

## 👨‍👩‍👧‍👦 Admin Team Management

### Multiple Admins

**Roles:**
- **Super Admin** - Full access
- **Admin** - Most features
- **Support** - Tickets only
- **Finance** - Payments only
- **Content Moderator** - Content only

### Add Admin

1. Go to **"Team"** → **"Add Member"**
2. Enter:
   - Name
   - Email
   - Role
   - Permissions
3. Send invitation
4. They set password

### Manage Permissions

**Fine-tune Access:**
- User management
- Property approval
- Financial access
- Settings modification
- Report generation
- System configuration

---

## 📱 Mobile App Management

### App Configuration

**Update App Settings:**
1. Go to **"App Config"**
2. Set:
   - API base URL
   - Minimum app version
   - Force update flag
   - Maintenance mode
   - Feature flags

### Push Notifications

**Send Push:**
1. **"Notifications"** → **"Push"**
2. Select users
3. Title and message
4. Action (open screen)
5. Schedule or send now

### App Versions

**Manage Versions:**
- Current version
- Minimum supported
- Force update trigger
- Update message
- Download links

---

## 🔍 Monitoring & Logs

### System Health

**Monitor:**
- API response time
- Database queries
- Error rates
- Server resources
- Active connections

### Application Logs

**View Logs:**
1. Go to **"Logs"**
2. Filter by:
   - Log level (Error/Warning/Info)
   - Date range
   - Module
   - User
3. Search and analyze

### Error Tracking

**Track Errors:**
- Application errors
- API failures
- Database errors
- Payment failures
- User reported bugs

**Debugging:**
- View stack trace
- Reproduce issue
- Fix and deploy
- Verify resolution

---

## 📞 Communication

### Email Management

**Templates:**
- Welcome email
- Verification email
- Password reset
- Booking confirmation
- Payment receipt
- Support response

**Email Logs:**
- View sent emails
- Delivery status
- Open rates
- Click rates

### SMS Management

**Templates:**
- OTP messages
- Booking alerts
- Payment reminders
- Support updates

**SMS Logs:**
- Delivery reports
- Failed messages
- Cost tracking

---

## 💡 Pro Tips for Admins

### Daily Tasks

✅ Check dashboard health
✅ Review new registrations
✅ Verify properties waiting approval
✅ Handle support tickets
✅ Monitor payment issues
✅ Review user reports

### Weekly Tasks

✅ Generate weekly report
✅ Review analytics
✅ Check for fraudulent activity
✅ Update featured properties
✅ Team sync meeting
✅ System backup verification

### Monthly Tasks

✅ Financial reconciliation
✅ Platform performance review
✅ User growth analysis
✅ Feature prioritization
✅ Security audit
✅ Database optimization

---

## 🆘 Emergency Procedures

### System Down

1. Check server status
2. Check database connection
3. Check API health
4. Review error logs
5. Restart services if needed
6. Notify users if extended
7. Document incident

### Data Breach

1. Isolate affected systems
2. Assess breach scope
3. Notify security team
4. Inform affected users
5. Investigate cause
6. Apply fixes
7. Document and report

### Payment Issues

1. Check payment gateway status
2. Review failed transactions
3. Contact gateway support if needed
4. Retry failed payments
5. Notify affected users
6. Offer alternative payment

---

## 📊 Success Metrics

### KPIs to Track

**User Metrics:**
- Daily/Monthly active users
- User retention rate
- Churn rate
- User satisfaction score

**Business Metrics:**
- Total bookings
- Booking conversion rate
- Average booking value
- Revenue growth
- Commission earned

**Platform Metrics:**
- App crash rate
- API response time
- Payment success rate
- Support ticket resolution time
- Property approval time

---

## ✅ Admin Checklist

**Daily:**
- [ ] Check system health
- [ ] Review new users
- [ ] Approve properties
- [ ] Handle urgent tickets
- [ ] Monitor payments

**Weekly:**
- [ ] Generate reports
- [ ] Review analytics
- [ ] Check for issues
- [ ] Update featured listings
- [ ] Team meeting

**Monthly:**
- [ ] Financial review
- [ ] Performance analysis
- [ ] Security audit
- [ ] Feature planning
- [ ] Database maintenance

---

## 📞 Admin Support

**Technical Issues:**
- Email: admin@pgni.com
- Phone: +91-XXXX-XXXXXX
- Slack: #admin-support

**System Access:**
- API: http://34.227.111.143:8080
- Admin Portal: http://34.227.111.143:8080/admin
- Database: (Access via SSH)

**Documentation:**
- API Docs: `/docs/api`
- System Architecture: `/docs/architecture`
- Deployment Guide: `/docs/deployment`

---

**You're the backbone of PGNi!** 💪

**Keep the platform running smoothly!** 🚀

For technical deployment and maintenance, see: `TECHNICAL_GUIDE.md`

