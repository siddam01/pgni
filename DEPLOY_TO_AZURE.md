# 🚀 Deploy to Azure - Step by Step Guide

**Platform:** Microsoft Azure  
**Estimated Cost:** $49/month  
**Setup Time:** 2 hours  
**Difficulty:** Medium

---

## 📊 AZURE ARCHITECTURE

```
Internet → Azure DNS
         ↓
    Azure Front Door (CDN) [Optional]
         ↓
    Application Gateway / App Service
         ↓
    ┌────────────────────────┐
    │   App Service          │ ← Your Go API
    │   (Auto-scaling)       │
    └────────────────────────┘
         ↓
    Azure Database for MySQL
         ↓
    Blob Storage (File Storage)
```

---

## 💰 COST BREAKDOWN

| Service | Configuration | Monthly Cost |
|---------|--------------|--------------|
| **App Service** | B1 Basic (1 core, 1.75GB RAM) | $13 |
| **Azure MySQL** | B1ms (1 vCPU, 2GB RAM, 32GB) | $30 |
| **Blob Storage** | 200GB + transactions | $4 |
| **App Gateway** | Basic tier (optional) | $125 |
| **DNS Zone** | Azure DNS + queries | $1 |
| **Data Transfer** | First 5GB free, then $0.087/GB | $2 |
| **SSL Certificate** | App Service Certificate | $75/year |
| **Total (Basic)** | | **$49** |
| **Total (with Gateway)** | | **$174** |

**Note:** Azure is more expensive than AWS but easier to manage

---

## 🎯 DEPLOYMENT GUIDE

### Step 1: Create Azure MySQL Database (15 minutes)

1. **Go to Azure Portal → Create a resource**
2. **Search "Azure Database for MySQL flexible server"**
3. **Click "Create"**

4. **Configuration:**
   ```
   Basics:
   - Subscription: Your subscription
   - Resource group: Create new → "pgworld-rg"
   - Server name: pgworld-mysql-server
   - Region: East US (or nearest)
   - MySQL version: 8.0
   - Compute + storage: Burstable, B1ms (1 vCore, 2GB RAM)
   - Storage: 32 GB
   - Backup retention: 7 days
   
   Authentication:
   - Admin username: pgworldadmin
   - Password: [STRONG PASSWORD - Save this!]
   
   Networking:
   - Connectivity: Public access
   - Add current client IP: Yes
   - Allow Azure services: Yes
   ```

5. **Click "Review + create"** (takes 10-15 minutes)

6. **Configure Firewall:**
   - Go to the created server
   - Settings → Networking
   - Add your IP address
   - Add rule: Allow all Azure services (0.0.0.0-0.0.0.0)

7. **Enable SSL (Required by Azure):**
   - Already enabled by default
   - Download SSL certificate from portal

8. **Save Connection String:**
   ```
   Server: pgworld-mysql-server.mysql.database.azure.com
   Username: pgworldadmin@pgworld-mysql-server
   Database: pgworld_db
   Port: 3306
   SSL: Required
   ```

---

### Step 2: Import Database Schema (10 minutes)

1. **Create database:**
   ```bash
   # Install MySQL client if needed
   mysql --host=pgworld-mysql-server.mysql.database.azure.com \
         --user=pgworldadmin@pgworld-mysql-server \
         --password=[YOUR_PASSWORD] \
         --ssl-mode=REQUIRED \
         -e "CREATE DATABASE pgworld_db;"
   ```

2. **Import schema:**
   ```bash
   mysql --host=pgworld-mysql-server.mysql.database.azure.com \
         --user=pgworldadmin@pgworld-mysql-server \
         --password=[YOUR_PASSWORD] \
         --ssl-mode=REQUIRED \
         pgworld_db < pgworld-api-master/setup-database.sql
   ```

3. **Run migrations:**
   ```bash
   mysql --host=pgworld-mysql-server.mysql.database.azure.com \
         --user=pgworldadmin@pgworld-mysql-server \
         --password=[YOUR_PASSWORD] \
         --ssl-mode=REQUIRED \
         pgworld_db < pgworld-api-master/migrations/001_owner_onboarding.sql
   ```

---

### Step 3: Create Blob Storage (5 minutes)

1. **Go to Azure Portal → Create a resource**
2. **Search "Storage account"**
3. **Configuration:**
   ```
   Basics:
   - Resource group: pgworld-rg
   - Storage account name: pgworldstorage
   - Region: East US (same as database)
   - Performance: Standard
   - Redundancy: LRS (Locally-redundant)
   
   Advanced:
   - Secure transfer: Enabled
   - Blob public access: Disabled
   ```

4. **Click "Review + create"**

5. **Create container:**
   - Go to Storage account → Containers
   - Create new container
   - Name: `uploads`
   - Public access level: Private

6. **Get Access Keys:**
   - Go to Storage account → Access keys
   - Show keys
   - **Save:** Storage account name and Key1

---

### Step 4: Create App Service (20 minutes)

