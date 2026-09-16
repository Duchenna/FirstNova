# Stage 1: Build stage
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /novapay-wallet ./cmd/server

# Stage 2: Runtime stage (Minimal & Non-root)
FROM alpine:3.19

# Create non-root group and user
RUN addgroup -S novapay && adduser -S novapay -G novapay

WORKDIR /app

# Copy compiled binary from builder
COPY --from=builder /novapay-wallet .

# Set ownership and switch to non-root user
RUN chown -R novapay:novapay /app
USER novapay:novapay

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["/app/novapay-wallet"]