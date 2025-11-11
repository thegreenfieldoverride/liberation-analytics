# Analytics Dashboard Authentication Strategy

## Current State: NO AUTHENTICATION ⚠️

The liberation-analytics dashboard currently has no authentication or authorization. All endpoints are publicly accessible, creating security risks for production deployment.

## Production Authentication Strategy

### 1. Three-Tier Access Control System

#### **Tier 1: Public Event Collection** (Current)
- `POST /api/events` - Remains public for tool tracking
- Rate limited (already implemented)
- Anonymous data only

#### **Tier 2: API Token Authentication** (New)
- `GET /api/insights/*` - Require API tokens
- `GET /api/health` - Require basic auth
- Role-based permissions

#### **Tier 3: Dashboard Authentication** (New)
- Admin login for dashboard access
- Session-based authentication
- Multi-user support

### 2. Implementation Plan

#### Phase 1: Basic API Token System

**Go Middleware Implementation:**
```go
// middleware/auth.go
func APITokenMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        token := extractToken(r) // From Authorization header
        
        if !validateAPIToken(token) {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }
        
        next.ServeHTTP(w, r)
    })
}

func extractToken(r *http.Request) string {
    // Support multiple formats:
    // 1. Authorization: Bearer <token>
    // 2. X-API-Key: <token>
    // 3. Query param: ?token=<token>
    
    if auth := r.Header.Get("Authorization"); auth != "" {
        if strings.HasPrefix(auth, "Bearer ") {
            return strings.TrimPrefix(auth, "Bearer ")
        }
    }
    
    if apiKey := r.Header.Get("X-API-Key"); apiKey != "" {
        return apiKey
    }
    
    return r.URL.Query().Get("token")
}
```

**Database Token Management:**
```go
// models/token.go
type APIToken struct {
    ID          string    `json:"id"`
    TokenHash   string    `json:"-"`
    Name        string    `json:"name"`
    Permissions []string  `json:"permissions"`
    CreatedAt   time.Time `json:"created_at"`
    LastUsed    *time.Time `json:"last_used"`
    ExpiresAt   *time.Time `json:"expires_at"`
    IsActive    bool      `json:"is_active"`
}

func (s *AnalyticsServer) validateAPIToken(token string) (*APIToken, error) {
    tokenHash := hashToken(token)
    
    var apiToken APIToken
    err := s.db.QueryRow(`
        SELECT id, token_hash, name, permissions, created_at, last_used, expires_at, is_active
        FROM api_tokens 
        WHERE token_hash = $1 AND is_active = true 
        AND (expires_at IS NULL OR expires_at > NOW())
    `, tokenHash).Scan(
        &apiToken.ID, &apiToken.TokenHash, &apiToken.Name,
        &apiToken.Permissions, &apiToken.CreatedAt, &apiToken.LastUsed,
        &apiToken.ExpiresAt, &apiToken.IsActive,
    )
    
    if err != nil {
        return nil, err
    }
    
    // Update last used timestamp
    s.updateTokenLastUsed(apiToken.ID)
    
    return &apiToken, nil
}
```

**Route Protection:**
```go
// main.go - Updated routes
func setupRoutes(server *AnalyticsServer) *mux.Router {
    router := mux.NewRouter()
    
    // Public routes (for event collection)
    public := router.PathPrefix("/api").Subrouter()
    public.HandleFunc("/events", server.handleEvent).Methods("POST")
    
    // Protected routes (require API token)
    protected := router.PathPrefix("/api").Subrouter()
    protected.Use(APITokenMiddleware)
    protected.HandleFunc("/insights/usage", server.handleUsageInsights).Methods("GET")
    protected.HandleFunc("/insights/geographic", server.handleGeographicInsights).Methods("GET")
    protected.HandleFunc("/insights/financial", server.handleFinancialInsights).Methods("GET")
    protected.HandleFunc("/health", server.handleHealth).Methods("GET")
    
    // Admin routes (require admin token)
    admin := router.PathPrefix("/api/admin").Subrouter()
    admin.Use(AdminTokenMiddleware)
    admin.HandleFunc("/tokens", server.handleCreateToken).Methods("POST")
    admin.HandleFunc("/tokens", server.handleListTokens).Methods("GET")
    admin.HandleFunc("/tokens/{id}", server.handleRevokeToken).Methods("DELETE")
    
    return router
}
```

#### Phase 2: Dashboard Authentication

**Basic HTTP Authentication (Simple):**
```go
// middleware/dashboard_auth.go
func DashboardAuthMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        username, password, ok := r.BasicAuth()
        if !ok || !validateDashboardCredentials(username, password) {
            w.Header().Set("WWW-Authenticate", `Basic realm="Analytics Dashboard"`)
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }
        next.ServeHTTP(w, r)
    })
}

func validateDashboardCredentials(username, password string) bool {
    // Check against environment variables or database
    expectedUsername := os.Getenv("DASHBOARD_USERNAME")
    expectedPasswordHash := os.Getenv("DASHBOARD_PASSWORD_HASH")
    
    if username != expectedUsername {
        return false
    }
    
    return checkPasswordHash(password, expectedPasswordHash)
}
```

