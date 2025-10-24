package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	_ "github.com/marcboeker/go-duckdb"
	"github.com/oschwald/geoip2-golang"
	"github.com/rs/cors"
)

// LiberationEvent represents a single analytics event
type LiberationEvent struct {
	App        string                 `json:"app"`
	Action     string                 `json:"action"`
	Attributes map[string]interface{} `json:"attributes"`
	Timestamp  time.Time              `json:"timestamp"`
	GeoHint    string                 `json:"geo_hint,omitempty"`
	SessionID  string                 `json:"session_id"`
}

// AnalyticsServer handles liberation analytics
type AnalyticsServer struct {
	db    *sql.DB
	geoIP *geoip2.Reader
}

func main() {
	server, err := NewAnalyticsServer()
	if err != nil {
		log.Fatal("Failed to create analytics server:", err)
	}
	defer server.Close()

	router := mux.NewRouter()

	// CORS for cross-origin requests from liberation tools
	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"}, // In production, restrict to liberation domains
		AllowedMethods: []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders: []string{"*"},
	})

	// Routes
	router.HandleFunc("/api/events", server.handleEvent).Methods("POST")
	router.HandleFunc("/api/insights/usage", server.handleUsageInsights).Methods("GET")
	router.HandleFunc("/api/insights/geographic", server.handleGeographicInsights).Methods("GET")
	router.HandleFunc("/api/insights/financial", server.handleFinancialInsights).Methods("GET")
	router.HandleFunc("/api/health", server.handleHealth).Methods("GET")

	handler := c.Handler(router)
	log.Println("🚀 Liberation Analytics Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", handler))
}

func NewAnalyticsServer() (*AnalyticsServer, error) {
	// Initialize DuckDB
	db, err := sql.Open("duckdb", "./analytics.db")
	if err != nil {
		return nil, err
	}

	// Initialize GeoIP (optional - can work without it)
	var geoIP *geoip2.Reader
	if reader, err := geoip2.Open("GeoLite2-Country.mmdb"); err == nil {
		geoIP = reader
	} else {
		log.Println("GeoIP database not found, continuing without geographic insights")
	}

	server := &AnalyticsServer{
		db:    db,
		geoIP: geoIP,
	}

	// Create tables
	if err := server.initDatabase(); err != nil {
		return nil, err
	}

	return server, nil
}

func (s *AnalyticsServer) initDatabase() error {
	query := `
	CREATE TABLE IF NOT EXISTS liberation_events (
		id INTEGER PRIMARY KEY,
		app VARCHAR(50),
		action VARCHAR(50),
		attributes JSON,
		timestamp TIMESTAMP,
		geo_hint VARCHAR(10),
		session_id VARCHAR(64),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);
	
	-- Indexes for fast analytics queries
	CREATE INDEX IF NOT EXISTS idx_app_action ON liberation_events(app, action);
	CREATE INDEX IF NOT EXISTS idx_timestamp ON liberation_events(timestamp);
	CREATE INDEX IF NOT EXISTS idx_geo_hint ON liberation_events(geo_hint);
	CREATE INDEX IF NOT EXISTS idx_session_id ON liberation_events(session_id);
	`

	_, err := s.db.Exec(query)
	return err
}

