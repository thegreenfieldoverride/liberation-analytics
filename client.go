package main

import (
	"bytes"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"time"
)

// LiberationAnalyticsClient provides easy integration for liberation tools
type LiberationAnalyticsClient struct {
	BaseURL   string
	SessionID string
}

// NewClient creates a new analytics client
func NewClient(baseURL string) *LiberationAnalyticsClient {
	sessionID := generateSessionID()
	return &LiberationAnalyticsClient{
		BaseURL:   baseURL,
		SessionID: sessionID,
	}
}

// Track sends an analytics event
func (c *LiberationAnalyticsClient) Track(app, action string, attributes map[string]interface{}) error {
	event := LiberationEvent{
		App:        app,
		Action:     action,
		Attributes: attributes,
		Timestamp:  time.Now(),
		SessionID:  c.SessionID,
	}

	jsonData, err := json.Marshal(event)
	if err != nil {
		return err
	}

	resp, err := http.Post(c.BaseURL+"/api/events", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	return nil
}

// TrackRunwayCalculation is a convenience method for runway calculator
func (c *LiberationAnalyticsClient) TrackRunwayCalculation(runwayMonths float64, savingsBand, expensesBand, industry string) error {
	return c.Track("runway-calculator", "calculate", map[string]interface{}{
		"runway_months": runwayMonths,
		"savings_band":  savingsBand,
		"expenses_band": expensesBand,
		"industry":      industry,
	})
}

// TrackRealWageReveal is a convenience method for real hourly wage calculator
func (c *LiberationAnalyticsClient) TrackRealWageReveal(salaryBand string, realWageDiff float64, commuteMinutes int, industry string) error {
	return c.Track("real-hourly-wage", "reveal", map[string]interface{}{
		"salary_band":     salaryBand,
		"real_wage_diff":  realWageDiff,
		"commute_minutes": commuteMinutes,
		"industry":        industry,
	})
}

// TrackCognitiveDebtAssessment is a convenience method for cognitive debt assessment
func (c *LiberationAnalyticsClient) TrackCognitiveDebtAssessment(score int, category, recommendation string) error {
	return c.Track("cognitive-debt-assessment", "complete", map[string]interface{}{
		"debt_score":       score,
		"primary_category": category,
		"recommendation":   recommendation,
	})
}

func generateSessionID() string {
	bytes := make([]byte, 16)
	rand.Read(bytes)
	return hex.EncodeToString(bytes)
}
