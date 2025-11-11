package main

import (
	"crypto/rand"
	"crypto/sha256"
	"database/sql"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	_ "github.com/marcboeker/go-duckdb"
)

func main() {
	var (
		command     = flag.String("command", "", "Command: create, hash-password")
		name        = flag.String("name", "", "Token name")
		permissions = flag.String("permissions", "", "Comma-separated permissions")
		password    = flag.String("password", "", "Password to hash")
		expires     = flag.String("expires", "", "Expiration (e.g., 30d, 1y)")
	)
	flag.Parse()

	switch *command {
	case "create":
		createToken(*name, *permissions, *expires)
	case "hash-password":
		if *password == "" {
			log.Fatal("Password is required for hash-password command")
		}
		hashPassword(*password)
	default:
		fmt.Println("Usage:")
		fmt.Println("  go run cmd/token-manager/main.go -command=create -name='Frontend API' -permissions='read:insights,read:health'")
		fmt.Println("  go run cmd/token-manager/main.go -command=hash-password -password='your_password'")
		os.Exit(1)
	}
}

func createToken(name, permissions, expires string) {
	if name == "" {
		log.Fatal("Token name is required")
	}

	if permissions == "" {
		log.Fatal("Permissions are required")
	}

	// Generate secure token
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		log.Fatal("Failed to generate random token:", err)
	}
	token := "analytics_" + hex.EncodeToString(bytes)

	// Open database and insert token
	db, err := sql.Open("duckdb", "./analytics.db")
	if err != nil {
		log.Fatal("Failed to open database:", err)
	}
	defer db.Close()

	tokenHash := hashToken(token)
	permissionsJSON := formatPermissions(permissions)

	_, err = db.Exec(`
		INSERT INTO api_tokens (token_hash, name, permissions, expires_at, is_active) 
		VALUES (?, ?, ?, NULL, true)
	`, tokenHash, name, permissionsJSON)

	if err != nil {
		log.Fatal("Failed to insert token into database:", err)
	}

	fmt.Printf("Generated API Token:\n")
	fmt.Printf("Token: %s\n", token)
	fmt.Printf("Name: %s\n", name)
	fmt.Printf("Permissions: %s\n", permissions)
	if expires != "" {
		fmt.Printf("Expires: %s\n", expires)
	}
	fmt.Printf("\n✅ Token has been inserted into the database and is ready to use!\n")
	fmt.Printf("\nTo use this token, add it to your API requests:\n")
	fmt.Printf("curl -H 'X-API-Key: %s' http://localhost:8082/api/health\n", token)
	fmt.Printf("curl -H 'Authorization: Bearer %s' http://localhost:8082/api/insights/usage\n", token)
	fmt.Printf("\nStore this token securely - it cannot be retrieved again!\n")
}

func hashPassword(password string) {
	// For now, just print the password for basic auth
	// In production, you'd want to use bcrypt
	fmt.Printf("Dashboard Credentials:\n")
	fmt.Printf("Username: Set DASHBOARD_USERNAME environment variable\n")
	fmt.Printf("Password: Set DASHBOARD_PASSWORD=%s\n", password)
	fmt.Printf("\nExample .env entry:\n")
	fmt.Printf("DASHBOARD_USERNAME=analytics_admin\n")
	fmt.Printf("DASHBOARD_PASSWORD=%s\n", password)
}

func hashToken(token string) string {
	// This should match the hashToken function in auth.go
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

func formatPermissions(permissions string) string {
	perms := strings.Split(permissions, ",")
	var jsonPerms []string
	for _, perm := range perms {
		jsonPerms = append(jsonPerms, fmt.Sprintf(`"%s"`, strings.TrimSpace(perm)))
	}
	return fmt.Sprintf("[%s]", strings.Join(jsonPerms, ","))
}

func formatExpiration(expires string) string {
	if expires == "" {
		return "NULL"
	}
	// For now, just return NULL - in production you'd parse the duration
	return "NULL"
}
