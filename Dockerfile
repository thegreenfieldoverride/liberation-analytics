# Liberation Analytics Service
FROM ubuntu:22.04 AS builder

# Install build dependencies and Go
RUN apt-get update && \
    apt-get install -y gcc g++ libc6-dev wget tar && \
    ARCH=$(dpkg --print-architecture) && \
    wget https://go.dev/dl/go1.21.6.linux-${ARCH}.tar.gz && \
    tar -C /usr/local -xzf go1.21.6.linux-${ARCH}.tar.gz && \
    rm go1.21.6.linux-${ARCH}.tar.gz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/local/go/bin:${PATH}"

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
RUN CGO_ENABLED=1 GOOS=linux go build -o liberation-analytics

# Production image (same Ubuntu version)
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y ca-certificates tzdata wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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
  CMD wget --no-verbose --tries=1 -O /dev/null http://localhost:8080/api/health || exit 1

CMD ["./liberation-analytics"]