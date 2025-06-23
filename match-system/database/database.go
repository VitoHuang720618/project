package database

import (
	"database/sql"
	"fmt"
	"time"
	"match-system/config"
	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB

func InitDB(cfg *config.DatabaseConfig) (*sql.DB, error) {
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.Username, cfg.Password, cfg.Host, cfg.Port, cfg.Database)
	
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, err
	}
	
	// 測試連接
	if err := db.Ping(); err != nil {
		return nil, err
	}
	
	// 設置連接池
	db.SetMaxIdleConns(cfg.MaxIdleConns)
	db.SetMaxOpenConns(cfg.MaxOpenConns)
	db.SetConnMaxLifetime(time.Duration(cfg.MaxLifetime) * time.Second)
	
	return db, nil
}

// EnsureTablesExist 確保所需的表結構存在
func EnsureTablesExist() error {
	// 檢查MatchWagers表是否存在，如果不存在則創建
	matchWagersSQL := `
	CREATE TABLE IF NOT EXISTS MatchWagers (
		WID INT AUTO_INCREMENT PRIMARY KEY COMMENT '委託單 ID',
		WD_ID BIGINT NOT NULL COMMENT '出款單號',
		WD_Amount SMALLINT NOT NULL COMMENT '出款金額',
		WD_Account VARCHAR(15) NOT NULL COMMENT '出款帳戶',
		WD_Date DATETIME(3) NOT NULL COMMENT '出款單日期',
		WD_DateTime DATETIME(3) NOT NULL COMMENT '出款建立時間',
		State ENUM('Order', 'Rejected', 'Matching', 'Success', 'Cancel') NOT NULL DEFAULT 'Order' COMMENT '狀態',
		Reserve_UserID BIGINT DEFAULT NULL COMMENT '會員預約入款 ID',
		Reserve_DateTime DATETIME(3) DEFAULT NULL COMMENT '預約入款時間',
		DEP_ID BIGINT DEFAULT NULL COMMENT '入款單號',
		DEP_Amount SMALLINT DEFAULT NULL COMMENT '入款金額',
		Finish_DateTime DATETIME(3) DEFAULT NULL COMMENT '完成時間',
		INDEX idx_state (State),
		INDEX idx_wd_datetime (WD_DateTime)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='撮合系統委託單表';
	`
	
	if _, err := DB.Exec(matchWagersSQL); err != nil {
		return fmt.Errorf("failed to create MatchWagers table: %v", err)
	}
	
	// 檢查MatchLogs表是否存在，如果不存在則創建
	matchLogsSQL := `
	CREATE TABLE IF NOT EXISTS MatchLogs (
		ID INT AUTO_INCREMENT PRIMARY KEY COMMENT '日誌 ID',
		WID INT NOT NULL COMMENT '委託單 ID',
		WD_ID INT NOT NULL COMMENT '出款單號',
		State VARCHAR(50) NOT NULL COMMENT '操作狀態',
		LogData JSON COMMENT '日誌數據',
		CreatedAt DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3) COMMENT '創建時間',
		INDEX idx_wid (WID),
		INDEX idx_wd_id (WD_ID),
		INDEX idx_state (State),
		INDEX idx_created_at (CreatedAt)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='撮合系統日誌表';
	`
	
	if _, err := DB.Exec(matchLogsSQL); err != nil {
		return fmt.Errorf("failed to create MatchLogs table: %v", err)
	}
	
	return nil
} 