package main

import (
	"golang.org/x/crypto/bcrypt"
)

// HashPassword creates a bcrypt hash of the password
// PG Owner benefit: Passwords are securely stored, can't be stolen
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPasswordHash compares password with hash
// PG Owner benefit: Secure login without storing plain passwords
func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// ValidatePassword checks if password meets minimum requirements
// PG Owner benefit: Ensures strong passwords for account protection
func ValidatePassword(password string) (bool, string) {
	if len(password) < 6 {
		return false, "Password must be at least 6 characters"
	}
	return true, ""
}
