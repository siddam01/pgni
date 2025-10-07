package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

// Demo Data Structures
type Room struct {
	ID         int    `json:"id"`
	Number     string `json:"number"`
	Type       string `json:"type"`
	Status     string `json:"status"`
	Rent       int    `json:"rent"`
	TenantName string `json:"tenant_name,omitempty"`
	CheckIn    string `json:"check_in,omitempty"`
}

type Tenant struct {
	ID      int    `json:"id"`
	Name    string `json:"name"`
	Email   string `json:"email"`
	Phone   string `json:"phone"`
	Room    string `json:"room"`
	CheckIn string `json:"check_in"`
	Status  string `json:"status"`
}

type Bill struct {
	ID     int     `json:"id"`
	Room   string  `json:"room"`
	Tenant string  `json:"tenant"`
	Amount float64 `json:"amount"`
	Type   string  `json:"type"`
	Status string  `json:"status"`
	Date   string  `json:"date"`
}

type DashboardStats struct {
	TotalRooms     int `json:"total_rooms"`
	OccupiedRooms  int `json:"occupied_rooms"`
	TotalTenants   int `json:"total_tenants"`
	MonthlyRevenue int `json:"monthly_revenue"`
}

// Demo Data
var rooms = []Room{
	{1, "101", "Single", "occupied", 8000, "Raj Patel", "2024-01-15"},
	{2, "102", "Single", "available", 8000, "", ""},
	{3, "103", "Double", "occupied", 12000, "Amit Kumar", "2024-02-01"},
	{4, "104", "Single", "maintenance", 8000, "", ""},
	{5, "105", "Double", "occupied", 12000, "Priya Singh", "2024-01-20"},
	{6, "201", "Single", "available", 8500, "", ""},
	{7, "202", "Double", "occupied", 13000, "Vikash Sharma", "2024-03-01"},
	{8, "203", "Single", "occupied", 8500, "Neha Gupta", "2024-02-15"},
}

var tenants = []Tenant{
	{1, "Raj Patel", "raj.patel@email.com", "+91-9876543210", "101", "2024-01-15", "active"},
	{2, "Amit Kumar", "amit.kumar@email.com", "+91-9876543211", "103", "2024-02-01", "active"},
	{3, "Priya Singh", "priya.singh@email.com", "+91-9876543212", "105", "2024-01-20", "active"},
	{4, "Vikash Sharma", "vikash.sharma@email.com", "+91-9876543213", "202", "2024-03-01", "active"},
	{5, "Neha Gupta", "neha.gupta@email.com", "+91-9876543214", "203", "2024-02-15", "active"},
}

var bills = []Bill{
	{1, "101", "Raj Patel", 8000, "rent", "paid", "2024-10-01"},
	{2, "103", "Amit Kumar", 12000, "rent", "paid", "2024-10-01"},
	{3, "105", "Priya Singh", 12000, "rent", "pending", "2024-10-01"},
	{4, "202", "Vikash Sharma", 13000, "rent", "paid", "2024-10-01"},
	{5, "203", "Neha Gupta", 8500, "rent", "overdue", "2024-09-01"},
	{6, "101", "Raj Patel", 500, "electricity", "pending", "2024-10-01"},
}

// CORS Middleware
func enableCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// API Handlers
func getDashboard(w http.ResponseWriter, r *http.Request) {
	occupiedCount := 0
	for _, room := range rooms {
		if room.Status == "occupied" {
			occupiedCount++
		}
	}

	stats := DashboardStats{
		TotalRooms:     len(rooms),
		OccupiedRooms:  occupiedCount,
		TotalTenants:   len(tenants),
		MonthlyRevenue: 245000,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(stats)
}

func getRooms(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(rooms)
}

func getTenants(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tenants)
}

func getBills(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(bills)
}

func getRoom(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid room ID", http.StatusBadRequest)
		return
	}

	for _, room := range rooms {
		if room.ID == id {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(room)
			return
		}
	}

	http.Error(w, "Room not found", http.StatusNotFound)
}

func getTenant(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		http.Error(w, "Invalid tenant ID", http.StatusBadRequest)
		return
	}

	for _, tenant := range tenants {
		if tenant.ID == id {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(tenant)
			return
		}
	}

	http.Error(w, "Tenant not found", http.StatusNotFound)
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().Format(time.RFC3339),
		"service":   "CloudPG Demo API",
		"version":   "1.0.0",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func main() {
	r := mux.NewRouter()

	// Enable CORS for all routes
	r.Use(enableCORS)

	// API Routes
	r.HandleFunc("/api/health", healthCheck).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/dashboard", getDashboard).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/rooms", getRooms).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/rooms/{id}", getRoom).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/tenants", getTenants).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/tenants/{id}", getTenant).Methods("GET", "OPTIONS")
	r.HandleFunc("/api/bills", getBills).Methods("GET", "OPTIONS")

	// Root endpoint
	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		response := map[string]string{
			"message": "CloudPG Demo API Server",
			"status":  "running",
			"version": "1.0.0",
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}).Methods("GET")

	port := ":8082"
	fmt.Printf("🚀 CloudPG Demo API Server starting on port %s\n", port)
	fmt.Println("📊 Dashboard: http://localhost:8082/api/dashboard")
	fmt.Println("🏠 Rooms: http://localhost:8082/api/rooms")
	fmt.Println("👥 Tenants: http://localhost:8082/api/tenants")
	fmt.Println("💰 Bills: http://localhost:8082/api/bills")
	fmt.Println("❤️  Health: http://localhost:8082/api/health")

	log.Fatal(http.ListenAndServe(port, r))
}
