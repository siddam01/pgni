package main

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"path/filepath"
	"time"
)

// KYCUpload - Upload KYC document
func KYCUpload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	adminID := r.FormValue("admin_id")
	documentType := r.FormValue("document_type") // pan, gstin, aadhar, address_proof, bank_statement
	documentNumber := r.FormValue("document_number")

	if adminID == "" || documentType == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id and document_type required", dialogType, response)
		return
	}

	// Handle file upload
	file, header, err := r.FormFile("document")
	if err != nil {
		SetReponseStatus(w, r, statusCodeBadRequest, "Document file required", dialogType, response)
		return
	}
	defer file.Close()

	// Get file extension
	extension := filepath.Ext(header.Filename)

	// Upload to S3
	documentURL, success := uploadToS3("kyc/"+adminID+"/"+documentType, file, extension)
	if !success {
		SetReponseStatus(w, r, statusCodeServerError, "File upload failed", dialogType, response)
		return
	}

	// Save to database
	docID := RandStringBytes(15)
	insertData := map[string]string{
		"id":                  docID,
		"admin_id":            adminID,
		"document_type":       documentType,
		"document_number":     documentNumber,
		"document_url":        documentURL,
		"verification_status": "pending",
	}

	status, ok := insertSQL("kyc_documents", insertData)
	if !ok {
		SetReponseStatus(w, r, status, "Failed to save document", dialogType, response)
		return
	}

	// Update onboarding progress
	db.Exec("UPDATE onboarding_progress SET step_kyc_upload = TRUE, current_step = GREATEST(current_step, 3) WHERE admin_id = ?", adminID)

	response["data"] = map[string]string{
		"document_id":  docID,
		"document_url": documentURL,
	}
	response["meta"] = setMeta(statusCodeCreated, "KYC document uploaded successfully", dialogType)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// KYCDocumentsGet - Get all KYC documents for an admin
func KYCDocumentsGet(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	adminID := params.Get("admin_id")

	if adminID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id required", dialogType, response)
		return
	}

	SQLQuery := "SELECT id, document_type, document_number, document_url, verification_status, rejection_reason, uploaded_at, verified_at FROM kyc_documents WHERE admin_id = ? ORDER BY uploaded_at DESC"
	rows, err := db.Query(SQLQuery, adminID)
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, err.Error(), dialogType, response)
		return
	}
	defer rows.Close()

	var documents []map[string]interface{}
	for rows.Next() {
		var (
			id, documentType, documentNumber, documentURL, verificationStatus sql.NullString
			rejectionReason                                                   sql.NullString
			uploadedAt, verifiedAt                                            sql.NullTime
		)

		rows.Scan(&id, &documentType, &documentNumber, &documentURL, &verificationStatus,
			&rejectionReason, &uploadedAt, &verifiedAt)

		doc := map[string]interface{}{
			"id":                  id.String,
			"document_type":       documentType.String,
			"document_number":     documentNumber.String,
			"document_url":        documentURL.String,
			"verification_status": verificationStatus.String,
			"rejection_reason":    rejectionReason.String,
			"uploaded_at":         uploadedAt.Time,
			"verified_at":         verifiedAt.Time,
		}
		documents = append(documents, doc)
	}

	// Get admin KYC status
	var kycStatus sql.NullString
	db.QueryRow("SELECT kyc_status FROM admins WHERE id = ?", adminID).Scan(&kycStatus)

	response["data"] = documents
	response["kyc_status"] = kycStatus.String
	response["meta"] = setMeta(statusCodeOk, "Success", "")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// KYCVerify - Verify a KYC document (admin action)
