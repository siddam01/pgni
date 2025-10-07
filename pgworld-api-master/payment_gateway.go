package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"database/sql"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/skip2/go-qrcode"
)

// PaymentGatewayGet - Get payment gateways for an owner
func PaymentGatewayGet(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	adminID := params.Get("admin_id")
	hostelID := params.Get("hostel_id")

	if adminID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id required", dialogType, response)
		return
	}

	where := "admin_id = '" + adminID + "'"
	if hostelID != "" {
		where += " AND (hostel_id = '" + hostelID + "' OR hostel_id IS NULL)"
	}
	where += " AND status = '1'"

	SQLQuery := "SELECT * FROM payment_gateways WHERE " + where
	rows, err := db.Query(SQLQuery)
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, err.Error(), dialogType, response)
		return
	}
	defer rows.Close()

	var gateways []map[string]interface{}
	for rows.Next() {
		var (
			id, adminIDCol, hostelIDCol, gatewayType, apiKeyEncrypted, apiSecretEncrypted sql.NullString
			merchantID, encryptionIV, qrCodeURL, paymentLink, upiID, webhookSecret        sql.NullString
			status                                                                        sql.NullString
			kycVerified, payoutEnabled, autoCapture                                       sql.NullBool
			settlementDays                                                                sql.NullInt64
			verifiedAt, lastUsedAt, createdAt, updatedAt                                  sql.NullTime
		)

		err := rows.Scan(
			&id, &adminIDCol, &hostelIDCol, &gatewayType,
			&apiKeyEncrypted, &apiSecretEncrypted, &merchantID, &encryptionIV,
			&qrCodeURL, &paymentLink, &upiID,
			&kycVerified, &payoutEnabled, &webhookSecret,
			&autoCapture, &settlementDays,
			&status, &verifiedAt, &lastUsedAt, &createdAt, &updatedAt,
		)

		if err != nil {
			continue
		}

		gateway := map[string]interface{}{
			"id":              id.String,
			"admin_id":        adminIDCol.String,
			"hostel_id":       hostelIDCol.String,
			"gateway_type":    gatewayType.String,
			"merchant_id":     merchantID.String,
			"qr_code_url":     qrCodeURL.String,
			"payment_link":    paymentLink.String,
			"upi_id":          upiID.String,
			"kyc_verified":    kycVerified.Bool,
			"payout_enabled":  payoutEnabled.Bool,
			"auto_capture":    autoCapture.Bool,
			"settlement_days": settlementDays.Int64,
			"status":          status.String,
			"verified_at":     verifiedAt.Time,
			"last_used_at":    lastUsedAt.Time,
			"created_at":      createdAt.Time,
		}
		// Don't send encrypted keys to client
		gateways = append(gateways, gateway)
	}

	response["data"] = gateways
	response["meta"] = setMeta(statusCodeOk, "Success", "")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// PaymentGatewayAdd - Add new payment gateway for owner
func PaymentGatewayAdd(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	body := map[string]string{}
	r.ParseMultipartForm(32 << 20)

	for key, value := range r.Form {
		body[key] = value[0]
	}

	// Required fields
	requiredFields := []string{"admin_id", "gateway_type", "api_key", "api_secret"}
	for _, field := range requiredFields {
		if body[field] == "" {
			SetReponseStatus(w, r, statusCodeBadRequest, field+" required", dialogType, response)
			return
		}
	}

	// Encrypt API credentials
	encryptedKey, iv1, err := encryptString(body["api_key"])
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, "Encryption failed", dialogType, response)
		return
	}

	encryptedSecret, iv2, err := encryptString(body["api_secret"])
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, "Encryption failed", dialogType, response)
		return
	}

	// Generate ID
	gatewayID := RandStringBytes(15)

	// Insert into database
	insertData := map[string]string{
		"id":                   gatewayID,
		"admin_id":             body["admin_id"],
		"hostel_id":            body["hostel_id"], // Can be NULL for all properties
		"gateway_type":         body["gateway_type"],
		"api_key_encrypted":    encryptedKey,
		"api_secret_encrypted": encryptedSecret,
		"merchant_id":          body["merchant_id"],
		"encryption_iv":        iv1 + ":" + iv2, // Store both IVs
		"upi_id":               body["upi_id"],
		"webhook_secret":       RandStringBytes(32), // Generate webhook secret
		"status":               "1",
		"kyc_verified":         "0", // Needs verification
		"payout_enabled":       "0",
	}

	status, ok := insertSQL("payment_gateways", insertData)
	if !ok {
		SetReponseStatus(w, r, status, "Failed to add payment gateway", dialogType, response)
		return
	}

	// Generate QR code and payment link
	go generateQRCodeForGateway(gatewayID, body["admin_id"], body["hostel_id"], body["upi_id"])

	response["data"] = map[string]string{"gateway_id": gatewayID}
	response["meta"] = setMeta(statusCodeCreated, "Payment gateway added successfully", dialogType)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// PaymentGatewayUpdate - Update payment gateway settings
