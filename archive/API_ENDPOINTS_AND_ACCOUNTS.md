# 🌐 API ENDPOINTS & TEST ACCOUNTS

**Base URL:** http://34.227.111.143:8080

---

## 🔗 **COMPLETE API ENDPOINTS**

### **Health Check:**
```
GET http://34.227.111.143:8080/
Response: "ok" ✅ (Confirmed Working)

GET http://34.227.111.143:8080/health
Response: {"status":"healthy","timestamp":"..."}
```

---

### **Authentication Endpoints:**

#### **Register New User**
```
POST http://34.227.111.143:8080/api/auth/register

Body (JSON):
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "Test@123",
  "role": "tenant"  // or "admin", "pg_owner"
}

Response:
{
  "message": "User created successfully",
  "user_id": 1
}
```

#### **Login**
```
POST http://34.227.111.143:8080/api/auth/login

Body (JSON):
{
  "email": "admin@pgni.com",
  "password": "password123"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "admin",
    "email": "admin@pgni.com",
    "role": "admin"
  }
}
```

---

### **Property Management Endpoints:**

#### **Get All Properties**
```
GET http://34.227.111.143:8080/api/properties

Headers:
Authorization: Bearer {token}

Response:
{
  "properties": [
    {
      "id": 1,
      "owner_id": 2,
      "name": "Sunshine PG",
      "address": "123 Main Street",
      "city": "New York",
      "total_rooms": 20
    }
  ]
}
```

#### **Get Property Details**
```
GET http://34.227.111.143:8080/api/properties/{id}

Headers:
Authorization: Bearer {token}

Response:
{
  "id": 1,
  "owner_id": 2,
  "name": "Sunshine PG",
  "address": "123 Main Street, Near Metro Station",
  "city": "New York",
  "total_rooms": 20,
  "rooms": [...],
  "tenants": [...]
}
```

#### **Create Property**
```
POST http://34.227.111.143:8080/api/properties

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "name": "New PG Hostel",
  "address": "456 Oak Avenue",
  "city": "Boston",
  "total_rooms": 15
}
```

#### **Update Property**
```
PUT http://34.227.111.143:8080/api/properties/{id}

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "name": "Updated PG Name",
  "address": "Updated Address",
  "city": "Boston",
  "total_rooms": 20
}
```

#### **Delete Property**
```
DELETE http://34.227.111.143:8080/api/properties/{id}

Headers:
Authorization: Bearer {token}
```

---

### **Room Management Endpoints:**

#### **Get All Rooms**
```
GET http://34.227.111.143:8080/api/rooms

Headers:
Authorization: Bearer {token}

Response:
{
  "rooms": [
    {
      "id": 1,
      "property_id": 1,
      "room_number": "101",
      "rent_amount": 8000.00,
      "is_occupied": false
    }
  ]
}
```

#### **Get Rooms by Property**
```
GET http://34.227.111.143:8080/api/properties/{property_id}/rooms

Headers:
Authorization: Bearer {token}
```

#### **Get Room Details**
```
GET http://34.227.111.143:8080/api/rooms/{id}

Headers:
Authorization: Bearer {token}
```

#### **Create Room**
```
POST http://34.227.111.143:8080/api/rooms

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "property_id": 1,
  "room_number": "205",
  "rent_amount": 6000.00,
  "is_occupied": false
}
```

#### **Update Room**
```
PUT http://34.227.111.143:8080/api/rooms/{id}

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "room_number": "205A",
  "rent_amount": 6500.00,
  "is_occupied": true
}
```

#### **Delete Room**
```
DELETE http://34.227.111.143:8080/api/rooms/{id}

Headers:
Authorization: Bearer {token}
```

---

### **Tenant Management Endpoints:**

#### **Get All Tenants**
```
GET http://34.227.111.143:8080/api/tenants

Headers:
Authorization: Bearer {token}

Response:
{
  "tenants": [
    {
      "id": 1,
      "user_id": 5,
      "room_id": 2,
      "name": "Alice Johnson",
      "phone": "+1-555-0102",
      "move_in_date": "2024-02-01",
      "is_active": true
    }
  ]
}
```

