package main

import (
	"fmt"
	"log"
	"os"
	"match-system/config"
	"match-system/database"
	"match-system/routes"
	"match-system/utils"
	"github.com/gin-gonic/gin"
)

func main() {
	// 載入配置，支援環境變數覆蓋
	cfg, err := config.LoadConfig("config/config.yaml")
	if err != nil {
		log.Fatal("Failed to load config:", err)
	}
	
	log.Printf("Connecting to database: %s:%d/%s", cfg.Database.Host, cfg.Database.Port, cfg.Database.Database)
	
	// 初始化資料庫連接
	db, err := database.InitDB(&cfg.Database)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	database.DB = db
	
	log.Println("Database connected successfully")
	
	// 執行數據庫結構檢查/創建
	if err := database.EnsureTablesExist(); err != nil {
		log.Fatal("Failed to ensure tables exist:", err)
	}
	
	log.Println("Database migration completed")
	
	// 設定 Gin 模式
	if ginMode := os.Getenv("GIN_MODE"); ginMode != "" {
		gin.SetMode(ginMode)
	}
	
	// 建立 Gin 路由器
	r := gin.Default()
	
	// 中間件
	r.Use(gin.Logger())
	r.Use(gin.Recovery())
	r.Use(utils.PerformanceMonitor())
	r.Use(utils.DatabaseConnectionMonitor())
	
	// 健康檢查端點
	r.GET("/api/health", func(c *gin.Context) {
		// 檢查資料庫連接
		if database.DB != nil {
			if err := database.DB.Ping(); err == nil {
				c.JSON(200, gin.H{
					"status":   "OK",
					"database": "connected",
					"service":  "match-system",
					"version":  "1.0.0",
				})
				return
			}
		}
		
		c.JSON(503, gin.H{
			"status":   "ERROR",
			"database": "disconnected",
			"service":  "match-system",
			"version":  "1.0.0",
		})
	})
	
	// 設定業務路由
	routes.SetupRoutes(r)
	
	log.Printf("🚀 Match System starting on port %d", cfg.Server.Port)
	log.Printf("🔗 Health check: http://localhost:%d/api/health", cfg.Server.Port)
	
	// 啟動服務器
	if err := r.Run(fmt.Sprintf(":%d", cfg.Server.Port)); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
