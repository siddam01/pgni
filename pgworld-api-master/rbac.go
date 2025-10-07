package main

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strings"
)

// ManagerInvite - Owner invites a manager
func ManagerInvite(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	ownerID := r.FormValue("owner_id")
	managerEmail := r.FormValue("email")
	managerPhone := r.FormValue("phone")
	managerName := r.FormValue("name")
	hostelIDs := r.FormValue("hostel_ids") // Comma-separated
	password := r.FormValue("password")

	if ownerID == "" || managerEmail == "" || managerName == "" || hostelIDs == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "owner_id, email, name and hostel_ids required", dialogType, response)
		return
	}

	// Verify owner exists and is an owner
	var ownerRole string
	err := db.QueryRow("SELECT role FROM admins WHERE id = ?", ownerID).Scan(&ownerRole)
	if err != nil || ownerRole != "owner" {
		SetReponseStatus(w, r, statusCodeBadRequest, "Invalid owner", dialogType, response)
		return
	}

	// Check if email already exists
	var exists int
	db.QueryRow("SELECT COUNT(*) FROM admins WHERE email = ? OR phone = ?", managerEmail, managerPhone).Scan(&exists)
	if exists > 0 {
		SetReponseStatus(w, r, statusCodeBadRequest, "Email or phone already registered", dialogType, response)
		return
	}

	// Create manager account
	managerID := RandStringBytes(12)
	username := GenerateUsername(managerName)

	managerData := map[string]string{
		"id":                  managerID,
		"username":            username,
		"password":            password, // Should be hashed
		"name":                managerName,
		"email":               managerEmail,
		"phone":               managerPhone,
		"role":                "manager",
		"parent_admin_id":     ownerID,
		"assigned_hostel_ids": hostelIDs,
		"status":              "1",
		"hostel_ids":          hostelIDs, // For compatibility
	}

	status, ok := insertSQL("admins", managerData)
	if !ok {
		SetReponseStatus(w, r, status, "Failed to create manager", dialogType, response)
		return
	}

	// Create default permissions for each hostel
	hostelList := strings.Split(hostelIDs, ",")
	for _, hostelID := range hostelList {
		permID := RandStringBytes(12)
		permData := map[string]string{
			"id":                   permID,
			"admin_id":             managerID,
			"hostel_id":            hostelID,
			"role":                 "manager",
			"can_view_dashboard":   r.FormValue("can_view_dashboard"),
			"can_manage_rooms":     r.FormValue("can_manage_rooms"),
			"can_manage_tenants":   r.FormValue("can_manage_tenants"),
			"can_manage_bills":     r.FormValue("can_manage_bills"),
			"can_view_financials":  r.FormValue("can_view_financials"),
			"can_manage_employees": r.FormValue("can_manage_employees"),
			"can_view_reports":     r.FormValue("can_view_reports"),
			"can_manage_notices":   r.FormValue("can_manage_notices"),
			"can_manage_issues":    r.FormValue("can_manage_issues"),
			"can_manage_payments":  r.FormValue("can_manage_payments"),
			"assigned_by":          ownerID,
			"status":               "1",
		}
		insertSQL("admin_permissions", permData)
	}

	// Send invitation email
	// TODO: Implement email sending

	response["data"] = map[string]string{
		"manager_id": managerID,
		"username":   username,
		"email":      managerEmail,
	}
	response["meta"] = setMeta(statusCodeCreated, "Manager invited successfully", dialogType)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