func (s *AnalyticsServer) handleEvent(w http.ResponseWriter, r *http.Request) {
	var event LiberationEvent
	if err := json.NewDecoder(r.Body).Decode(&event); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Set timestamp if not provided
	if event.Timestamp.IsZero() {
		event.Timestamp = time.Now()
	}

	// Extract geo hint from IP (privacy-first - only country code)
	if s.geoIP != nil && event.GeoHint == "" {
		if ip := s.extractIP(r); ip != nil {
			if record, err := s.geoIP.Country(ip); err == nil {
				event.GeoHint = record.Country.IsoCode
			}
		}
	}

	// Store event
	if err := s.storeEvent(event); err != nil {
		log.Printf("Failed to store event: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(map[string]string{"status": "recorded"})
}

func (s *AnalyticsServer) storeEvent(event LiberationEvent) error {
	attributesJSON, _ := json.Marshal(event.Attributes)

	query := `
	INSERT INTO liberation_events (app, action, attributes, timestamp, geo_hint, session_id)
	VALUES (?, ?, ?, ?, ?, ?)
	`

	_, err := s.db.Exec(query, event.App, event.Action, string(attributesJSON),
		event.Timestamp, event.GeoHint, event.SessionID)
	return err
}

func (s *AnalyticsServer) handleUsageInsights(w http.ResponseWriter, r *http.Request) {
	query := `
	SELECT 
		app,
		action,
		COUNT(*) as count,
		COUNT(DISTINCT session_id) as unique_sessions,
		DATE_TRUNC('hour', timestamp) as hour
	FROM liberation_events 
	WHERE timestamp >= NOW() - INTERVAL '24 hours'
	GROUP BY app, action, hour
	ORDER BY count DESC
	`

	s.executeInsightQuery(w, query)
}

func (s *AnalyticsServer) handleGeographicInsights(w http.ResponseWriter, r *http.Request) {
	query := `
	SELECT 
		geo_hint as country,
		app,
		COUNT(*) as usage_count,
		COUNT(DISTINCT session_id) as unique_users
	FROM liberation_events 
	WHERE geo_hint IS NOT NULL 
		AND timestamp >= NOW() - INTERVAL '7 days'
	GROUP BY geo_hint, app
	ORDER BY usage_count DESC
	LIMIT 50
	`

	s.executeInsightQuery(w, query)
}

func (s *AnalyticsServer) handleFinancialInsights(w http.ResponseWriter, r *http.Request) {
	query := `
	SELECT 
		app,
		JSON_EXTRACT(attributes, '$.salary_band') as salary_band,
		JSON_EXTRACT(attributes, '$.runway_months') as runway_months,
		JSON_EXTRACT(attributes, '$.real_wage_diff') as real_wage_diff,
		COUNT(*) as count
	FROM liberation_events 
	WHERE action IN ('calculate', 'complete', 'reveal')
		AND timestamp >= NOW() - INTERVAL '30 days'
		AND (
			JSON_EXTRACT(attributes, '$.salary_band') IS NOT NULL OR
			JSON_EXTRACT(attributes, '$.runway_months') IS NOT NULL OR
			JSON_EXTRACT(attributes, '$.real_wage_diff') IS NOT NULL
		)
	GROUP BY app, salary_band, runway_months, real_wage_diff
	ORDER BY count DESC
	`

	s.executeInsightQuery(w, query)
}

func (s *AnalyticsServer) executeInsightQuery(w http.ResponseWriter, query string) {
	rows, err := s.db.Query(query)
	if err != nil {
		log.Printf("Query error: %v", err)
		http.Error(w, "Query failed", http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var results []map[string]interface{}
	columns, _ := rows.Columns()

	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		for i := range values {
			valuePtrs[i] = &values[i]
		}

		rows.Scan(valuePtrs...)

		row := make(map[string]interface{})
		for i, col := range columns {
			row[col] = values[i]
		}
		results = append(results, row)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func (s *AnalyticsServer) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":    "ok",
		"service":   "liberation-analytics",
		"timestamp": time.Now(),
		"database":  "connected",
	})
}

func (s *AnalyticsServer) extractIP(r *http.Request) net.IP {
	// Handle various proxy headers
	forwarded := r.Header.Get("X-Forwarded-For")
	if forwarded != "" {
		return net.ParseIP(forwarded)
	}

	realIP := r.Header.Get("X-Real-IP")
	if realIP != "" {
		return net.ParseIP(realIP)
	}

	host, _, _ := net.SplitHostPort(r.RemoteAddr)
	return net.ParseIP(host)
}

func (s *AnalyticsServer) Close() {
	if s.db != nil {
		s.db.Close()
	}
	if s.geoIP != nil {
		s.geoIP.Close()
	}
}
