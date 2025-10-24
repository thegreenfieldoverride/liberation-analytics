-- Liberation Analytics PostgreSQL Initialization
-- Transactional data for sessions, tokens, and real-time events

-- Sessions table for user session tracking
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(64) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT,
    geo_hint VARCHAR(10)
);

-- API tokens table for service authentication
CREATE TABLE IF NOT EXISTS api_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_hash VARCHAR(128) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    permissions JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_used TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Real-time events table (before ETL to DuckDB)
CREATE TABLE IF NOT EXISTS events_staging (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    app VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    attributes JSONB,
    timestamp TIMESTAMP NOT NULL,
    geo_hint VARCHAR(10),
    session_id VARCHAR(64),
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sessions_session_id ON sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_sessions_last_active ON sessions(last_active);

CREATE INDEX IF NOT EXISTS idx_api_tokens_hash ON api_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_api_tokens_active ON api_tokens(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_events_staging_app_action ON events_staging(app, action);
CREATE INDEX IF NOT EXISTS idx_events_staging_timestamp ON events_staging(timestamp);
CREATE INDEX IF NOT EXISTS idx_events_staging_session ON events_staging(session_id);
CREATE INDEX IF NOT EXISTS idx_events_staging_processed ON events_staging(processed_at);

-- Create a user for the analytics service
-- Password will be set via environment variable
-- ALTER USER liberation PASSWORD 'set_via_env';

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO liberation;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO liberation;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO liberation;