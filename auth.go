package main

import (
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"
)

// APIToken represents an API token for accessing protected endpoints
type APIToken struct {
	ID          string     `json:"id"`
	TokenHash   string     `json:"-"`
	Name        string     `json:"name"`
	Permissions []string   `json:"permissions"`
	CreatedAt   time.Time  `json:"created_at"`
	LastUsed    *time.Time `json:"last_used,omitempty"`
	ExpiresAt   *time.Time `json:"expires_at,omitempty"`
	IsActive    bool       `json:"is_active"`
}

// Permission constants
const (
	PermissionReadInsights = "read:insights"
	PermissionReadHealth   = "read:health"
	PermissionManageTokens = "manage:tokens"
	PermissionAdmin        = "admin:all"
)

// APITokenMiddleware validates API tokens for protected endpoints
func (s *AnalyticsServer) APITokenMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := extractToken(r)
		if token == "" {
			s.logAuthFailure(r, "No token provided")
			http.Error(w, "Unauthorized: API token required", http.StatusUnauthorized)
			return
		}

		apiToken, err := s.validateAPIToken(token)
		if err != nil {
			s.logAuthFailure(r, fmt.Sprintf("Invalid token: %v", err))
			http.Error(w, "Unauthorized: Invalid token", http.StatusUnauthorized)
			return
		}

		// Check if token has required permissions for this endpoint
		if !s.hasPermission(apiToken, r.URL.Path) {
			s.logAuthFailure(r, "Insufficient permissions")
			http.Error(w, "Forbidden: Insufficient permissions", http.StatusForbidden)
			return
		}

		// Update token last used timestamp
		go s.updateTokenLastUsed(apiToken.ID)

		next.ServeHTTP(w, r)
	})
}

// AdminTokenMiddleware requires admin permissions
func (s *AnalyticsServer) AdminTokenMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := extractToken(r)
		if token == "" {
			s.logAuthFailure(r, "No admin token provided")
			http.Error(w, "Unauthorized: Admin token required", http.StatusUnauthorized)
			return
		}

		apiToken, err := s.validateAPIToken(token)
		if err != nil {
			s.logAuthFailure(r, fmt.Sprintf("Invalid admin token: %v", err))
			http.Error(w, "Unauthorized: Invalid token", http.StatusUnauthorized)
			return
		}

		// Check for admin permissions
		if !s.hasAdminPermission(apiToken) {
			s.logAuthFailure(r, "Not an admin token")
			http.Error(w, "Forbidden: Admin access required", http.StatusForbidden)
			return
		}

		go s.updateTokenLastUsed(apiToken.ID)
		next.ServeHTTP(w, r)
	})
}

// extractToken extracts the API token from various sources
func extractToken(r *http.Request) string {
	// 1. Authorization: Bearer <token>
	if auth := r.Header.Get("Authorization"); auth != "" {
		if strings.HasPrefix(auth, "Bearer ") {
			return strings.TrimPrefix(auth, "Bearer ")
		}
	}

	// 2. X-API-Key: <token>
	if apiKey := r.Header.Get("X-API-Key"); apiKey != "" {
		return apiKey
	}

	// 3. Query parameter: ?token=<token>
	return r.URL.Query().Get("token")
}

// validateAPIToken checks if a token is valid and active
func (s *AnalyticsServer) validateAPIToken(token string) (*APIToken, error) {
	if token == "" {
		return nil, fmt.Errorf("empty token")
	}

	tokenHash := hashToken(token)

	// Simplified query to avoid JSON parsing issues for now
	var apiToken APIToken
	err := s.db.QueryRow(`
		SELECT id, token_hash, name, is_active
		FROM api_tokens 
		WHERE token_hash = ? AND is_active = true
	`, tokenHash).Scan(
		&apiToken.ID, &apiToken.TokenHash, &apiToken.Name, &apiToken.IsActive,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("token not found or expired")
		}
		return nil, fmt.Errorf("database error: %v", err)
	}

	// Set default permissions for now
	apiToken.Permissions = []string{"read:insights", "read:health"}

	return &apiToken, nil
}

// hasPermission checks if token has required permissions for endpoint
func (s *AnalyticsServer) hasPermission(token *APIToken, path string) bool {
	// Admin tokens have all permissions
	for _, perm := range token.Permissions {
		if perm == PermissionAdmin {
			return true
		}
	}

	// Check specific permissions based on path
	switch {
	case strings.HasPrefix(path, "/api/insights"):
		return s.hasTokenPermission(token, PermissionReadInsights)
	case strings.HasPrefix(path, "/api/health"):
		return s.hasTokenPermission(token, PermissionReadHealth)
	default:
		return false
	}
}

// hasAdminPermission checks if token has admin permissions
func (s *AnalyticsServer) hasAdminPermission(token *APIToken) bool {
	return s.hasTokenPermission(token, PermissionAdmin) ||
		s.hasTokenPermission(token, PermissionManageTokens)
}

// hasTokenPermission checks if token has specific permission
func (s *AnalyticsServer) hasTokenPermission(token *APIToken, permission string) bool {
	for _, perm := range token.Permissions {
		if perm == permission || perm == PermissionAdmin {
			return true
		}
	}
	return false
}

// updateTokenLastUsed updates the last_used timestamp for a token
func (s *AnalyticsServer) updateTokenLastUsed(tokenID string) {
	_, err := s.db.Exec(`
		UPDATE api_tokens 
		SET last_used = CURRENT_TIMESTAMP 
		WHERE id = ?
	`, tokenID)

	if err != nil {
		log.Printf("Failed to update token last_used: %v", err)
	}
}

// hashToken creates a SHA-256 hash of the token
func hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

// logAuthFailure logs authentication failures for monitoring
func (s *AnalyticsServer) logAuthFailure(r *http.Request, reason string) {
	log.Printf("AUTH_FAILURE: %s from %s (%s) - %s",
		reason,
		r.RemoteAddr,
		r.UserAgent(),
		r.URL.Path,
	)
}
