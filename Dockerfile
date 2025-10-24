# Liberation Analytics Service - Use Debian base for glibc compatibility
FROM golang:bullseye AS builder

# Install build dependencies for CGO and DuckDB
RUN apt-get update && apt-get install -y \
    gcc g++ \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
RUN ls -la && go version && CGO_ENABLED=1 GOOS=linux go build -v -o liberation-analytics

# Production image - Use Debian slim for glibc compatibility
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    tzdata \
    wget \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# Create app directory
WORKDIR /app

# Copy binary
COPY --from=builder /app/liberation-analytics .

# Create data directory for DuckDB
RUN mkdir -p /app/data

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

CMD ["./liberation-analytics"]