func KYCVerify(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	documentID := r.FormValue("document_id")
	verifiedBy := r.FormValue("verified_by")
	status := r.FormValue("status") // verified, rejected
	rejectionReason := r.FormValue("rejection_reason")

	if documentID == "" || verifiedBy == "" || status == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "document_id, verified_by and status required", dialogType, response)
		return
	}

	// Update document status
	SQLQuery := "UPDATE kyc_documents SET verification_status = ?, verified_by = ?, verified_at = ?, rejection_reason = ? WHERE id = ?"
	_, err := db.Exec(SQLQuery, status, verifiedBy, time.Now(), rejectionReason, documentID)
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, err.Error(), dialogType, response)
		return
	}

	// Get admin ID
	var adminID string
	db.QueryRow("SELECT admin_id FROM kyc_documents WHERE id = ?", documentID).Scan(&adminID)

	// Check if all documents are verified
	var pendingDocs int
	db.QueryRow("SELECT COUNT(*) FROM kyc_documents WHERE admin_id = ? AND verification_status = 'pending'", adminID).Scan(&pendingDocs)

	if status == "verified" && pendingDocs == 0 {
		// All documents verified, update admin KYC status
		db.Exec("UPDATE admins SET kyc_status = '1' WHERE id = ?", adminID)
	} else if status == "rejected" {
		db.Exec("UPDATE admins SET kyc_status = '2' WHERE id = ?", adminID)
	}

	response["meta"] = setMeta(statusCodeOk, "Document "+status+" successfully", dialogType)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// KYCSubmit - Submit all KYC documents for verification
func KYCSubmit(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	adminID := r.FormValue("admin_id")

	if adminID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id required", dialogType, response)
		return
	}

	// Check if minimum required documents are uploaded
	requiredDocs := []string{"pan", "gstin", "aadhar", "address_proof"}
	for _, docType := range requiredDocs {
		var count int
		db.QueryRow("SELECT COUNT(*) FROM kyc_documents WHERE admin_id = ? AND document_type = ?", adminID, docType).Scan(&count)
		if count == 0 {
			SetReponseStatus(w, r, statusCodeBadRequest, docType+" document required", dialogType, response)
			return
		}
	}

	// Mark all documents as submitted (change from 'draft' if applicable)
	db.Exec("UPDATE kyc_documents SET verification_status = 'pending' WHERE admin_id = ? AND verification_status = 'draft'", adminID)

	// Update admin KYC status to pending
	db.Exec("UPDATE admins SET kyc_status = '0' WHERE id = ?", adminID)

	// Send notification to super admin for verification
	// TODO: Implement notification

	response["meta"] = setMeta(statusCodeOk, "KYC submitted for verification", dialogType)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// KYCStatus - Get overall KYC status
func KYCStatus(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	adminID := params.Get("admin_id")

	if adminID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id required", dialogType, response)
		return
	}

	// Get admin KYC status
	var kycStatus, payoutEnabled sql.NullString
	var payoutEnabledBool sql.NullBool
	db.QueryRow("SELECT kyc_status, payout_enabled FROM admins WHERE id = ?", adminID).
		Scan(&kycStatus, &payoutEnabledBool)

	if payoutEnabledBool.Bool {
		payoutEnabled.String = "1"
	} else {
		payoutEnabled.String = "0"
	}

	// Count documents by status
	var totalDocs, verifiedDocs, pendingDocs, rejectedDocs int
	db.QueryRow("SELECT COUNT(*) FROM kyc_documents WHERE admin_id = ?", adminID).Scan(&totalDocs)
	db.QueryRow("SELECT COUNT(*) FROM kyc_documents WHERE admin_id = ? AND verification_status = 'verified'", adminID).Scan(&verifiedDocs)
	db.QueryRow("SELECT COUNT(*) FROM kyc_documents WHERE admin_id = ? AND verification_status = 'pending'", adminID).Scan(&pendingDocs)
	db.QueryRow("SELECT COUNT(*) FROM kyc_documents WHERE admin_id = ? AND verification_status = 'rejected'", adminID).Scan(&rejectedDocs)

	// Calculate completion percentage
	completionPercent := 0
	if totalDocs > 0 {
		completionPercent = (verifiedDocs * 100) / totalDocs
	}

	response["data"] = map[string]interface{}{
		"kyc_status":         kycStatus.String, // 0=pending, 1=verified, 2=rejected
		"payout_enabled":     payoutEnabled.String,
		"total_documents":    totalDocs,
		"verified_documents": verifiedDocs,
		"pending_documents":  pendingDocs,
		"rejected_documents": rejectedDocs,
		"completion_percent": completionPercent,
		"can_proceed":        kycStatus.String == "1" && payoutEnabledBool.Bool,
	}
	response["meta"] = setMeta(statusCodeOk, "Success", "")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}
