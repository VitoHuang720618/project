# 撮合系統 - Master-Slave 讀寫分離架構

## 🚀 快速啟動方式

### 方法一：互動式選單模式 (推薦新用戶)

```bash
# 直接執行進入選單
./run.sh

# 選單將顯示：
# ╔════════════════════════════════════════════╗
# ║          🚀 撮合系統管理工具 🚀           ║
# ╚════════════════════════════════════════════╝
# 
# 🚀 快速部署
#   1) 一鍵完整部署 (推薦新用戶)
#   2) 快速啟動 (假設已建置)
# 
# 🔧 服務管理
#   3) 初始化專案環境
#   4) 啟動所有服務
#   ...等 20 個選項
```

### 方法二：指令模式 (推薦熟練用戶)

```bash
# 一鍵完整部署
./run.sh deploy

# 快速啟動 (Master-Slave 架構)
./run.sh start && ./run.sh replication

# 查看所有可用指令
./run.sh help
```

### 方法三：直接使用 ZSH 指令

```bash
# 一鍵啟動
chmod +x scripts/*.sh && ./scripts/setup.sh && ./scripts/start.sh && ./scripts/setup_replication.sh
```

## 📋 Master-Slave 架構功能對照表

| 功能 | 選單編號 | run.sh 指令 | 直接 ZSH 指令 |
|------|----------|-------------|---------------|
| **快速部署** |
| 一鍵完整部署 | `1` | `./run.sh deploy` | `./scripts/clean.sh && ./scripts/setup.sh && ./scripts/start.sh && ./scripts/setup_replication.sh` |
| 快速啟動 | `2` | `./run.sh start && ./run.sh replication` | `./scripts/start.sh && ./scripts/setup_replication.sh` |
| **服務管理** |
| 初始化環境 | `3` | `./run.sh setup` | `chmod +x scripts/*.sh && ./scripts/setup.sh` |
| 啟動系統 | `4` | `./run.sh start` | `./scripts/start.sh` |
| 停止系統 | `5` | `./run.sh stop` | `docker-compose down` |
| 重啟系統 | `6` | `./run.sh restart` | `docker-compose down && ./scripts/start.sh` |
| 查看狀態 | `7` | `./run.sh status` | `docker-compose ps` |
| 查看日誌 | `8` | `./run.sh logs` | `docker-compose logs -f` |
| **資料庫管理** |
| 資料庫遷移 | `9` | `./run.sh migrate` | `go run cmd/migrate/main.go` |
| 載入測試資料 | `10` | `./run.sh seed` | `cat database/seeds/*.sql \| mysql...` |
| 設置複製 | `11` | `./run.sh replication` | `./scripts/setup_replication.sh` |
| 檢查資料庫狀態 | `12` | `./run.sh dbstatus` | `docker-compose exec mysql-master/slave...` |
| 開啟 phpMyAdmin | `13` | `./run.sh db` | `open http://localhost:8081` |
| **測試與監控** |
| 健康檢查 | `14` | `./run.sh health` | `./scripts/health_check.sh` |
| 執行測試 | `15` | `./run.sh test` | `./scripts/test.sh` |
| **開發工具** |
| 開發模式 | `16` | `./run.sh dev` | `docker-compose up` |
| 重建服務 | `17` | `./run.sh build` | `docker-compose build --no-cache` |
| 清理環境 | `18` | `./run.sh clean` | `./scripts/clean.sh` |
| **清理** |
| 移除資料庫 | `19` | `./run.sh remove-db` | `docker-compose down -v && docker system prune` |

## 🛠️ Master-Slave 架構常用組合指令

### 新手推薦：使用選單模式
```bash
# 進入選單模式
./run.sh

# - 選擇 1：一鍵完整部署 (包含 Master-Slave 設置)
# - 選擇 12：檢查資料庫狀態
# - 選擇 13：開啟 phpMyAdmin 管理介面
```

### 完全重置並啟動 Master-Slave
```bash
# 使用 run.sh (推薦)
./run.sh deploy

# 等同於：
./run.sh clean && ./run.sh setup && ./run.sh start && ./run.sh replication

# 使用直接指令
./scripts/clean.sh && ./scripts/setup.sh && ./scripts/start.sh && ./scripts/setup_replication.sh
```

