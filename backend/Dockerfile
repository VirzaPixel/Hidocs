FROM golang:1.26-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o hidocs-backend ./cmd/api

FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

COPY --from=builder /app/hidocs-backend .
COPY --from=builder /app/.env.example .env

EXPOSE 8080

CMD ["./hidocs-backend"]