func PaymentGatewayUpdate(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	gatewayID := params.Get("id")
	adminID := params.Get("admin_id")

	if gatewayID == "" || adminID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "id and admin_id required", dialogType, response)
		return
	}

	body := map[string]string{}
	r.ParseMultipartForm(32 << 20)

	for key, value := range r.Form {
		body[key] = value[0]
	}

	// Build update query
	updateFields := []string{}
	for key, value := range body {
		if key != "id" && key != "admin_id" {
			updateFields = append(updateFields, "`"+key+"` = '"+value+"'")
		}
	}

	if len(updateFields) == 0 {
		SetReponseStatus(w, r, statusCodeBadRequest, "No fields to update", dialogType, response)
		return
	}

	SQLQuery := "UPDATE payment_gateways SET " + strings.Join(updateFields, ", ") +
		" WHERE id = '" + gatewayID + "' AND admin_id = '" + adminID + "'"

	_, err := db.Exec(SQLQuery)
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, err.Error(), dialogType, response)
		return
	}

	response["meta"] = setMeta(statusCodeOk, "Payment gateway updated successfully", dialogType)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// PaymentGatewayDelete - Deactivate payment gateway
func PaymentGatewayDelete(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	gatewayID := params.Get("id")
	adminID := params.Get("admin_id")

	if gatewayID == "" || adminID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "id and admin_id required", dialogType, response)
		return
	}

	SQLQuery := "UPDATE payment_gateways SET status = '0' WHERE id = '" + gatewayID +
		"' AND admin_id = '" + adminID + "'"

	_, err := db.Exec(SQLQuery)
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, err.Error(), dialogType, response)
		return
	}

	response["meta"] = setMeta(statusCodeOk, "Payment gateway deleted successfully", dialogType)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// VerifyPaymentGateway - Verify gateway credentials with actual API call
func VerifyPaymentGateway(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	gatewayID := params.Get("id")

	if gatewayID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "id required", dialogType, response)
		return
	}

	// Get gateway details
	var gatewayType, apiKeyEncrypted, apiSecretEncrypted, encryptionIV string
	err := db.QueryRow("SELECT gateway_type, api_key_encrypted, api_secret_encrypted, encryption_iv FROM payment_gateways WHERE id = ?", gatewayID).
		Scan(&gatewayType, &apiKeyEncrypted, &apiSecretEncrypted, &encryptionIV)

	if err != nil {
		SetReponseStatus(w, r, statusCodeBadRequest, "Gateway not found", dialogType, response)
		return
	}

	// Decrypt credentials
	ivs := strings.Split(encryptionIV, ":")
	apiKey, _ := decryptString(apiKeyEncrypted, ivs[0])
	apiSecret, _ := decryptString(apiSecretEncrypted, ivs[1])

	// Verify based on gateway type
	verified := false
	switch gatewayType {
	case "razorpay":
		verified = verifyRazorpay(apiKey, apiSecret)
	case "phonepe":
		verified = verifyPhonePe(apiKey, apiSecret)
	case "paytm":
		verified = verifyPaytm(apiKey, apiSecret)
	}

	if verified {
		// Update verification status
		db.Exec("UPDATE payment_gateways SET kyc_verified = TRUE, payout_enabled = TRUE, verified_at = ? WHERE id = ?",
			time.Now(), gatewayID)

		response["meta"] = setMeta(statusCodeOk, "Payment gateway verified successfully", dialogType)
	} else {
		response["meta"] = setMeta(statusCodeBadRequest, "Gateway verification failed. Check credentials", dialogType)
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// Helper: Encrypt string using AES
func encryptString(plaintext string) (string, string, error) {
	key := []byte(encryptionKey) // From config
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", "", err
	}

	plainBytes := []byte(plaintext)
	ciphertext := make([]byte, aes.BlockSize+len(plainBytes))
	iv := ciphertext[:aes.BlockSize]

	if _, err := io.ReadFull(rand.Reader, iv); err != nil {
		return "", "", err
	}

	stream := cipher.NewCFBEncrypter(block, iv)
	stream.XORKeyStream(ciphertext[aes.BlockSize:], plainBytes)

	return base64.URLEncoding.EncodeToString(ciphertext), base64.URLEncoding.EncodeToString(iv), nil
}

