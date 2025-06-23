# 使用官方 Golang 映像作為建置環境
FROM golang:1.19-alpine AS builder

# 設定工作目錄
WORKDIR /app

# 安裝 git 和 ca-certificates (用於 HTTPS 請求)
RUN apk add --no-cache git ca-certificates

# 複製 go mod 檔案
COPY go.mod go.sum ./

# 下載依賴
RUN go mod download

# 複製原始碼
COPY . .

# 建置應用程式
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# 驗證執行檔是否存在
RUN ls -la main

# 使用輕量級的 alpine 映像作為執行環境
FROM alpine:latest

# 安裝 ca-certificates 和 curl (用於健康檢查)
RUN apk --no-cache add ca-certificates curl

# 建立非 root 使用者
RUN addgroup -g 1001 app && adduser -D -s /bin/sh -u 1001 -G app app

WORKDIR /app

# 從建置階段複製執行檔
COPY --from=builder /app/main .
COPY --from=builder /app/config ./config

# 變更檔案擁有者
RUN chown -R app:app /app

# 切換到非 root 使用者
USER app

# 暴露連接埠
EXPOSE 8080

# 設定健康檢查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/health || exit 1

# 啟動應用程式
CMD ["/app/main"] 