**Session-Based Authentication (Advanced):**
```go
// For multi-user dashboard with sessions
type DashboardSession struct {
    ID       string    `json:"id"`
    UserID   string    `json:"user_id"`
    Username string    `json:"username"`
    Role     string    `json:"role"`
    ExpiresAt time.Time `json:"expires_at"`
}

func SessionMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        sessionID := getSessionFromCookie(r)
        session, err := validateSession(sessionID)
        
        if err != nil || session.ExpiresAt.Before(time.Now()) {
            redirectToLogin(w, r)
            return
        }
        
        // Add user context to request
        ctx := context.WithValue(r.Context(), "user", session)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

#### Phase 3: Frontend Dashboard Auth

**Next.js Dashboard with Authentication:**
```typescript
// dashboard/src/app/login/page.tsx
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const router = useRouter()

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      })

      if (response.ok) {
        router.push('/dashboard')
      } else {
        setError('Invalid credentials')
      }
    } catch (err) {
      setError('Login failed')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="text-3xl font-bold text-center">
            Liberation Analytics
          </h2>
          <p className="text-center text-gray-600">
            Sign in to access the dashboard
          </p>
        </div>
        
        <form onSubmit={handleLogin} className="space-y-6">
          <div>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Username"
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              required
            />
          </div>
          
          <div>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Password"
              className="w-full px-3 py-2 border border-gray-300 rounded-md"
              required
            />
          </div>
          
          {error && (
            <div className="text-red-600 text-sm text-center">{error}</div>
          )}
          
          <button
            type="submit"
            className="w-full py-2 px-4 bg-liberation-600 text-white rounded-md hover:bg-liberation-700"
          >
            Sign In
          </button>
        </form>
      </div>
    </div>
  )
}
```

**Protected Dashboard Layout:**
```typescript
// dashboard/src/app/dashboard/layout.tsx
import { AuthProvider } from '@/components/AuthProvider'
import { AuthCheck } from '@/components/AuthCheck'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <AuthProvider>
      <AuthCheck>
        <div className="min-h-screen bg-gray-50">
          <nav className="bg-white shadow-sm border-b">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div className="flex justify-between h-16">
                <div className="flex items-center">
                  <h1 className="text-xl font-semibold">Analytics Dashboard</h1>
                </div>
                <div className="flex items-center space-x-4">
                  <UserMenu />
                </div>
              </div>
            </div>
          </nav>
          <main>{children}</main>
        </div>
      </AuthCheck>
    </AuthProvider>
  )
}
```

### 3. Token Management System

#### Token Types and Permissions

```go
const (
    PermissionReadInsights = "read:insights"
    PermissionReadHealth   = "read:health"
    PermissionManageTokens = "manage:tokens"
    PermissionAdmin        = "admin:all"
)

type TokenPermissions struct {
    Insights bool `json:"insights"`
    Health   bool `json:"health"`
    Admin    bool `json:"admin"`
}
```

#### API Token Creation

```bash
# CLI tool for token management
go run cmd/token-manager/main.go create \
  --name "Frontend Analytics" \
  --permissions "read:insights,read:health" \
  --expires "365d"

# Output: analytics_token_abc123def456...
```

### 4. Environment Configuration

```env
# Analytics Dashboard Authentication
DASHBOARD_USERNAME=analytics_admin
DASHBOARD_PASSWORD_HASH=$2a$10$...
DASHBOARD_SESSION_SECRET=your_session_secret_here

# API Token Security
API_TOKEN_SECRET=generate_a_random_256_bit_secret_for_jwt_signing
TOKEN_HASH_SECRET=another_random_secret_for_token_hashing

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS_PER_MINUTE=100
RATE_LIMIT_BURST=20

# CORS Security
ALLOWED_ORIGINS=https://thegreenfieldoverride.com,https://staging.thegreenfieldoverride.com
```

### 5. Production Security Checklist

#### ✅ Immediate (Pre-Production)
- [ ] Implement API token middleware
- [ ] Add basic auth to dashboard
- [ ] Restrict CORS origins
- [ ] Set up rate limiting
- [ ] Create admin token management

#### ✅ Phase 2 (Post-Launch)
- [ ] Multi-user dashboard system
- [ ] Role-based permissions
- [ ] Audit logging
- [ ] Token rotation system
- [ ] 2FA for admin access

#### ✅ Security Measures
- [ ] HTTPS only (already configured in Caddy)
- [ ] Token expiration
- [ ] IP allowlisting (optional)
- [ ] Failed login monitoring
- [ ] Session timeout

### 6. Integration with Main App

**Frontend Analytics Hook Update:**
```typescript
// apps/web/src/hooks/useAnalytics.ts
const ANALYTICS_API_TOKEN = process.env.NEXT_PUBLIC_ANALYTICS_TOKEN

export function useAnalytics() {
  const trackEvent = async (event: AnalyticsEvent) => {
    try {
      await fetch('/api/analytics/events', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': ANALYTICS_API_TOKEN, // Add API token
        },
        body: JSON.stringify(event),
      })
    } catch (error) {
      // Silent fail - analytics should never break UX
      console.warn('Analytics tracking failed:', error)
    }
  }

  return { trackEvent }
}
```

### 7. Monitoring and Alerts

```go
// Add authentication failure monitoring
func (s *AnalyticsServer) logAuthFailure(r *http.Request, reason string) {
    log.Printf("AUTH_FAILURE: %s from %s - %s", 
        reason, 
        r.RemoteAddr, 
        r.UserAgent(),
    )
    
    // Could integrate with monitoring system
    // metrics.IncrementCounter("auth_failures")
}
```

## Summary

This three-tier authentication system provides:

1. **Public event collection** (maintains privacy-first approach)
2. **Protected analytics insights** (API token required)
3. **Secure dashboard access** (admin authentication)

The implementation can be done incrementally, starting with basic API tokens and evolving to a full multi-user system as needed.