# 撮合系統 - ZSH 指令版本

## 🚀 不使用 Makefile 的快速啟動方式

### 方法一：使用統一管理腳本 (推薦)

```bash
# 一鍵啟動
./run.sh setup && ./run.sh start && ./run.sh test

# 查看所有可用指令
./run.sh help
```

### 方法二：直接使用 ZSH 指令

```bash
# 一鍵啟動
chmod +x scripts/*.sh && ./scripts/setup.sh && ./scripts/start.sh && ./scripts/test.sh
```

## 📋 主要指令對照表

| 功能 | run.sh 方式 | 直接 ZSH 指令 |
|------|-------------|---------------|
| 初始化環境 | `./run.sh setup` | `chmod +x scripts/*.sh && ./scripts/setup.sh` |
| 啟動系統 | `./run.sh start` | `./scripts/start.sh` |
| 停止系統 | `./run.sh stop` | `docker-compose down` |
| 重啟系統 | `./run.sh restart` | `docker-compose down && ./scripts/start.sh` |
| 執行測試 | `./run.sh test` | `./scripts/test.sh` |
| 健康檢查 | `./run.sh health` | `./scripts/health_check.sh` |
| 查看狀態 | `./run.sh status` | `docker-compose ps` |
| 查看日誌 | `./run.sh logs` | `docker-compose logs -f` |
| 清理環境 | `./run.sh clean` | `./scripts/clean.sh` |
| 重建服務 | `./run.sh build` | `docker-compose build --no-cache` |
| 資料庫遷移 | `./run.sh migrate` | `go run cmd/migrate/main.go` |

## 🛠️ 常用組合指令

### 完全重置並啟動
```bash
# 使用 run.sh
./run.sh clean && ./run.sh setup && ./run.sh start && ./run.sh test

# 使用直接指令
./scripts/clean.sh && ./scripts/setup.sh && ./scripts/start.sh && ./scripts/test.sh
```

### 快速重啟並測試
```bash
# 使用 run.sh
./run.sh restart && ./run.sh health

# 使用直接指令
docker-compose down && ./scripts/start.sh && ./scripts/health_check.sh
```

### 重建並啟動
```bash
# 使用 run.sh
./run.sh stop && ./run.sh build && ./run.sh start

# 使用直接指令
docker-compose down && docker-compose build --no-cache && ./scripts/start.sh
```

## 🔍 除錯和監控指令

### 容器管理
```bash
# 查看容器狀態
docker ps -a
docker-compose ps

# 查看特定服務日誌
docker-compose logs -f mysql-db    # MySQL 日誌
docker-compose logs -f match-api   # API 服務日誌

# 進入容器除錯
docker-compose exec mysql-db bash
docker-compose exec match-api sh
```

### 效能監控
```bash
# 系統資源使用
docker stats

# API 健康檢查
curl http://localhost:8080/api/health

# 響應時間測試
time curl -s http://localhost:8080/api/health

# 撮合中清單
curl http://localhost:8080/api/getmatchinglist

# 失效單清單
curl http://localhost:8080/api/getrejectedlist
```

### 網路和連接埠檢查
```bash
# 檢查 Docker 網路
docker network ls
docker network inspect match_network

# 檢查連接埠佔用
lsof -i :8080  # API 服務
lsof -i :3306  # MySQL 服務

# 或使用 netstat
netstat -tulpn | grep :8080
netstat -tulpn | grep :3306
```

## 💡 ZSH 別名設定

將以下內容加入你的 `~/.zshrc` 檔案：

```bash
# 撮合系統快捷指令
alias match='./run.sh'
alias match-setup='./run.sh setup'
alias match-start='./run.sh start'
alias match-stop='./run.sh stop'
alias match-restart='./run.sh restart'
alias match-test='./run.sh test'
alias match-health='./run.sh health'
alias match-logs='./run.sh logs'
alias match-status='./run.sh status'
alias match-clean='./run.sh clean'
alias match-build='./run.sh build'

# 直接指令別名
alias match-quick='chmod +x scripts/*.sh && ./scripts/setup.sh && ./scripts/start.sh && ./scripts/test.sh'
alias match-reset='./scripts/clean.sh && ./scripts/setup.sh && ./scripts/start.sh'
```

使用方式：
```bash
# 重新載入配置
source ~/.zshrc

# 使用別名
match-start        # 啟動系統
match-test         # 執行測試
match-quick        # 快速完整啟動
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

## 🎯 效果對比

### 原 Makefile 方式
```bash
make setup && make start && make test
```

### ZSH 方式
```bash
# 方式一：使用 run.sh
./run.sh setup && ./run.sh start && ./run.sh test

# 方式二：直接指令
chmod +x scripts/*.sh && ./scripts/setup.sh && ./scripts/start.sh && ./scripts/test.sh

# 方式三：別名 (設定後)
match-quick
```

兩種方式都能達到相同效果，選擇你喜歡的方式即可！ 🚀 