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
	Master       MasterConfig `yaml:"master"`
	Slave        SlaveConfig  `yaml:"slave"`
	MaxIdleConns int          `yaml:"max_idle_conns"`
	MaxOpenConns int          `yaml:"max_open_conns"`
	MaxLifetime  int          `yaml:"max_lifetime"`
}

type MasterConfig struct {
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	Username string `yaml:"username"`
	Password string `yaml:"password"`
	Database string `yaml:"database"`
}

type SlaveConfig struct {
	Host     string `yaml:"host"`
	Port     int    `yaml:"port"`
	Username string `yaml:"username"`
	Password string `yaml:"password"`
	Database string `yaml:"database"`
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
	
	// 設定預設值 - Master
	if config.Database.Master.Host == "" {
		config.Database.Master.Host = "mysql-master"
	}
	if config.Database.Master.Port == 0 {
		config.Database.Master.Port = 3306
	}
	if config.Database.Master.Username == "" {
		config.Database.Master.Username = "root"
	}
	if config.Database.Master.Password == "" {
		config.Database.Master.Password = "root1234"
	}
	if config.Database.Master.Database == "" {
		config.Database.Master.Database = "match_system"
	}
	
	// 設定預設值 - Slave
	if config.Database.Slave.Host == "" {
		config.Database.Slave.Host = "mysql-slave"
	}
	if config.Database.Slave.Port == 0 {
		config.Database.Slave.Port = 3306
	}
	if config.Database.Slave.Username == "" {
		config.Database.Slave.Username = "root"
	}
	if config.Database.Slave.Password == "" {
		config.Database.Slave.Password = "root1234"
	}
	if config.Database.Slave.Database == "" {
		config.Database.Slave.Database = "match_system"
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
	
	// 環境變數覆蓋配置 - Master
	if host := os.Getenv("DB_MASTER_HOST"); host != "" {
		config.Database.Master.Host = host
	}
	if port := os.Getenv("DB_MASTER_PORT"); port != "" {
		if p, err := strconv.Atoi(port); err == nil {
			config.Database.Master.Port = p
		}
	}
	if user := os.Getenv("DB_MASTER_USER"); user != "" {
		config.Database.Master.Username = user
	}
	if password := os.Getenv("DB_MASTER_PASSWORD"); password != "" {
		config.Database.Master.Password = password
	}
	if database := os.Getenv("DB_MASTER_NAME"); database != "" {
		config.Database.Master.Database = database
	}
	
	// 環境變數覆蓋配置 - Slave
	if host := os.Getenv("DB_SLAVE_HOST"); host != "" {
		config.Database.Slave.Host = host
	}
	if port := os.Getenv("DB_SLAVE_PORT"); port != "" {
		if p, err := strconv.Atoi(port); err == nil {
			config.Database.Slave.Port = p
		}
	}
	if user := os.Getenv("DB_SLAVE_USER"); user != "" {
		config.Database.Slave.Username = user
	}
	if password := os.Getenv("DB_SLAVE_PASSWORD"); password != "" {
		config.Database.Slave.Password = password
	}
	if database := os.Getenv("DB_SLAVE_NAME"); database != "" {
		config.Database.Slave.Database = database
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