1. **Go to Azure Portal → Create a resource**
2. **Search "App Service" → Web App**
3. **Configuration:**
   ```
   Basics:
   - Resource group: pgworld-rg
   - Name: pgworld-api
   - Publish: Code
   - Runtime stack: Go 1.21 (or latest)
   - Operating System: Linux
   - Region: East US
   
   App Service Plan:
   - Create new: pgworld-plan
   - Sku: B1 Basic (1 core, 1.75GB)
   ```

4. **Click "Review + create"**

---

### Step 5: Configure App Service (30 minutes)

1. **Go to App Service → Configuration → Application settings**

2. **Add environment variables:**
   ```
   dbConfig = pgworldadmin@pgworld-mysql-server:PASSWORD@tcp(pgworld-mysql-server.mysql.database.azure.com:3306)/pgworld_db?tls=true
   connectionPool = 20
   baseURL = https://pgworld-api.azurewebsites.net
   test = false
   migrate = false
   
   supportEmailID = support@pgworld.com
   supportEmailPassword = YOUR_APP_PASSWORD
   supportEmailHost = smtp.gmail.com
   supportEmailPort = 587
   
   ANDROID_LIVE_KEY = [FROM PRODUCTION_API_KEYS.txt]
   ANDROID_TEST_KEY = [FROM PRODUCTION_API_KEYS.txt]
   IOS_LIVE_KEY = [FROM PRODUCTION_API_KEYS.txt]
   IOS_TEST_KEY = [FROM PRODUCTION_API_KEYS.txt]
   
   RAZORPAY_KEY_ID = YOUR_RAZORPAY_KEY
   RAZORPAY_KEY_SECRET = YOUR_RAZORPAY_SECRET
   
   # For Azure Blob Storage
   AZURE_STORAGE_ACCOUNT = pgworldstorage
   AZURE_STORAGE_KEY = YOUR_STORAGE_KEY
   AZURE_STORAGE_CONTAINER = uploads
   
   # Port (Azure expects 8080 or 80)
   PORT = 8080
   ```

3. **Click "Save"**

---

### Step 6: Deploy Code (30 minutes)

#### Option A: Deploy via Azure CLI (Recommended)

1. **Install Azure CLI:**
   ```powershell
   # Windows
   winget install Microsoft.AzureCLI
   
   # Or download from: https://aka.ms/installazurecliwindows
   ```

2. **Login:**
   ```bash
   az login
   ```

3. **Navigate to API directory:**
   ```bash
   cd C:\MyFolder\Mytest\pgworld-master\pgworld-api-master
   ```

4. **Create deployment package:**
   ```bash
   # Build for Linux
   $env:GOOS="linux"
   $env:GOARCH="amd64"
   go build -o pgworld-api .
   
   # Create zip
   Compress-Archive -Path pgworld-api,.env.production -DestinationPath deploy.zip -Force
   ```

5. **Deploy:**
   ```bash
   az webapp deployment source config-zip `
     --resource-group pgworld-rg `
     --name pgworld-api `
     --src deploy.zip
   ```

#### Option B: Deploy via GitHub Actions

1. **Push code to GitHub**

2. **In Azure Portal → App Service → Deployment Center:**
   - Source: GitHub
   - Authorize GitHub
   - Select repository and branch
   - Build provider: GitHub Actions
   - Runtime: Go

3. **Azure auto-creates workflow file**

4. **Push to GitHub triggers deployment**

---

### Step 7: Configure Custom Domain and SSL (30 minutes)

1. **Add Custom Domain:**
   - Go to App Service → Custom domains
   - Click "Add custom domain"
   - Domain: `api.pgworld.com`
   - Add CNAME record in your DNS:
     ```
     CNAME: api → pgworld-api.azurewebsites.net
     ```
   - Validate and add

2. **Add SSL Certificate:**

   **Option A: Free App Service Managed Certificate**
   - Go to App Service → TLS/SSL settings
   - Private Key Certificates → Create App Service Managed Certificate
   - Select your custom domain
   - Create (free and auto-renews!)

   **Option B: Let's Encrypt (Free)**
   - Use Azure App Service extension
   - Auto-renews every 90 days

   **Option C: Buy Certificate ($75/year)**
   - App Service Certificates
   - Purchase and bind

3. **Force HTTPS:**
   - Go to App Service → TLS/SSL settings
   - HTTPS Only: On

4. **Update baseURL in environment:**
   ```
   baseURL = https://api.pgworld.com
   ```

---

### Step 8: Configure Networking Security (10 minutes)

1. **Restrict Database Access:**
   - Go to MySQL Server → Networking
   - Remove "Allow all Azure services"
   - Add only App Service outbound IPs:
     - Go to App Service → Properties
     - Copy "Outbound IP addresses"
     - Add each IP to MySQL firewall

2. **Enable App Service Authentication (Optional):**
   - Go to App Service → Authentication
   - Add identity provider if needed

---

## ✅ VERIFICATION CHECKLIST

- [ ] MySQL database created and accessible
- [ ] Database schema imported
- [ ] Blob Storage created with access keys
- [ ] App Service created
- [ ] Environment variables configured
- [ ] Code deployed successfully
- [ ] App Service running
- [ ] API accessible via Azure URL
- [ ] Custom domain configured
- [ ] SSL certificate installed
- [ ] HTTPS enforced
- [ ] Database firewall configured
- [ ] All API endpoints working
- [ ] File uploads work to Blob Storage

---

## 🔍 TESTING

```bash
# Health check
curl https://api.pgworld.com/health

