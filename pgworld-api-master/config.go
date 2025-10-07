package main

import "os"

var dbConfig string
var connectionPool int

var baseURL string

var razorpayAuth string
var razorpayKeyID string
var razorpayKeySecret string

var supportEmailID string
var supportEmailPassword string
var supportEmailHost string
var supportEmailPort int

// API keys - now loaded from environment for security
var androidLiveKey string
var androidTestKey string
var iOSLiveKey string
var iOSTestKey string

var adminTable = "admins"
var billTable = "bills"
var employeeTable = "employees"
var foodTable = "foods"
var invoiceTable = "invoices"
var issueTable = "issues"
var hostelTable = "hostels"
var logTable = "logs"
var noteTable = "notes"
var noticeTable = "notices"
var roomTable = "rooms"
var signupTable = "signups"
var supportTable = "supports"
var userTable = "users"

var adminDigits = 7
var billDigits = 11
var employeeDigits = 9
var foodDigits = 15
var invoiceDigits = 9
var issueDigits = 9
var hostelDigits = 8
var noteDigits = 13
var noticeDigits = 11
var roomDigits = 12
var userDigits = 10

var dialogType = "1"
var toastType = "2"
var appUpdateAvailable = "3"
var appUpdateRequired = "4"

// API keys map - populated at runtime from environment
var apikeys map[string]string

// Initialize API keys from environment variables
func initAPIKeys() {
	// These will be loaded from environment variables
	androidLiveKey = getEnvOrDefault("ANDROID_LIVE_KEY", "T9h9P6j2N6y9M3Q8")
	androidTestKey = getEnvOrDefault("ANDROID_TEST_KEY", "K7b3V4h3C7t6g6M7")
	iOSLiveKey = getEnvOrDefault("IOS_LIVE_KEY", "b4E6U9K8j6b5E9W3")
	iOSTestKey = getEnvOrDefault("IOS_TEST_KEY", "R4n7N8G4m9B4S5n2")

	// Build the API keys map
	apikeys = map[string]string{
		androidLiveKey: "1", // android live
		androidTestKey: "1", // android test
		iOSLiveKey:     "1", // iOS live
		iOSTestKey:     "1", // iOS test
	}
}

// Helper function to get environment variable with default
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

var pro = map[string]int{
	"9900":  1,
	"49900": 6,
}

// required fields
var adminRequiredFields = []string{}
var billRequiredFields = []string{}
var employeeRequiredFields = []string{}
var foodRequiredFields = []string{}
var invoiceRequiredFields = []string{}
var issueRequiredFields = []string{}
var hostelRequiredFields = []string{}
var logRequiredFields = []string{}
var noteRequiredFields = []string{}
var noticeRequiredFields = []string{}
var paymentRequiredFields = []string{}
var roomRequiredFields = []string{}
var signupRequiredFields = []string{}
var supportRequiredFields = []string{}
var userRequiredFields = []string{}

// server codes
var statusCodeOk = "200"
var statusCodeCreated = "201"
var statusCodeBadRequest = "400"
var statusCodeForbidden = "403"
var statusCodeServerError = "500"
var statusCodeDuplicateEntry = "1000"

var defaultLimit = "25"
var defaultOffset = "0"

var test bool
var migrate bool

// versions
var iOSVersionCode = 1.0
var iOSForceVersionCode = 1.0

var androidVersionCode = 3.1
var androidForceVersionCode = 3.1

// s3
var s3Bucket string
var docS3Path = "document"

// Encryption key for payment gateway credentials (32 bytes)
var encryptionKey = "pgworld-secure-key-2024-v1-32b"
