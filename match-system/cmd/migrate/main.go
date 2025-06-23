package main

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

type Migration struct {
	ID       int
	Filename string
	Path     string
}

func main() {
	log.Println("🚀 開始執行資料庫遷移...")

	db, err := connectDB()
	if err != nil {
		log.Fatalf("❌ 連接資料庫失敗: %v", err)
	}
	defer db.Close()

	if err := createMigrationTable(db); err != nil {
		log.Fatalf("❌ 建立遷移表失敗: %v", err)
	}

	migrations, err := loadMigrations()
	if err != nil {
		log.Fatalf("❌ 載入遷移檔案失敗: %v", err)
	}

	for _, migration := range migrations {
		if err := runMigration(db, migration); err != nil {
			log.Fatalf("❌ 執行遷移失敗 [%s]: %v", migration.Filename, err)
		}
	}

	log.Println("✅ 所有遷移執行完成！")
}

func connectDB() (*sql.DB, error) {
	host := getEnv("DB_HOST", "localhost")
	port := getEnv("DB_PORT", "3306")
	user := getEnv("DB_USER", "root")
	password := getEnv("DB_PASSWORD", "root1234")
	dbname := getEnv("DB_NAME", "match_system")

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		user, password, host, port, dbname)

	log.Printf("📊 連接資料庫: %s:%s/%s", host, port, dbname)

	for i := 0; i < 30; i++ {
		db, err := sql.Open("mysql", dsn)
		if err != nil {
			return nil, err
		}

		if err := db.Ping(); err != nil {
			log.Printf("⏳ 等待資料庫啟動... (%d/30)", i+1)
			time.Sleep(2 * time.Second)
			db.Close()
			continue
		}

		return db, nil
	}

	return nil, fmt.Errorf("無法連接到資料庫")
}

func createMigrationTable(db *sql.DB) error {
	query := `
	CREATE TABLE IF NOT EXISTS migrations (
		id INT NOT NULL,
		filename VARCHAR(255) NOT NULL,
		executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (id)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;`

	_, err := db.Exec(query)
	return err
}

func loadMigrations() ([]Migration, error) {
	var migrations []Migration

	migrationPaths := []string{
		"database/create_table.sql",
		"database/migrations",
		"database/seeds",
	}

	for _, path := range migrationPaths {
		if strings.HasSuffix(path, ".sql") {
			migrations = append(migrations, Migration{
				ID:       0,
				Filename: filepath.Base(path),
				Path:     path,
			})
		} else {
			files, err := loadFromDirectory(path)
			if err != nil {
				continue
			}
			migrations = append(migrations, files...)
		}
	}

	sort.Slice(migrations, func(i, j int) bool {
		return migrations[i].ID < migrations[j].ID || 
			   (migrations[i].ID == migrations[j].ID && migrations[i].Filename < migrations[j].Filename)
	})

	return migrations, nil
}

func loadFromDirectory(dir string) ([]Migration, error) {
	var migrations []Migration

	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return migrations, nil
	}

	files, err := ioutil.ReadDir(dir)
	if err != nil {
		return nil, err
	}

	for _, file := range files {
		if !strings.HasSuffix(file.Name(), ".sql") {
			continue
		}

		id := extractMigrationID(file.Name())
		migrations = append(migrations, Migration{
			ID:       id,
			Filename: file.Name(),
			Path:     filepath.Join(dir, file.Name()),
		})
	}

	return migrations, nil
}

func extractMigrationID(filename string) int {
	parts := strings.Split(filename, "_")
	if len(parts) > 0 {
		if id, err := strconv.Atoi(parts[0]); err == nil {
			return id
		}
	}
	return 999
}

func runMigration(db *sql.DB, migration Migration) error {
	var count int
	err := db.QueryRow("SELECT COUNT(*) FROM migrations WHERE id = ? AND filename = ?", 
		migration.ID, migration.Filename).Scan(&count)
	if err != nil {
		return err
	}

	if count > 0 {
		log.Printf("⏭️  跳過已執行的遷移: %s", migration.Filename)
		return nil
	}

	log.Printf("🔄 執行遷移: %s", migration.Filename)

	content, err := ioutil.ReadFile(migration.Path)
	if err != nil {
		return err
	}

	statements := strings.Split(string(content), ";")
	for _, stmt := range statements {
		stmt = strings.TrimSpace(stmt)
		if stmt == "" {
			continue
		}

		if _, err := db.Exec(stmt); err != nil {
			// 檢查是否為可忽略的錯誤
			if isIgnorableError(err) {
				log.Printf("⚠️  忽略已知錯誤: %v", err)
				continue
			}
			return fmt.Errorf("執行 SQL 失敗: %s, 錯誤: %v", stmt, err)
		}
	}

	_, err = db.Exec("INSERT IGNORE INTO migrations (id, filename) VALUES (?, ?)", 
		migration.ID, migration.Filename)
	if err != nil {
		return err
	}

	log.Printf("✅ 遷移完成: %s", migration.Filename)
	return nil
}

func isIgnorableError(err error) bool {
	errStr := err.Error()
	
	// MySQL 可忽略的錯誤類型
	ignorableErrors := []string{
		"Error 1050", // Table already exists
		"Error 1061", // Duplicate key name
		"Error 1062", // Duplicate entry
		"Error 1091", // Can't DROP, check that column/key exists
		"Error 1146", // Table doesn't exist (for DROP operations)
	}
	
	for _, ignorable := range ignorableErrors {
		if strings.Contains(errStr, ignorable) {
			return true
		}
	}
	
	return false
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
} 