### 快速重啟並檢查複製狀態
```bash
# 使用 run.sh
./run.sh restart && ./run.sh replication && ./run.sh dbstatus

# 使用直接指令
docker-compose down && ./scripts/start.sh && ./scripts/setup_replication.sh
```

### 重建並啟動 Master-Slave
```bash
# 使用 run.sh
./run.sh stop && ./run.sh build && ./run.sh start && ./run.sh replication

# 使用直接指令
docker-compose down && docker-compose build --no-cache && ./scripts/start.sh && ./scripts/setup_replication.sh
```

## 🔍 Master-Slave 架構除錯和監控

### 容器管理
```bash
# 查看容器狀態
docker ps -a
docker-compose ps

# 查看特定服務日誌
docker-compose logs -f mysql-master    # MySQL Master 日誌
docker-compose logs -f mysql-slave     # MySQL Slave 日誌
docker-compose logs -f match-api       # API 服務日誌
docker-compose logs -f phpmyadmin      # phpMyAdmin 日誌

# 進入容器除錯
docker-compose exec mysql-master bash
docker-compose exec mysql-slave bash
docker-compose exec match-api sh
```

### Master-Slave 狀態監控
```bash
# 使用 run.sh 檢查 (推薦)
./run.sh dbstatus

# 或選單模式選擇 12

# 手動檢查複製狀態
docker-compose exec mysql-slave mysql -u root -proot1234 -e "SHOW SLAVE STATUS\G"

# 檢查 Master 狀態
docker-compose exec mysql-master mysql -u root -proot1234 -e "SHOW MASTER STATUS\G"

# 檢查資料同步
docker-compose exec mysql-master mysql -u root -proot1234 -e "SELECT COUNT(*) FROM match_system.MatchWagers;"
docker-compose exec mysql-slave mysql -u root -proot1234 -e "SELECT COUNT(*) FROM match_system.MatchWagers;"
```

### API 效能監控
```bash
# 系統資源使用
docker stats

# API 健康檢查
curl http://localhost:8080/api/health

# 資料庫狀態檢查
curl http://localhost:8080/api/dbstatus

# 響應時間測試
time curl -s http://localhost:8080/api/health

# 撮合中清單 (從 Slave 讀取)
curl -X POST -H "Content-Type: application/json" -d '{}' http://localhost:8080/api/getmatchinglist

# 建立新訂單 (寫入 Master)
curl -X POST -H "Content-Type: application/json" -d '{
  "wd_amount": 1000,
  "wd_account": "test123"
}' http://localhost:8080/api/order
```

### 網路和連接埠檢查
```bash
# 檢查 Docker 網路
docker network ls
docker network inspect match-system_match_network

# 檢查連接埠佔用
lsof -i :8080  # API 服務
lsof -i :3306  # MySQL Master
lsof -i :3307  # MySQL Slave
lsof -i :8081  # phpMyAdmin

# 或使用 netstat
netstat -tulpn | grep :8080
netstat -tulpn | grep :3306
netstat -tulpn | grep :3307
netstat -tulpn | grep :8081
```

## 💡 ZSH 別名設定

將以下內容加入你的 `~/.zshrc` 檔案：

```bash
# 撮合系統 Master-Slave 架構快捷指令
alias match='./run.sh'                    # 進入選單模式
alias match-menu='./run.sh'               # 進入選單模式
alias match-deploy='./run.sh deploy'      # 一鍵完整部署
alias match-setup='./run.sh setup'        # 初始化環境
alias match-start='./run.sh start'        # 啟動服務
alias match-stop='./run.sh stop'          # 停止服務
alias match-restart='./run.sh restart'    # 重啟服務
alias match-replication='./run.sh replication'  # 設置複製
alias match-dbstatus='./run.sh dbstatus'  # 檢查資料庫狀態
alias match-health='./run.sh health'      # 健康檢查
alias match-test='./run.sh test'          # 執行測試
alias match-logs='./run.sh logs'          # 查看日誌
alias match-status='./run.sh status'      # 查看狀態
alias match-clean='./run.sh clean'        # 清理環境
alias match-build='./run.sh build'        # 重建服務
alias match-db='./run.sh db'              # 開啟 phpMyAdmin

# Master-Slave 組合指令別名
alias match-quick='./run.sh start && ./run.sh replication'  # 快速啟動含複製
alias match-reset='./run.sh clean && ./run.sh deploy'       # 完全重置
alias match-check='./run.sh dbstatus && ./run.sh health'    # 完整檢查

# 直接指令別名 (進階用戶)
alias match-master='docker-compose exec mysql-master mysql -u root -proot1234 match_system'
alias match-slave='docker-compose exec mysql-slave mysql -u root -proot1234 match_system'
```

