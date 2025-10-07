package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

// CORS handler
type WithCORS struct {
	r *mux.Router
}

func (s *WithCORS) ServeHTTP(res http.ResponseWriter, req *http.Request) {
	res.Header().Set("Access-Control-Allow-Origin", "*")
	res.Header().Set("Access-Control-Allow-Methods", "GET,OPTIONS,POST,PUT,DELETE")
	res.Header().Set("Access-Control-Allow-Headers", "Content-Type,apikey,appversion")

	if req.Method == "OPTIONS" {
		return
	}

	s.r.ServeHTTP(res, req)
}

// Sample response structures matching the original API
type DashboardResponse struct {
	Status string `json:"status"`
	Data   struct {
		TotalRooms      int `json:"total_rooms"`
		OccupiedRooms   int `json:"occupied_rooms"`
		TotalTenants    int `json:"total_tenants"`
		MonthlyRevenue  int `json:"monthly_revenue"`
		PendingPayments int `json:"pending_payments"`
	} `json:"data"`
}

type RoomResponse struct {
	Status string `json:"status"`
	Data   []struct {
		ID       string `json:"id"`
		RoomNo   string `json:"roomno"`
		Type     string `json:"type"`
		Capacity int    `json:"capacity"`
		Rent     int    `json:"rent"`
		Status   string `json:"room_status"`
	} `json:"data"`
}

type UserResponse struct {
	Status string `json:"status"`
	Data   []struct {
		ID      string `json:"id"`
		Name    string `json:"name"`
		Email   string `json:"email"`
		Phone   string `json:"phone"`
		RoomNo  string `json:"roomno"`
		CheckIn string `json:"checkin"`
		Status  string `json:"status"`
	} `json:"data"`
}

type BillResponse struct {
	Status string `json:"status"`
	Data   []struct {
		ID       string  `json:"id"`
		UserName string  `json:"username"`
		RoomNo   string  `json:"roomno"`
		Amount   float64 `json:"amount"`
		Type     string  `json:"type"`
		Status   string  `json:"status"`
		DueDate  string  `json:"due_date"`
	} `json:"data"`
}

