package main

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/mux"
)

// CreateTokenRequest represents a request to create a new API token
type CreateTokenRequest struct {
	Name        string   `json:"name"`
	Permissions []string `json:"permissions"`
	ExpiresIn   *string  `json:"expires_in,omitempty"` // e.g., "30d", "1y", null for no expiration
}

// CreateTokenResponse represents the response when creating a token
type CreateTokenResponse struct {
	Token   string `json:"token"`
	TokenID string `json:"token_id"`
	APIToken
}

// generateSecureToken generates a cryptographically secure random token
func generateSecureToken() (string, error) {
	bytes := make([]byte, 32) // 256 bits
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return "analytics_" + hex.EncodeToString(bytes), nil
}

// parseExpiresIn converts a duration string to a time.Time
func parseExpiresIn(expiresIn string) (*time.Time, error) {
	if expiresIn == "" {
		return nil, nil // No expiration
	}

	var duration time.Duration
	var err error

	if strings.HasSuffix(expiresIn, "d") {
		days := strings.TrimSuffix(expiresIn, "d")
		var d int
		if _, err := fmt.Sscanf(days, "%d", &d); err != nil {
			return nil, fmt.Errorf("invalid days format: %s", expiresIn)
		}
		duration = time.Duration(d) * 24 * time.Hour
	} else if strings.HasSuffix(expiresIn, "y") {
		years := strings.TrimSuffix(expiresIn, "y")
		var y int
		if _, err := fmt.Sscanf(years, "%d", &y); err != nil {
			return nil, fmt.Errorf("invalid years format: %s", expiresIn)
		}
		duration = time.Duration(y) * 365 * 24 * time.Hour
	} else {
		duration, err = time.ParseDuration(expiresIn)
		if err != nil {
			return nil, fmt.Errorf("invalid duration format: %s", expiresIn)
		}
	}

	expiresAt := time.Now().Add(duration)
	return &expiresAt, nil
}

// validatePermissions checks if the provided permissions are valid
func validatePermissions(permissions []string) error {
	validPermissions := map[string]bool{
		PermissionReadInsights: true,
		PermissionReadHealth:   true,
		PermissionManageTokens: true,
		PermissionAdmin:        true,
	}

	for _, perm := range permissions {
		if !validPermissions[perm] {
			return fmt.Errorf("invalid permission: %s", perm)
		}
	}

	return nil
}

// handleCreateToken creates a new API token
func (s *AnalyticsServer) handleCreateToken(w http.ResponseWriter, r *http.Request) {
	var req CreateTokenRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Validate request
	if req.Name == "" {
		http.Error(w, "Token name is required", http.StatusBadRequest)
		return
	}

	if len(req.Permissions) == 0 {
		http.Error(w, "At least one permission is required", http.StatusBadRequest)
		return
	}

	if err := validatePermissions(req.Permissions); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// Parse expiration
	var expiresAt *time.Time
	if req.ExpiresIn != nil {
		var err error
		expiresAt, err = parseExpiresIn(*req.ExpiresIn)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}

	// Generate token
	token, err := generateSecureToken()
	if err != nil {
		http.Error(w, "Failed to generate token", http.StatusInternalServerError)
		return
	}

	tokenHash := hashToken(token)

	// Convert permissions to JSON
	permissionsJSON, err := json.Marshal(req.Permissions)
	if err != nil {
		http.Error(w, "Failed to serialize permissions", http.StatusInternalServerError)
		return
	}

	// Insert into database
	var tokenID string
	err = s.db.QueryRow(`
		INSERT INTO api_tokens (token_hash, name, permissions, expires_at, is_active)
		VALUES (?, ?, ?, ?, true)
		RETURNING id
	`, tokenHash, req.Name, string(permissionsJSON), expiresAt).Scan(&tokenID)

	if err != nil {
		http.Error(w, "Failed to create token", http.StatusInternalServerError)
		return
	}

	// Prepare response
	response := CreateTokenResponse{
		Token:   token,
		TokenID: tokenID,
		APIToken: APIToken{
			ID:          tokenID,
			Name:        req.Name,
			Permissions: req.Permissions,
			CreatedAt:   time.Now(),
			ExpiresAt:   expiresAt,
			IsActive:    true,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleListTokens lists all API tokens (without the actual token values)
func (s *AnalyticsServer) handleListTokens(w http.ResponseWriter, r *http.Request) {
	rows, err := s.db.Query(`
		SELECT id, name, permissions, created_at, last_used, expires_at, is_active
		FROM api_tokens
		ORDER BY created_at DESC
	`)
	if err != nil {
		http.Error(w, "Failed to fetch tokens", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tokens []APIToken
	for rows.Next() {
		var token APIToken
		var permissionsJSON string

		err := rows.Scan(
			&token.ID, &token.Name, &permissionsJSON,
			&token.CreatedAt, &token.LastUsed, &token.ExpiresAt, &token.IsActive,
		)
		if err != nil {
			http.Error(w, "Failed to scan token", http.StatusInternalServerError)
			return
		}

		// Parse permissions JSON
		if permissionsJSON != "" {
			if err := json.Unmarshal([]byte(permissionsJSON), &token.Permissions); err != nil {
				http.Error(w, "Failed to parse permissions", http.StatusInternalServerError)
				return
			}
		}

		tokens = append(tokens, token)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tokens)
}

// handleRevokeToken revokes (deactivates) an API token
func (s *AnalyticsServer) handleRevokeToken(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	tokenID := vars["id"]

	if tokenID == "" {
		http.Error(w, "Token ID is required", http.StatusBadRequest)
		return
	}

	result, err := s.db.Exec(`
		UPDATE api_tokens 
		SET is_active = false 
		WHERE id = ?
	`, tokenID)

	if err != nil {
		http.Error(w, "Failed to revoke token", http.StatusInternalServerError)
		return
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		http.Error(w, "Failed to verify token revocation", http.StatusInternalServerError)
		return
	}

	if rowsAffected == 0 {
		http.Error(w, "Token not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status":  "success",
		"message": "Token revoked successfully",
	})
}