使用方式：
```bash
# 重新載入配置
source ~/.zshrc

# 使用別名
match              # 進入選單模式
match-deploy       # 一鍵完整部署
match-quick        # 快速啟動 Master-Slave
match-dbstatus     # 檢查資料庫狀態
match-check        # 完整系統檢查
```

## 🚨 緊急處理指令

### 完全重置系統
```bash
# 強制停止所有容器並清理
docker-compose down -v
docker system prune -a -f
./run.sh setup
./run.sh start
```

### 強制清理 Docker 資源
```bash
# 停止所有容器
docker stop $(docker ps -q) 2>/dev/null

# 移除所有容器
docker rm $(docker ps -aq) 2>/dev/null

# 清理未使用的映像
docker rmi $(docker images -q) 2>/dev/null
```

### 檢查和修復權限
```bash
# 重新設定腳本權限
find scripts/ -name "*.sh" -exec chmod +x {} \;
chmod +x run.sh
```

## 📊 監控腳本

### 持續監控服務狀態
```bash
# 每 5 秒檢查一次服務狀態
watch -n 5 'docker-compose ps && echo "---" && curl -s http://localhost:8080/api/health'
```

### 自動重啟監控
```bash
# 建立監控腳本
cat > monitor.sh << 'EOF'
#!/bin/zsh
while true; do
    if ! curl -s http://localhost:8080/api/health > /dev/null; then
        echo "⚠️  API 服務異常，正在重啟..."
        ./run.sh restart
    fi
    sleep 30
done
EOF

chmod +x monitor.sh
./monitor.sh
```

## 🎯 Master-Slave 架構使用方式對比

### 新手推薦：選단模式
```bash
./run.sh
# 選擇 1 → 一鍵完整部署 (包含 Master-Slave 設置)
# 選擇 12 → 檢查資料庫狀態
# 選擇 13 → 開啟 phpMyAdmin 管理介面
```

### 熟練用戶：指令模式
```bash
# 一鍵完整部署
./run.sh deploy

# 快速啟動 Master-Slave
./run.sh start && ./run.sh replication

# 檢查資料庫狀態
./run.sh dbstatus
```

### 進階用戶：直接指令
```bash
# 完整部署
chmod +x scripts/*.sh && ./scripts/clean.sh && ./scripts/setup.sh && ./scripts/start.sh && ./scripts/setup_replication.sh

# 快速啟動
./scripts/start.sh && ./scripts/setup_replication.sh
```

### 效率專家：別名 (設定後)
```bash
match              # 進入選單模式
match-deploy       # 一鍵完整部署
match-quick        # 快速啟動 Master-Slave
match-dbstatus     # 檢查資料庫狀態
match-check        # 完整系統檢查
```

## 🏆 系統架構特色

- **📊 Master-Slave 讀寫分離**：寫入使用 Master，讀取使用 Slave
- **🔄 自動複製同步**：資料自動從 Master 同步到 Slave  
- **🖥️ 互動式選單**：20 個選項，數字選擇更直觀
- **⚡ 一鍵部署**：自動化部署包含複製設置
- **📈 即時監控**：資料庫狀態、複製狀態即時查看
- **🌐 Web 管理**：phpMyAdmin 固定端口 8081 管理資料庫
- **🛡️ 企業級架構**：提升效能和可靠性

選擇最適合你的方式開始使用！ 🚀 