// ManagerList - Get all managers for an owner
func ManagerList(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	ownerID := params.Get("owner_id")

	if ownerID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "owner_id required", dialogType, response)
		return
	}

	SQLQuery := `
		SELECT 
			a.id, a.username, a.name, a.email, a.phone,
			a.assigned_hostel_ids, a.status, a.created_at
		FROM admins a
		WHERE a.parent_admin_id = ? AND a.role = 'manager'
		ORDER BY a.created_at DESC
	`

	rows, err := db.Query(SQLQuery, ownerID)
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, err.Error(), dialogType, response)
		return
	}
	defer rows.Close()

	var managers []map[string]interface{}
	for rows.Next() {
		var (
			id, username, name, email, phone, hostelIDs, status sql.NullString
			createdAt                                           sql.NullTime
		)

		rows.Scan(&id, &username, &name, &email, &phone, &hostelIDs, &status, &createdAt)

		// Get assigned properties
		var properties []map[string]string
		if hostelIDs.String != "" {
			hostelList := strings.Split(hostelIDs.String, ",")
			for _, hostelID := range hostelList {
				var hostelName string
				db.QueryRow("SELECT name FROM hostels WHERE id = ?", hostelID).Scan(&hostelName)
				properties = append(properties, map[string]string{
					"id":   hostelID,
					"name": hostelName,
				})
			}
		}

		manager := map[string]interface{}{
			"id":         id.String,
			"username":   username.String,
			"name":       name.String,
			"email":      email.String,
			"phone":      phone.String,
			"properties": properties,
			"status":     status.String,
			"created_at": createdAt.Time,
		}
		managers = append(managers, manager)
	}

	response["data"] = managers
	response["meta"] = setMeta(statusCodeOk, "Success", "")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// ManagerPermissions - Update manager permissions
func ManagerPermissions(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	r.ParseMultipartForm(32 << 20)

	ownerID := r.FormValue("owner_id")
	managerID := r.FormValue("manager_id")
	hostelID := r.FormValue("hostel_id")

	if ownerID == "" || managerID == "" || hostelID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "owner_id, manager_id and hostel_id required", dialogType, response)
		return
	}

	// Verify ownership
	var parentAdminID string
	db.QueryRow("SELECT parent_admin_id FROM admins WHERE id = ?", managerID).Scan(&parentAdminID)
	if parentAdminID != ownerID {
		SetReponseStatus(w, r, statusCodeForbidden, "Unauthorized", dialogType, response)
		return
	}

	// Build update query
	updateFields := []string{}
	permissions := []string{
		"can_view_dashboard", "can_manage_rooms", "can_manage_tenants",
		"can_manage_bills", "can_view_financials", "can_manage_employees",
		"can_view_reports", "can_manage_notices", "can_manage_issues",
		"can_manage_payments",
	}

	for _, perm := range permissions {
		if value := r.FormValue(perm); value != "" {
			updateFields = append(updateFields, "`"+perm+"` = '"+value+"'")
		}
	}

	if len(updateFields) == 0 {
		SetReponseStatus(w, r, statusCodeBadRequest, "No permissions to update", dialogType, response)
		return
	}

	SQLQuery := "UPDATE admin_permissions SET " + strings.Join(updateFields, ", ") +
		" WHERE admin_id = ? AND hostel_id = ?"

	_, err := db.Exec(SQLQuery, managerID, hostelID)
	if err != nil {
		SetReponseStatus(w, r, statusCodeServerError, err.Error(), dialogType, response)
		return
	}

	response["meta"] = setMeta(statusCodeOk, "Permissions updated successfully", dialogType)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// ManagerRemove - Remove a manager
func ManagerRemove(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	ownerID := params.Get("owner_id")
	managerID := params.Get("manager_id")

	if ownerID == "" || managerID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "owner_id and manager_id required", dialogType, response)
		return
	}

	// Verify ownership
	var parentAdminID string
	db.QueryRow("SELECT parent_admin_id FROM admins WHERE id = ?", managerID).Scan(&parentAdminID)
	if parentAdminID != ownerID {
		SetReponseStatus(w, r, statusCodeForbidden, "Unauthorized", dialogType, response)
		return
	}

	// Soft delete manager
	db.Exec("UPDATE admins SET status = '0' WHERE id = ?", managerID)

	// Disable all permissions
	db.Exec("UPDATE admin_permissions SET status = '0' WHERE admin_id = ?", managerID)

	response["meta"] = setMeta(statusCodeOk, "Manager removed successfully", dialogType)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// PermissionsCheck - Check if admin has specific permission
func PermissionsCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	adminID := params.Get("admin_id")
	hostelID := params.Get("hostel_id")
	permission := params.Get("permission") // e.g., "can_manage_rooms"

	if adminID == "" || hostelID == "" || permission == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id, hostel_id and permission required", dialogType, response)
		return
	}

	// Check if admin is owner
	var role string
	db.QueryRow("SELECT role FROM admins WHERE id = ?", adminID).Scan(&role)

	if role == "owner" {
		// Owners have all permissions
		response["data"] = map[string]interface{}{
			"has_permission": true,
			"role":           "owner",
		}
	} else if role == "manager" {
		// Check specific permission
		var hasPermission sql.NullBool
		SQLQuery := "SELECT `" + permission + "` FROM admin_permissions WHERE admin_id = ? AND hostel_id = ? AND status = '1'"
		db.QueryRow(SQLQuery, adminID, hostelID).Scan(&hasPermission)

		response["data"] = map[string]interface{}{
			"has_permission": hasPermission.Bool,
			"role":           "manager",
		}
	} else {
		response["data"] = map[string]interface{}{
			"has_permission": false,
			"role":           role,
		}
	}

	response["meta"] = setMeta(statusCodeOk, "Success", "")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// PermissionsGet - Get all permissions for an admin on a property
func PermissionsGet(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	var response = make(map[string]interface{})

	params := r.URL.Query()
	adminID := params.Get("admin_id")
	hostelID := params.Get("hostel_id")

	if adminID == "" || hostelID == "" {
		SetReponseStatus(w, r, statusCodeBadRequest, "admin_id and hostel_id required", dialogType, response)
		return
	}

	// Check if admin is owner
	var role string
	db.QueryRow("SELECT role FROM admins WHERE id = ?", adminID).Scan(&role)

	if role == "owner" {
		// Owners have all permissions
		response["data"] = map[string]interface{}{
			"role":                 "owner",
			"can_view_dashboard":   true,
			"can_manage_rooms":     true,
			"can_manage_tenants":   true,
			"can_manage_bills":     true,
			"can_view_financials":  true,
			"can_manage_employees": true,
			"can_view_reports":     true,
			"can_manage_notices":   true,
			"can_manage_issues":    true,
			"can_manage_payments":  true,
		}
	} else {
		// Get manager permissions
		SQLQuery := `
			SELECT 
				can_view_dashboard, can_manage_rooms, can_manage_tenants,
				can_manage_bills, can_view_financials, can_manage_employees,
				can_view_reports, can_manage_notices, can_manage_issues,
				can_manage_payments
			FROM admin_permissions 
			WHERE admin_id = ? AND hostel_id = ? AND status = '1'
		`

		var (
			canViewDashboard, canManageRooms, canManageTenants       bool
			canManageBills, canViewFinancials, canManageEmployees    bool
			canViewReports, canManageNotices, canManageIssues        bool
			canManagePayments                                        bool
		)

		err := db.QueryRow(SQLQuery, adminID, hostelID).Scan(
			&canViewDashboard, &canManageRooms, &canManageTenants,
			&canManageBills, &canViewFinancials, &canManageEmployees,
			&canViewReports, &canManageNotices, &canManageIssues,
			&canManagePayments,
		)

		if err != nil {
			// No permissions found
			response["data"] = map[string]interface{}{
				"role": "none",
				"has_access": false,
			}
		} else {
			response["data"] = map[string]interface{}{
				"role":                 "manager",
				"can_view_dashboard":   canViewDashboard,
				"can_manage_rooms":     canManageRooms,
				"can_manage_tenants":   canManageTenants,
				"can_manage_bills":     canManageBills,
				"can_view_financials":  canViewFinancials,
				"can_manage_employees": canManageEmployees,
				"can_view_reports":     canViewReports,
				"can_manage_notices":   canManageNotices,
				"can_manage_issues":    canManageIssues,
				"can_manage_payments":  canManagePayments,
			}
		}
	}

	response["meta"] = setMeta(statusCodeOk, "Success", "")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

