package config

import (
	"gopkg.in/yaml.v2"
	"os"
	"strconv"
)

type Config struct {
	Database DatabaseConfig `yaml:"database"`
	Server   ServerConfig   `yaml:"server"`
}

type DatabaseConfig struct {
	Host         string `yaml:"host"`
	Port         int    `yaml:"port"`
	Username     string `yaml:"username"`
	Password     string `yaml:"password"`
	Database     string `yaml:"database"`
	MaxIdleConns int    `yaml:"max_idle_conns"`
	MaxOpenConns int    `yaml:"max_open_conns"`
	MaxLifetime  int    `yaml:"max_lifetime"`
}

type ServerConfig struct {
	Port int `yaml:"port"`
}

func LoadConfig(configPath string) (*Config, error) {
	config := &Config{}
	
	// 嘗試從配置檔案載入預設值
	if configPath != "" {
		if data, err := os.ReadFile(configPath); err == nil {
			yaml.Unmarshal(data, config)
		}
	}
	
	// 設定預設值
	if config.Database.Host == "" {
		config.Database.Host = "localhost"
	}
	if config.Database.Port == 0 {
		config.Database.Port = 3306
	}
	if config.Database.Username == "" {
		config.Database.Username = "root"
	}
	if config.Database.Password == "" {
		config.Database.Password = "root1234"
	}
	if config.Database.Database == "" {
		config.Database.Database = "match_system"
	}
	if config.Database.MaxIdleConns == 0 {
		config.Database.MaxIdleConns = 10
	}
	if config.Database.MaxOpenConns == 0 {
		config.Database.MaxOpenConns = 100
	}
	if config.Database.MaxLifetime == 0 {
		config.Database.MaxLifetime = 300
	}
	if config.Server.Port == 0 {
		config.Server.Port = 8080
	}
	
	// 環境變數覆蓋配置
	if host := os.Getenv("DB_HOST"); host != "" {
		config.Database.Host = host
	}
	if port := os.Getenv("DB_PORT"); port != "" {
		if p, err := strconv.Atoi(port); err == nil {
			config.Database.Port = p
		}
	}
	if user := os.Getenv("DB_USER"); user != "" {
		config.Database.Username = user
	}
	if password := os.Getenv("DB_PASSWORD"); password != "" {
		config.Database.Password = password
	}
	if database := os.Getenv("DB_NAME"); database != "" {
		config.Database.Database = database
	}
	if maxOpenConns := os.Getenv("DB_MAX_OPEN_CONNS"); maxOpenConns != "" {
		if conns, err := strconv.Atoi(maxOpenConns); err == nil {
			config.Database.MaxOpenConns = conns
		}
	}
	if maxIdleConns := os.Getenv("DB_MAX_IDLE_CONNS"); maxIdleConns != "" {
		if conns, err := strconv.Atoi(maxIdleConns); err == nil {
			config.Database.MaxIdleConns = conns
		}
	}
	if maxLifetime := os.Getenv("DB_CONN_MAX_LIFETIME"); maxLifetime != "" {
		if lifetime, err := strconv.Atoi(maxLifetime); err == nil {
			config.Database.MaxLifetime = lifetime
		}
	}
	if apiPort := os.Getenv("API_PORT"); apiPort != "" {
		if port, err := strconv.Atoi(apiPort); err == nil {
			config.Server.Port = port
		}
	}
	
	return config, nil
} 