package database

import (
	"database/sql"
	"fmt"
	"time"
	"match-system/config"
	_ "github.com/go-sql-driver/mysql"
)

var (
	MasterDB *sql.DB
	SlaveDB  *sql.DB
	DB       *sql.DB // 向後兼容，預設指向 Master
)

func InitDB(cfg *config.DatabaseConfig) (*sql.DB, error) {
	// 初始化 Master 連線
	masterDSN := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&collation=utf8mb4_unicode_ci&parseTime=True&loc=Local",
		cfg.Master.Username, cfg.Master.Password, cfg.Master.Host, cfg.Master.Port, cfg.Master.Database)
	
	masterDB, err := sql.Open("mysql", masterDSN)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to master database: %v", err)
	}
	
	if err := masterDB.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping master database: %v", err)
	}
	
	// 設置 Master 連接池
	masterDB.SetMaxIdleConns(cfg.MaxIdleConns)
	masterDB.SetMaxOpenConns(cfg.MaxOpenConns)
	masterDB.SetConnMaxLifetime(time.Duration(cfg.MaxLifetime) * time.Second)
	
	// 初始化 Slave 連線
	slaveDSN := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&collation=utf8mb4_unicode_ci&parseTime=True&loc=Local",
		cfg.Slave.Username, cfg.Slave.Password, cfg.Slave.Host, cfg.Slave.Port, cfg.Slave.Database)
	
	slaveDB, err := sql.Open("mysql", slaveDSN)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to slave database: %v", err)
	}
	
	if err := slaveDB.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping slave database: %v", err)
	}
	
	// 設置 Slave 連接池
	slaveDB.SetMaxIdleConns(cfg.MaxIdleConns)
	slaveDB.SetMaxOpenConns(cfg.MaxOpenConns)
	slaveDB.SetConnMaxLifetime(time.Duration(cfg.MaxLifetime) * time.Second)
	
	// 設置全域變數
	MasterDB = masterDB
	SlaveDB = slaveDB
	DB = masterDB // 向後兼容，預設指向 Master
	
	return masterDB, nil
}

// GetWriteDB 取得寫入用的資料庫連線 (Master)
func GetWriteDB() *sql.DB {
	return MasterDB
}

// GetReadDB 取得讀取用的資料庫連線 (Slave)
func GetReadDB() *sql.DB {
	return SlaveDB
}

// EnsureTablesExist 確保所需的表結構存在
func EnsureTablesExist() error {
	// 設定正確的字符集
	queries := []string{
		"SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci",
		"SET CHARACTER SET utf8mb4",
		"SET character_set_connection = utf8mb4",
		"SET character_set_results = utf8mb4",
		"SET character_set_client = utf8mb4",
	}
	
	for _, query := range queries {
		if _, err := DB.Exec(query); err != nil {
			return fmt.Errorf("failed to set character set with query '%s': %v", query, err)
		}
	}
	
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