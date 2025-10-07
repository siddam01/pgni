package main

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"regexp"
)

// OnboardingRegister - Step 1: Register new owner
func OnboardingRegister(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	// Required fields
	requiredFields := map[string]string{
		"name":          r.FormValue("name"),
		"email":         r.FormValue("email"),
		"phone":         r.FormValue("phone"),
		"password":      r.FormValue("password"),
		"gstin":         r.FormValue("gstin"),
		"pan":           r.FormValue("pan"),
		"business_name": r.FormValue("business_name"),
	}

	// Validate required fields
	for field, value := range requiredFields {
		if value == "" {
			SetReponseStatus(w, r, statusCodeBadRequest, field+" required", dialogType, response)
			return
		}
	}

	// Validate GSTIN format (15 characters alphanumeric)
	gstinRegex := regexp.MustCompile(`^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$`)
	if !gstinRegex.MatchString(requiredFields["gstin"]) {
		SetReponseStatus(w, r, statusCodeBadRequest, "Invalid GSTIN format", dialogType, response)
		return
	}

	// Validate PAN format (10 characters alphanumeric)
	panRegex := regexp.MustCompile(`^[A-Z]{5}[0-9]{4}[A-Z]{1}$`)
	if !panRegex.MatchString(requiredFields["pan"]) {
		SetReponseStatus(w, r, statusCodeBadRequest, "Invalid PAN format", dialogType, response)
		return
	}

	// Check if email/phone already exists
	var exists int
	db.QueryRow("SELECT COUNT(*) FROM admins WHERE email = ? OR phone = ?", requiredFields["email"], requiredFields["phone"]).Scan(&exists)
	if exists > 0 {
		SetReponseStatus(w, r, statusCodeBadRequest, "Email or phone already registered", dialogType, response)
		return
	}

	// Check if GSTIN already exists
	db.QueryRow("SELECT COUNT(*) FROM admins WHERE gstin = ?", requiredFields["gstin"]).Scan(&exists)
	if exists > 0 {
		SetReponseStatus(w, r, statusCodeBadRequest, "GSTIN already registered", dialogType, response)
		return
	}

	// Create owner account
	adminID := RandStringBytes(12)
	username := GenerateUsername(requiredFields["name"])

	insertData := map[string]string{
		"id":               adminID,
		"username":         username,
		"password":         requiredFields["password"], // Should be hashed in production
		"name":             requiredFields["name"],
		"email":            requiredFields["email"],
		"phone":            requiredFields["phone"],
		"gstin":            requiredFields["gstin"],
		"pan":              requiredFields["pan"],
		"business_name":    requiredFields["business_name"],
		"business_address": r.FormValue("business_address"),
		"role":             "owner",
		"kyc_status":       "0", // Pending
		"status":           "1",
		"hostel_ids":       "",
	}

	status, ok := insertSQL("admins", insertData)
	if !ok {
		SetReponseStatus(w, r, status, "Failed to register owner", dialogType, response)
		return
	}

	// Onboarding progress is auto-created by trigger
	// But we can verify/create it manually
	// onboardingID := "onb_" + adminID
	onboardingData := map[string]string{
		"id":                "onb_" + adminID,
		"admin_id":          adminID,
		"step_registration": "1",
		"current_step":      "2", // Move to property setup
	}
	insertSQL("onboarding_progress", onboardingData)

	response["data"] = map[string]string{
		"admin_id": adminID,
		"username": username,
		"email":    requiredFields["email"],
	}
	response["meta"] = setMeta(statusCodeCreated, "Owner registered successfully", dialogType)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// OnboardingProperty - Step 2: Add first property
func OnboardingProperty(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	adminID := r.FormValue("admin_id")
	hostelName := r.FormValue("name")
	address := r.FormValue("address")
	phone := r.FormValue("phone")

	if adminID == "" || hostelName == "" || address == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id, name and address required", dialogType, response)
		return
	}

	// Create hostel
	hostelID := RandStringBytes(12)

	hostelData := map[string]string{
		"id":        hostelID,
		"admin_id":  adminID,
		"name":      hostelName,
		"address":   address,
		"phone":     phone,
		"email":     r.FormValue("email"),
		"city":      r.FormValue("city"),
		"state":     r.FormValue("state"),
		"pincode":   r.FormValue("pincode"),
		"capacity":  r.FormValue("capacity"),
		"occupied":  "0",
		"amenities": r.FormValue("amenities"), // JSON string
		"images":    r.FormValue("images"),    // JSON string
		"status":    "1",
	}

	status, ok := insertSQL("hostels", hostelData)
	if !ok {
		SetReponseStatus(w, r, status, "Failed to add property", dialogType, response)
		return
	}

	// Update admin's hostel_ids
	db.Exec("UPDATE admins SET hostel_ids = ? WHERE id = ?", hostelID, adminID)

	// Update onboarding progress
	db.Exec("UPDATE onboarding_progress SET step_property_setup = TRUE, current_step = 3 WHERE admin_id = ?", adminID)

	response["data"] = map[string]string{
		"hostel_id": hostelID,
		"name":      hostelName,
	}
	response["meta"] = setMeta(statusCodeCreated, "Property added successfully", dialogType)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// OnboardingProgress - Get current onboarding progress
func OnboardingProgress(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	adminID := params.Get("admin_id")

	if adminID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id required", dialogType, response)
		return
	}

	SQLQuery := `
		SELECT 
			step_registration,
			step_property_setup,
			step_kyc_upload,
			step_kyc_verification,
			step_payment_gateway,
			step_qr_generation,
			step_completed,
			current_step,
			started_at,
			completed_at
		FROM onboarding_progress 
		WHERE admin_id = ?
	`

	var (
		stepReg, stepProperty, stepKYCUpload, stepKYCVerified bool
		stepPayment, stepQR, stepCompleted                    bool
		currentStep                                           int
		startedAt, completedAt                                sql.NullTime
	)

	err := db.QueryRow(SQLQuery, adminID).Scan(
		&stepReg, &stepProperty, &stepKYCUpload, &stepKYCVerified,
		&stepPayment, &stepQR, &stepCompleted,
		&currentStep, &startedAt, &completedAt,
	)

	if err != nil {
		// Create onboarding progress if not exists
		onboardingData := map[string]string{
			"id":                "onb_" + adminID,
			"admin_id":          adminID,
			"step_registration": "1",
			"current_step":      "1",
		}
		insertSQL("onboarding_progress", onboardingData)

		stepReg = true
		currentStep = 1
	}

	// Calculate overall progress
	totalSteps := 7
	completedSteps := 0
	if stepReg {
		completedSteps++
	}
	if stepProperty {
		completedSteps++
	}
	if stepKYCUpload {
		completedSteps++
	}
	if stepKYCVerified {
		completedSteps++
	}
	if stepPayment {
		completedSteps++
	}
	if stepQR {
		completedSteps++
	}
	if stepCompleted {
		completedSteps++
	}

	progressPercent := (completedSteps * 100) / totalSteps

	// Define step details
	steps := []map[string]interface{}{
		{
			"step":      1,
			"title":     "Owner Registration",
			"completed": stepReg,
			"current":   currentStep == 1,
		},
		{
			"step":      2,
			"title":     "Property Setup",
			"completed": stepProperty,
			"current":   currentStep == 2,
		},
		{
			"step":      3,
			"title":     "KYC Document Upload",
			"completed": stepKYCUpload,
			"current":   currentStep == 3,
		},
		{
			"step":      4,
			"title":     "KYC Verification",
			"completed": stepKYCVerified,
			"current":   currentStep == 4,
		},
		{
			"step":      5,
			"title":     "Payment Gateway Connection",
			"completed": stepPayment,
			"current":   currentStep == 5,
		},
		{
			"step":      6,
			"title":     "QR Code Generation",
			"completed": stepQR,
			"current":   currentStep == 6,
		},
		{
			"step":      7,
			"title":     "Onboarding Complete",
			"completed": stepCompleted,
			"current":   currentStep == 7,
		},
	}

	response["data"] = map[string]interface{}{
		"current_step":     currentStep,
		"progress_percent": progressPercent,
		"completed_steps":  completedSteps,
		"total_steps":      totalSteps,
		"is_completed":     stepCompleted,
		"started_at":       startedAt.Time,
		"completed_at":     completedAt.Time,
		"steps":            steps,
	}
	response["meta"] = setMeta(statusCodeOk, "Success", "")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// OnboardingComplete - Mark onboarding as complete
func OnboardingComplete(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	adminID := r.FormValue("admin_id")

	if adminID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id required", dialogType, response)
		return
	}

	// Verify all steps are completed
	var kycStatus, payoutEnabled sql.NullString
	db.QueryRow("SELECT kyc_status, payout_enabled FROM admins WHERE id = ?", adminID).
		Scan(&kycStatus, &payoutEnabled)

	if kycStatus.String != "1" {
		SetReponseStatus(w, r, statusCodeBadRequest, "KYC verification pending", dialogType, response)
		return
	}

	// Check if payment gateway is connected
	var gatewayCount int
	db.QueryRow("SELECT COUNT(*) FROM payment_gateways WHERE admin_id = ? AND status = '1'", adminID).Scan(&gatewayCount)
	if gatewayCount == 0 {
		SetReponseStatus(w, r, statusCodeBadRequest, "Payment gateway not connected", dialogType, response)
		return
	}

	// Mark onboarding as complete
	SQLQuery := `
		UPDATE onboarding_progress 
		SET 
			step_completed = TRUE,
			current_step = 7,
			completed_at = NOW()
		WHERE admin_id = ?
	`
	_, err := db.Exec(SQLQuery, adminID)
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, err.Error(), dialogType, response)
		return
	}

	// Enable payout if not already enabled
	db.Exec("UPDATE admins SET payout_enabled = TRUE WHERE id = ?", adminID)

	response["meta"] = setMeta(statusCodeOk, "Onboarding completed successfully! Welcome aboard.", dialogType)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// OnboardingSkipStep - Allow skipping optional steps
func OnboardingSkipStep(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	adminID := r.FormValue("admin_id")
	stepNumber := r.FormValue("step")

	if adminID == "" || stepNumber == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id and step required", dialogType, response)
		return
	}

	// Only allow skipping optional steps (3 - KYC upload can be delayed)
	// But prevent skipping required steps
	if stepNumber == "4" || stepNumber == "5" {
		SetReponseStatus(w, r, statusCodeBadRequest, "Cannot skip required step", dialogType, response)
		return
	}

	// Update current step to next
	db.Exec("UPDATE onboarding_progress SET current_step = current_step + 1 WHERE admin_id = ?", adminID)

	response["meta"] = setMeta(statusCodeOk, "Step skipped", dialogType)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// Helper: Generate username from name
func GenerateUsername(name string) string {
	// Remove spaces, convert to lowercase, add random suffix
	username := regexp.MustCompile(`[^a-zA-Z0-9]+`).ReplaceAllString(name, "")
	username = username + RandStringBytes(4)
	return username
}
