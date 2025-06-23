package utils

import (
	"log"
	"time"
	"match-system/database"
	"github.com/gin-gonic/gin"
)

func PerformanceMonitor() gin.HandlerFunc {
	return func(c *gin.Context) {
		startTime := time.Now()
		
		c.Next()
		
		duration := time.Since(startTime)
		
		if duration > 500*time.Millisecond {
			log.Printf("⚠️  慢請求警告: %s %s 耗時 %v", c.Request.Method, c.Request.URL.Path, duration)
		}
		
		if duration > 1*time.Second {
			log.Printf("🚨 超慢請求警告: %s %s 耗時 %v", c.Request.Method, c.Request.URL.Path, duration)
		}
	}
}

func DatabaseConnectionMonitor() gin.HandlerFunc {
	return func(c *gin.Context) {
		if database.DB != nil {
			if err := database.DB.Ping(); err != nil {
				log.Printf("❌ 資料庫連接失敗: %v", err)
			}
		}
		
		c.Next()
	}
}

func generateRequestID() string {
	return time.Now().Format("20060102150405") + "-" + randomString(6)
}

func randomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
	}
	return string(b)
} 