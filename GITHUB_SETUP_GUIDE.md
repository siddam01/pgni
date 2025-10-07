# 🔒 GitHub Setup Guide - Private Repository

**Your GitHub Username:** siddam01  
**Project:** PGNi (PG World)  
**Repository Type:** Private (Secure)

---

## ✅ SETUP COMPLETE!

GitHub Actions CI/CD pipeline has been configured!

**Files Created:**
- `.github/workflows/deploy.yml` ✅

---

## 🚀 STEP-BY-STEP SETUP

### Step 1: Create Private GitHub Repository (5 minutes)

1. **Go to GitHub:** https://github.com/siddam01
2. **Click:** "New repository" (green button)
3. **Fill in:**
   - Repository name: `pgni` (or `pgworld`)
   - Description: `PGNi - Paying Guest Management System`
   - **Visibility:** ✅ **Private** (Important!)
   - Initialize: ❌ Don't check any boxes

4. **Click:** "Create repository"

---

### Step 2: Push Your Code to GitHub (5 minutes)

Open PowerShell in your project directory and run:

```powershell
cd C:\MyFolder\Mytest\pgworld-master

# Initialize git (if not already done)
git init

# Add your files
git add .

# Commit
git commit -m "Initial commit - PGNi application"

# Add remote (replace 'pgni' with your repo name if different)
git remote add origin https://github.com/siddam01/pgni.git

# Set main branch
git branch -M main

# Push to GitHub
git push -u origin main
```

**Note:** GitHub will ask for your credentials:
- Username: `siddam01`
- Password: Use a **Personal Access Token** (not your password)

---

### Step 3: Create Personal Access Token (If Needed)

If GitHub asks for password:

1. Go to: https://github.com/settings/tokens
2. Click: "Generate new token" → "Generate new token (classic)"
3. Name: `PGNi Development`
4. Expiration: `90 days` (or No expiration)
5. Select scopes:
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
6. Click: "Generate token"
7. **Copy the token** (you won't see it again!)
8. Use this token as your password when pushing

---

### Step 4: Configure GitHub Secrets (10 minutes)

Go to your repository → Settings → Secrets and variables → Actions

**Click "New repository secret" and add:**

#### AWS Credentials:
```
Name: AWS_ACCESS_KEY_ID
Value: [Your AWS Access Key ID]
```

```
Name: AWS_SECRET_ACCESS_KEY
Value: [Your AWS Secret Access Key]
```

#### Pre-Production Server:
```
Name: PREPROD_SSH_KEY
Value: [Content of your preprod .pem key file]
```

```
Name: PREPROD_HOST
Value: [EC2 IP address, e.g., 54.123.45.67]
```

#### Production Server:
```
Name: PRODUCTION_SSH_KEY
Value: [Content of your production .pem key file]
```

```
Name: PRODUCTION_HOST
Value: [EC2 IP address, e.g., 54.234.56.78]
```

**How to get SSH key content:**
```powershell
Get-Content C:\path\to\your-key.pem | Out-String
```
Copy the entire output (including BEGIN and END lines)

---

### Step 5: Configure GitHub Environments (5 minutes)

Go to: Settings → Environments

#### Create "pre-production" environment:
1. Click "New environment"
2. Name: `pre-production`
3. Protection rules: None (auto-deploy)
4. Environment URL: `https://api-preprod.pgni.com`
5. Click "Configure environment"

#### Create "production" environment:
1. Click "New environment"
2. Name: `production`
3. Protection rules:
   - ✅ Required reviewers
   - Add yourself: `siddam01`
4. Environment URL: `https://api.pgni.com`
5. Click "Configure environment"

**This ensures production requires your approval!**

---

### Step 6: Set Up Branch Protection (5 minutes)

Go to: Settings → Branches → Add rule

#### Protect 'main' branch:
- Branch name pattern: `main`
- Protection settings:
  - ✅ Require pull request before merging
  - ✅ Require approvals (1)
  - ✅ Require status checks to pass before merging
    - Add: `build`
- Click "Create"

#### Protect 'develop' branch:
- Branch name pattern: `develop`
- Protection settings:
  - ✅ Require status checks to pass before merging
    - Add: `build`
- Click "Create"

---

### Step 7: Create 'develop' Branch (2 minutes)

```powershell
# Create develop branch
git checkout -b develop

# Push to GitHub
git push -u origin develop
```

---

## 🔒 PRIVACY & SECURITY

### Your Repository is PRIVATE ✅

**What this means:**
- ✅ Only you can see the code
- ✅ You control who has access
- ✅ Code is not public
- ✅ GitHub Actions minutes: 2000/month free for private repos

### Who Can Access:
- ✅ You (siddam01) - Owner
- ✅ Anyone you explicitly invite
- ❌ No one else can see it

### To Add Collaborators:
1. Go to: Settings → Collaborators
2. Click "Add people"
3. Enter their GitHub username
4. Choose permission level

---

## 🔄 WORKFLOW

### Deploy to Pre-Production (Automatic):

```powershell
# Make changes
git add .
git commit -m "Add new feature"

# Push to develop branch
git push origin develop
```

**GitHub Actions will automatically:**
1. Build the API
2. Run tests
3. Deploy to pre-production
4. Run health check

---

### Deploy to Production (Manual Approval):

```powershell
# 1. Create Pull Request: develop → main
# Go to GitHub and create PR

# 2. After PR is approved and merged:
# GitHub Actions will:
#   - Build the API
#   - Run tests
#   - WAIT for your approval

# 3. Go to GitHub Actions tab
# Click on the workflow run
# Click "Review deployments"
# Select "production"
# Click "Approve and deploy"

# 4. Deployment proceeds automatically!
```

---

## 📊 MONITORING YOUR DEPLOYMENTS

### View Pipeline Status:

Go to: Your repository → Actions tab

You'll see:
- ✅ Build status
- ✅ Test results
- ✅ Deployment history
- ✅ Logs for each step

### View Specific Deployment:

1. Click on a workflow run
2. See all jobs (build, deploy-preprod, deploy-production)
3. Click any job to see logs
4. Green ✅ = Success
5. Red ❌ = Failed

---

## 💰 COST

### GitHub Actions Pricing (Private Repo):

**Free tier includes:**
- 2,000 minutes/month
- Your typical deployment: ~5 minutes
- **You can run ~400 deployments/month for FREE!**

**After free tier:**
- $0.008 per minute
- 10 deployments/month = $0.40
- Very affordable!

---

## ✅ SETUP CHECKLIST

- [ ] Created private GitHub repository
- [ ] Pushed code to GitHub
- [ ] Added AWS secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- [ ] Added Pre-prod secrets (PREPROD_SSH_KEY, PREPROD_HOST)
- [ ] Added Production secrets (PRODUCTION_SSH_KEY, PRODUCTION_HOST)
- [ ] Created 'pre-production' environment
- [ ] Created 'production' environment (with approval)
- [ ] Set up branch protection for 'main'
- [ ] Set up branch protection for 'develop'
- [ ] Created 'develop' branch
- [ ] Tested first deployment

---

## 🎯 QUICK COMMANDS

### Check Git Status:
```powershell
git status
```

### See Current Branch:
```powershell
git branch
```

### Switch to develop:
```powershell
git checkout develop
```

### Switch to main:
```powershell
git checkout main
```

### View Remotes:
```powershell
git remote -v
```

### Pull Latest Changes:
```powershell
git pull origin develop
```

---

## 🆘 TROUBLESHOOTING

### Problem: Git push fails with authentication error

**Solution:**
1. Create Personal Access Token (see Step 3)
2. Use token as password
3. Or configure credential helper:
```powershell
git config --global credential.helper manager
```

---

### Problem: GitHub Actions workflow not running

**Solutions:**
- Check `.github/workflows/deploy.yml` exists
- Verify you pushed to `develop` or `main` branch
- Check Actions tab for errors
- Ensure repository has Actions enabled (Settings → Actions)

---

### Problem: Deployment fails

**Solutions:**
- Check GitHub Actions logs
- Verify AWS credentials are correct
- Verify SSH keys are correct
- Verify EC2 instances are running
- Check EC2 security groups allow SSH (port 22)

---

## 📞 NEXT STEPS

### Today:
1. ✅ Create GitHub repository
2. ✅ Push code
3. ✅ Add secrets
4. ✅ Configure environments

### Tomorrow:
1. Test deployment to pre-prod
2. Verify API works
3. Test production approval flow

### This Week:
1. Set up AWS infrastructure
2. Deploy to pre-production
3. Deploy to production
4. Start development!

---

## 🎉 YOU'RE READY!

Your PGNi application now has:
- ✅ Private GitHub repository (secure!)
- ✅ Automated CI/CD pipeline
- ✅ Pre-production and production environments
- ✅ Manual approval for production
- ✅ Automatic rollback on failure

**Repository URL:** https://github.com/siddam01/pgni (private)

**Start by pushing your code to GitHub!**

```powershell
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/siddam01/pgni.git
git branch -M main
git push -u origin main
```

Good luck! 🚀