#### **Get Tenant Details**
```
GET http://34.227.111.143:8080/api/tenants/{id}

Headers:
Authorization: Bearer {token}
```

#### **Create Tenant**
```
POST http://34.227.111.143:8080/api/tenants

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "user_id": 5,
  "room_id": 2,
  "name": "Alice Johnson",
  "phone": "+1-555-0102",
  "move_in_date": "2024-02-01"
}
```

#### **Update Tenant**
```
PUT http://34.227.111.143:8080/api/tenants/{id}

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "room_id": 3,
  "phone": "+1-555-9999",
  "is_active": true
}
```

---

### **Payment Management Endpoints:**

#### **Get All Payments**
```
GET http://34.227.111.143:8080/api/payments

Headers:
Authorization: Bearer {token}

Response:
{
  "payments": [
    {
      "id": 1,
      "tenant_id": 1,
      "amount": 8000.00,
      "payment_date": "2024-08-05",
      "status": "completed"
    }
  ]
}
```

#### **Get Tenant Payments**
```
GET http://34.227.111.143:8080/api/tenants/{tenant_id}/payments

Headers:
Authorization: Bearer {token}
```

#### **Create Payment**
```
POST http://34.227.111.143:8080/api/payments

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "tenant_id": 1,
  "amount": 8000.00,
  "payment_date": "2024-10-05",
  "status": "completed"
}
```

#### **Update Payment Status**
```
PUT http://34.227.111.143:8080/api/payments/{id}

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "status": "completed"  // or "pending", "failed"
}
```

---

### **User Management Endpoints:**

#### **Get All Users**
```
GET http://34.227.111.143:8080/api/users

Headers:
Authorization: Bearer {token}
```

#### **Get User Profile**
```
GET http://34.227.111.143:8080/api/users/{id}

Headers:
Authorization: Bearer {token}
```

#### **Update User Profile**
```
PUT http://34.227.111.143:8080/api/users/{id}

Headers:
Authorization: Bearer {token}

Body (JSON):
{
  "username": "newusername",
  "email": "newemail@example.com"
}
```

---

## 🔐 **COMPLETE TEST ACCOUNTS**

### **Admin Account:**
```
Email:    admin@pgni.com
Password: password123
Role:     admin
Access:   Full system access (all 37 Admin App pages)

API Login:
POST http://34.227.111.143:8080/api/auth/login
{
  "email": "admin@pgni.com",
  "password": "password123"
}
```

### **PG Owner Accounts:**
```
Account 1:
  Email:    owner@pgni.com
  Password: password123
  Role:     pg_owner
  Access:   Manage properties and tenants (37 Admin App pages)

Account 2:
  Email:    john.owner@example.com
  Password: password123
  Role:     pg_owner

Account 3:
  Email:    mary.owner@example.com
  Password: password123
  Role:     pg_owner
```

### **Tenant Accounts:**
```
Account 1:
  Email:    tenant@pgni.com
  Password: password123
  Role:     tenant
  Access:   Resident features (28 Tenant App pages)

Account 2:
  Email:    alice.tenant@example.com
  Password: password123
  Role:     tenant

Account 3:
  Email:    bob.tenant@example.com
  Password: password123
  Role:     tenant

Account 4:
  Email:    charlie.tenant@example.com
  Password: password123
  Role:     tenant

Account 5:
  Email:    diana.tenant@example.com
  Password: password123
  Role:     tenant
```

---

## 🧪 **HOW TO TEST API ENDPOINTS**

### **Using cURL (Command Line):**

```bash
# 1. Login to get token
curl -X POST http://34.227.111.143:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@pgni.com",
    "password": "password123"
  }'

# 2. Use the token from response
export TOKEN="your_token_here"

# 3. Get all properties
curl -X GET http://34.227.111.143:8080/api/properties \
  -H "Authorization: Bearer $TOKEN"

# 4. Get all rooms
curl -X GET http://34.227.111.143:8080/api/rooms \
  -H "Authorization: Bearer $TOKEN"

# 5. Get all tenants
curl -X GET http://34.227.111.143:8080/api/tenants \
  -H "Authorization: Bearer $TOKEN"
```

### **Using Postman:**