// API Handlers
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"status":  "healthy",
		"service": "PG World API",
		"version": "1.0.0",
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Authentication endpoints
func AdminLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		var loginData map[string]string
		json.NewDecoder(r.Body).Decode(&loginData)
		
		username := loginData["username"]
		password := loginData["password"]
		
		// Demo authentication - accept admin/admin123 or any non-empty credentials
		if username != "" && password != "" {
			response := map[string]interface{}{
				"status": "success",
				"message": "Login successful",
				"data": map[string]interface{}{
					"id": "admin_001",
					"username": username,
					"name": "Admin User",
					"email": "admin@pgworld.com",
					"role": "admin",
					"hostel_ids": []string{"hostel_001"},
					"token": "demo_token_12345",
				},
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(response)
		} else {
			w.WriteHeader(http.StatusUnauthorized)
			response := map[string]string{
				"status": "error",
				"message": "Invalid credentials",
			}
			json.NewEncoder(w).Encode(response)
		}
	} else {
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func TenantLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		var loginData map[string]string
		json.NewDecoder(r.Body).Decode(&loginData)
		
		phone := loginData["phone"]
		otp := loginData["otp"]
		
		// Demo authentication for tenant
		if phone != "" && (otp == "" || otp == "123456") {
			response := map[string]interface{}{
				"status": "success",
				"message": "Login successful",
				"data": map[string]interface{}{
					"id": "tenant_001",
					"phone": phone,
					"name": "John Doe",
					"email": "john.doe@email.com",
					"room_no": "101",
					"hostel_id": "hostel_001",
					"token": "demo_tenant_token_12345",
				},
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(response)
		} else {
			w.WriteHeader(http.StatusUnauthorized)
			response := map[string]string{
				"status": "error",
				"message": "Invalid phone number or OTP",
			}
			json.NewEncoder(w).Encode(response)
		}
	} else {
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func SendOTP(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		var otpData map[string]string
		json.NewDecoder(r.Body).Decode(&otpData)
		
		phone := otpData["phone"]
		
		if phone != "" {
			response := map[string]interface{}{
				"status": "success",
				"message": "OTP sent successfully",
				"data": map[string]interface{}{
					"otp": "123456", // Demo OTP
					"verification_id": "demo_verification_12345",
				},
			}
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(response)
		} else {
			w.WriteHeader(http.StatusBadRequest)
			response := map[string]string{
				"status": "error",
				"message": "Phone number is required",
			}
			json.NewEncoder(w).Encode(response)
		}
	} else {
		w.WriteHeader(http.StatusMethodNotAllowed)
	}
}

func Dashboard(w http.ResponseWriter, r *http.Request) {
	response := DashboardResponse{
		Status: "success",
	}
	response.Data.TotalRooms = 50
	response.Data.OccupiedRooms = 42
	response.Data.TotalTenants = 42
	response.Data.MonthlyRevenue = 350000
	response.Data.PendingPayments = 5

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func RoomGet(w http.ResponseWriter, r *http.Request) {
	response := RoomResponse{Status: "success"}
	response.Data = []struct {
		ID       string `json:"id"`
		RoomNo   string `json:"roomno"`
		Type     string `json:"type"`
		Capacity int    `json:"capacity"`
		Rent     int    `json:"rent"`
		Status   string `json:"room_status"`
	}{
		{"1", "101", "Single", 1, 8000, "occupied"},
		{"2", "102", "Single", 1, 8000, "available"},
		{"3", "103", "Double", 2, 12000, "occupied"},
		{"4", "104", "Single", 1, 8000, "maintenance"},
		{"5", "201", "Double", 2, 12000, "occupied"},
		{"6", "202", "Single", 1, 8500, "available"},
		{"7", "203", "Triple", 3, 15000, "occupied"},
		{"8", "204", "Single", 1, 8500, "available"},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func UserGet(w http.ResponseWriter, r *http.Request) {
	response := UserResponse{Status: "success"}
	response.Data = []struct {
		ID      string `json:"id"`
		Name    string `json:"name"`
		Email   string `json:"email"`
		Phone   string `json:"phone"`
		RoomNo  string `json:"roomno"`
		CheckIn string `json:"checkin"`
		Status  string `json:"status"`
	}{
		{"1", "Rajesh Kumar", "rajesh.kumar@email.com", "+91-9876543210", "101", "2024-01-15", "active"},
		{"2", "Priya Sharma", "priya.sharma@email.com", "+91-9876543211", "103", "2024-02-01", "active"},
		{"3", "Amit Patel", "amit.patel@email.com", "+91-9876543212", "201", "2024-01-20", "active"},
		{"4", "Neha Singh", "neha.singh@email.com", "+91-9876543213", "203", "2024-03-01", "active"},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func BillGet(w http.ResponseWriter, r *http.Request) {
	response := BillResponse{Status: "success"}
	response.Data = []struct {
		ID       string  `json:"id"`
		UserName string  `json:"username"`
		RoomNo   string  `json:"roomno"`
		Amount   float64 `json:"amount"`
		Type     string  `json:"type"`
		Status   string  `json:"status"`
		DueDate  string  `json:"due_date"`
	}{
		{"1", "Rajesh Kumar", "101", 8000, "rent", "paid", "2024-10-01"},
		{"2", "Priya Sharma", "103", 12000, "rent", "paid", "2024-10-01"},
		{"3", "Amit Patel", "201", 12000, "rent", "pending", "2024-10-01"},
		{"4", "Neha Singh", "203", 15000, "rent", "overdue", "2024-09-01"},
		{"5", "Rajesh Kumar", "101", 500, "maintenance", "pending", "2024-10-15"},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func main() {
	router := mux.NewRouter()

	// Health check
	router.HandleFunc("/health", HealthCheck).Methods("GET")

	// Authentication endpoints
	router.HandleFunc("/admin/login", AdminLogin).Methods("POST", "OPTIONS")
	router.HandleFunc("/tenant/login", TenantLogin).Methods("POST", "OPTIONS")
	router.HandleFunc("/sendotp", SendOTP).Methods("POST", "OPTIONS")

	// Dashboard - matching the original API structure
	router.HandleFunc("/dashboard", Dashboard).Methods("GET")

	// Room endpoints - matching the original API structure
	router.HandleFunc("/room", RoomGet).Methods("GET")

	// User endpoints - matching the original API structure
	router.HandleFunc("/user", UserGet).Methods("GET")

	// Bill endpoints - matching the original API structure
	router.HandleFunc("/bill", BillGet).Methods("GET")

	// Root endpoint
	router.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]string{
			"message": "PG World API Server - Main Solution",
			"status":  "running",
			"version": "1.0.0",
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}).Methods("GET")

	fmt.Println("=========================================")
	fmt.Println("🏢 PG World API Server - Main Solution")
	fmt.Println("=========================================")
	fmt.Println("🚀 Server: http://localhost:8080")
	fmt.Println("❤️  Health: http://localhost:8080/health")
	fmt.Println("📊 Dashboard: http://localhost:8080/dashboard")
	fmt.Println("🏠 Rooms: http://localhost:8080/room")
	fmt.Println("👥 Users: http://localhost:8080/user")
	fmt.Println("💰 Bills: http://localhost:8080/bill")
	fmt.Println("=========================================")
	fmt.Println("")
	log.Fatal(http.ListenAndServe(":8080", &WithCORS{router}))
}