// Helper: Decrypt string using AES
func decryptString(encrypted string, ivString string) (string, error) {
	key := []byte(encryptionKey)
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", err
	}

	ciphertext, _ := base64.URLEncoding.DecodeString(encrypted)
	iv, _ := base64.URLEncoding.DecodeString(ivString)

	if len(ciphertext) < aes.BlockSize {
		return "", fmt.Errorf("ciphertext too short")
	}

	stream := cipher.NewCFBDecrypter(block, iv)
	stream.XORKeyStream(ciphertext, ciphertext)

	return string(ciphertext[aes.BlockSize:]), nil
}

// Helper: Generate QR code
func generateQRCodeForGateway(gatewayID, adminID, hostelID, upiID string) {
	if hostelID == "" {
		return // Skip if no specific hostel
	}

	// Create UPI payment string
	// Format: upi://pay?pa=UPI_ID&pn=NAME&cu=INR
	var hostelName string
	db.QueryRow("SELECT name FROM hostels WHERE id = ?", hostelID).Scan(&hostelName)

	upiString := fmt.Sprintf("upi://pay?pa=%s&pn=%s&cu=INR", upiID, hostelName)

	// Generate QR code
	qr, err := qrcode.New(upiString, qrcode.Medium)
	if err != nil {
		return
	}

	// Save QR code to file/S3
	// qrCodeData := qr.ToString(false)
	qrCodeURL := saveQRCodeToS3(gatewayID, qr) // Implement S3 upload

	// Insert QR code record
	qrID := RandStringBytes(12)
	insertData := map[string]string{
		"id":                qrID,
		"hostel_id":         hostelID,
		"admin_id":          adminID,
		"gateway_id":        gatewayID,
		"qr_code_image_url": qrCodeURL,
		"qr_code_data":      upiString,
		"upi_id":            upiID,
		"status":            "1",
	}

	insertSQL("qr_codes", insertData)

	// Update payment gateway with QR URL
	db.Exec("UPDATE payment_gateways SET qr_code_url = ?, payment_link = ? WHERE id = ?",
		qrCodeURL, upiString, gatewayID)
}

// Helper: Verify Razorpay credentials
func verifyRazorpay(apiKey, apiSecret string) bool {
	// Make API call to Razorpay to verify credentials
	// This is a simplified version
	req, _ := http.NewRequest("GET", "https://api.razorpay.com/v1/payments", nil)
	req.SetBasicAuth(apiKey, apiSecret)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return false
	}
	defer resp.Body.Close()

	return resp.StatusCode == 200
}

// Helper: Verify PhonePe credentials
func verifyPhonePe(apiKey, apiSecret string) bool {
	// Implement PhonePe verification
	// This is a placeholder
	return len(apiKey) > 0 && len(apiSecret) > 0
}

// Helper: Verify Paytm credentials
func verifyPaytm(apiKey, apiSecret string) bool {
	// Implement Paytm verification
	// This is a placeholder
	return len(apiKey) > 0 && len(apiSecret) > 0
}

// Helper: Save QR code to S3 (placeholder)
func saveQRCodeToS3(gatewayID string, qr *qrcode.QRCode) string {
	// Implement S3 upload
	// For now, return a placeholder URL
	return "https://" + s3Bucket + ".s3.amazonaws.com/qrcodes/" + gatewayID + ".png"
}