1. **Import Collection:**
   - Create new collection "PGNi API"
   - Add base URL: `http://34.227.111.143:8080`

2. **Set up Authentication:**
   - Create login request
   - Save token to environment variable
   - Use token in subsequent requests

3. **Test All Endpoints:**
   - Authentication (Login, Register)
   - Properties (CRUD)
   - Rooms (CRUD)
   - Tenants (CRUD)
   - Payments (CRUD)

### **Using Browser (Simple Test):**

```
Visit: http://34.227.111.143:8080/
Expected: "ok"

Visit: http://34.227.111.143:8080/health
Expected: {"status":"healthy",...}
```

---

## 🎯 **WHERE TO ACCESS UI PAGES**

### **❌ NOT at http://34.227.111.143:8080/**

The API endpoint only returns JSON data, not HTML pages.

### **✅ ACCESS UI PAGES LOCALLY:**

#### **Admin App (37 pages):**
```batch
1. Run: RUN_ADMIN_APP.bat
2. Choose: 1 (Chrome)
3. URL: http://localhost:50000 (or similar)
4. Login: admin@pgni.com / password123
```

#### **Tenant App (28 pages):**
```batch
1. Run: RUN_TENANT_APP.bat
2. Choose: 1 (Chrome)
3. URL: http://localhost:50001 (or similar)
4. Login: tenant@pgni.com / password123
```

---

## 📊 **COMPLETE SYSTEM ACCESS MAP**

| Component | URL | Access Method | Status |
|-----------|-----|---------------|--------|
| **Backend API** | http://34.227.111.143:8080 | cURL, Postman, Apps | ✅ Live |
| **Admin App (37 pages)** | Local: http://localhost | RUN_ADMIN_APP.bat | ✅ Ready |
| **Tenant App (28 pages)** | Local: http://localhost | RUN_TENANT_APP.bat | ✅ Ready |
| **Database** | RDS MySQL | Via API | ✅ Connected |

---

## 🔄 **OPTIONAL: DEPLOY UI TO SERVER**

If you want UI pages accessible at http://34.227.111.143:8080, you need to:

1. **Build Flutter Web Apps:**
   ```bash
   cd pgworld-master
   flutter build web
   
   cd ../pgworldtenant-master
   flutter build web
   ```

2. **Deploy to EC2:**
   - Copy `build/web` folder to EC2
   - Configure nginx or serve via Go API
   - Access at: http://34.227.111.143/admin and http://34.227.111.143/tenant

3. **Or Use Existing Script:**
   ```batch
   REM Already created for you
   BUILD_AND_DEPLOY_WEB.bat
   ```

See `DEPLOY_FLUTTER_WEB.md` for complete instructions.

---

## 📝 **SUMMARY**

### **Current Status:**
- ✅ **API**: http://34.227.111.143:8080 (JSON endpoints working)
- ✅ **UI Apps**: Run locally (65 pages ready)
- ✅ **Test Accounts**: 9 users with credentials
- ✅ **Endpoints**: All REST APIs documented

### **To Test:**
```bash
# Test API
curl http://34.227.111.143:8080/

# Test UI
Double-click: RUN_ADMIN_APP.bat
Login: admin@pgni.com / password123
```

### **All 65 Pages Location:**
- **NOT** at http://34.227.111.143:8080 (API only)
- **YES** via RUN_ADMIN_APP.bat (local browser)
- **YES** via RUN_TENANT_APP.bat (local browser)

---

## 🚀 **QUICK START**

```batch
REM Step 1: Load test data (one-time)
REM In CloudShell:
curl -O https://raw.githubusercontent.com/siddam01/pgni/main/LOAD_TEST_DATA.sh
chmod +x LOAD_TEST_DATA.sh
./LOAD_TEST_DATA.sh

REM Step 2: Test API
curl http://34.227.111.143:8080/health

REM Step 3: See UI pages
REM On Windows:
RUN_ADMIN_APP.bat
REM Login: admin@pgni.com / password123
```

---

**All 65 UI pages work perfectly - they just run locally, not on the server URL!**

**The server URL (http://34.227.111.143:8080) is for the backend API (JSON), not the UI (HTML).**

