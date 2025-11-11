package main

import (
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"log"
	"net/http"
	"os"
)

// DashboardAuthMiddleware provides basic HTTP authentication for the dashboard
func DashboardAuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		username, password, ok := r.BasicAuth()
		if !ok {
			requestAuth(w)
			return
		}

		if !validateDashboardCredentials(username, password) {
			requestAuth(w)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// validateDashboardCredentials checks username and password against environment variables
func validateDashboardCredentials(username, password string) bool {
	expectedUsername := os.Getenv("DASHBOARD_USERNAME")
	expectedPassword := os.Getenv("DASHBOARD_PASSWORD")

	// If no credentials are set, deny access
	if expectedUsername == "" || expectedPassword == "" {
		log.Println("Dashboard credentials not configured - access denied")
		return false
	}

	// Check username (constant time comparison to prevent timing attacks)
	if subtle.ConstantTimeCompare([]byte(username), []byte(expectedUsername)) != 1 {
		return false
	}

	// Check password (constant time comparison)
	if subtle.ConstantTimeCompare([]byte(password), []byte(expectedPassword)) != 1 {
		return false
	}

	return true
}

// requestAuth sends a 401 response requesting basic authentication
func requestAuth(w http.ResponseWriter) {
	w.Header().Set("WWW-Authenticate", `Basic realm="Liberation Analytics Dashboard"`)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	w.Write([]byte(`{"error": "Authentication required", "message": "Please provide valid credentials to access the analytics dashboard"}`))
}

// hashPassword creates a SHA-256 hash for a password (utility function)
func hashPassword(password string) string {
	hash := sha256.Sum256([]byte(password))
	return hex.EncodeToString(hash[:])
}