# Test endpoint
curl https://api.pgworld.com/

# Check logs in Azure Portal
# App Service → Log stream
```

---

## 📊 AWS vs AZURE COMPARISON

### Cost Comparison (Monthly)

| Service | AWS | Azure | Winner |
|---------|-----|-------|--------|
| **Compute** | $8 (EC2 t3.micro) | $13 (App Service B1) | AWS |
| **Database** | $15 (RDS db.t3.micro) | $30 (MySQL B1ms) | AWS |
| **Storage** | $5 (S3) | $4 (Blob) | Azure |
| **Total** | **$30** | **$49** | **AWS** |

**Winner: AWS is 37% cheaper**

---

### Operational Efficiency

| Factor | AWS | Azure | Winner |
|--------|-----|-------|--------|
| **Setup Complexity** | High | Medium | Azure |
| **Deployment** | Manual (EC2) | One-click | Azure |
| **SSL Setup** | Free (ACM) | Free (Managed) | Tie |
| **Scaling** | Manual/Auto | Auto (built-in) | Azure |
| **Monitoring** | CloudWatch | Application Insights | Azure |
| **Documentation** | Excellent | Good | AWS |
| **Community** | Huge | Large | AWS |
| **Integration** | AWS ecosystem | Microsoft stack | Depends |

**Winner: Azure for ease of use, AWS for flexibility**

---

### Feature Comparison

| Feature | AWS | Azure |
|---------|-----|-------|
| **Go Support** | ✅ Native | ✅ Native |
| **MySQL** | ✅ RDS | ✅ Azure MySQL |
| **File Storage** | ✅ S3 | ✅ Blob Storage |
| **Auto-scaling** | ✅ Yes | ✅ Yes |
| **Load Balancer** | ✅ ALB ($16/mo) | ✅ App Gateway ($125/mo) |
| **CDN** | ✅ CloudFront | ✅ Front Door |
| **Free SSL** | ✅ ACM | ✅ Managed Cert |
| **CI/CD** | ✅ CodePipeline | ✅ GitHub Actions |
| **Monitoring** | ✅ CloudWatch | ✅ App Insights |

**Both platforms fully support your application!**

---

## 🎯 WHEN TO CHOOSE AZURE

Choose Azure if:
- ✅ You prefer easier deployment (one-click)
- ✅ You use Microsoft ecosystem (.NET, Office 365, etc.)
- ✅ You have Azure credits or enterprise agreement
- ✅ You need hybrid cloud (on-premises + cloud)
- ✅ Your customers require Microsoft compliance
- ✅ You want better Windows integration
- ✅ Setup time matters more than cost

---

## 🎯 WHEN TO CHOOSE AWS

Choose AWS if:
- ✅ Cost optimization is critical (37% cheaper)
- ✅ You expect rapid growth and need scalability
- ✅ You want largest ecosystem and community
- ✅ You need advanced features and services
- ✅ You prefer more control and flexibility
- ✅ You have AWS experience
- ✅ You want best long-term pricing

---

## 💡 RECOMMENDATION FOR PG WORLD

**For Launch:** Railway ($10/month) - Easiest and cheapest  
**For Growth:** AWS ($30/month) - Best cost/performance  
**For Enterprise:** Azure ($49/month) - If customer requires it

**Your code works on ALL platforms!** You can migrate anytime.

---

## 💰 COST OPTIMIZATION TIPS (Azure)

1. **Use Reserved Instances:** Save 30-72%
2. **Use Azure Advisor:** Get cost recommendations
3. **Enable auto-shutdown:** For dev/test environments
4. **Use Blob lifecycle management:** Auto-archive old files
5. **Monitor with Cost Management:** Set budgets and alerts
6. **Consider B-series burstable:** Better for variable workloads

---

## 🔧 TROUBLESHOOTING

### App won't start:
```bash
# Check logs
az webapp log tail --name pgworld-api --resource-group pgworld-rg

# Or in Azure Portal
# App Service → Log stream
```

### Database connection fails:
- Check firewall rules include App Service IPs
- Verify SSL is enabled in connection string (?tls=true)
- Test connection from App Service console

### File uploads fail:
- Verify storage account credentials
- Check container permissions
- Ensure CORS is configured if needed

---

## 🎉 SUCCESS!

Your PG World API is now running on Azure!

**Next Steps:**
1. Update Flutter mobile apps with `https://api.pgworld.com`
2. Set up monitoring and alerts
3. Configure automated backups
4. Test with real users
5. Scale as needed

**Azure provides excellent operational efficiency with slightly higher cost than AWS.**

