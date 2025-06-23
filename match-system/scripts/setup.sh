#!/bin/bash
set -e

echo "🔧 撮合系統初始化開始..."

# 檢查必要工具
check_dependencies() {
    echo "📋 檢查系統依賴..."
    
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安裝，請先安裝 Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "❌ Docker Compose 未安裝，請先安裝 Docker Compose"
        exit 1
    fi
    
    if ! command -v go &> /dev/null; then
        echo "❌ Go 未安裝，請先安裝 Go 1.19+"
        exit 1
    fi
    
    echo "✅ 所有依賴檢查通過"
}

# 建立必要目錄
create_directories() {
    echo "📁 建立必要目錄..."
    
    mkdir -p scripts
    mkdir -p database/seeds
    mkdir -p tests/integration
    mkdir -p cmd/migrate
    mkdir -p logs
    
    echo "✅ 目錄建立完成"
}

# 複製環境變數範本
setup_env() {
    echo "⚙️  設定環境變數..."
    
    if [ ! -f .env ]; then
        cat > .env << 'EOF'
# MySQL 配置
MYSQL_ROOT_PASSWORD=root1234
MYSQL_DATABASE=match_system
MYSQL_USER=match_user
MYSQL_PASSWORD=match_pass
MYSQL_PORT=3306

# API 配置
API_PORT=8080
GIN_MODE=debug

# 資料庫連線配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=match_user
DB_PASSWORD=match_pass
DB_NAME=match_system

# 連接池配置
DB_MAX_OPEN_CONNS=100
DB_MAX_IDLE_CONNS=10
DB_CONN_MAX_LIFETIME=300
EOF
        echo "✅ .env 檔案已建立"
    else
        echo "⏭️  .env 檔案已存在，跳過"
    fi
}

# 下載 Go 依賴
install_go_deps() {
    echo "📦 下載 Go 依賴..."
    
    go mod tidy
    go mod download
    
    echo "✅ Go 依賴下載完成"
}

# 建立 Docker 網路
setup_docker_network() {
    echo "🌐 設定 Docker 網路..."
    
    if ! docker network ls | grep -q match_network; then
        docker network create match_network
        echo "✅ Docker 網路建立完成"
    else
        echo "⏭️  Docker 網路已存在，跳過"
    fi
}

# 拉取必要的 Docker 映像
pull_docker_images() {
    echo "🐳 拉取 Docker 映像..."
    
    docker pull mysql:8.0
    docker pull golang:1.19-alpine
    docker pull alpine:latest
    
    echo "✅ Docker 映像拉取完成"
}

# 設定腳本權限
set_permissions() {
    echo "🔒 設定腳本權限..."
    
    chmod +x scripts/*.sh
    
    echo "✅ 權限設定完成"
}

# 驗證安裝
verify_setup() {
    echo "🔍 驗證安裝..."
    
    # 檢查 Go 模組
    if go mod verify; then
        echo "✅ Go 模組驗證通過"
    else
        echo "❌ Go 模組驗證失敗"
        exit 1
    fi
    
    # 檢查 Docker
    if docker --version > /dev/null; then
        echo "✅ Docker 正常運行"
    else
        echo "❌ Docker 檢查失敗"
        exit 1
    fi
    
    echo "✅ 安裝驗證完成"
}

# 顯示下一步指示
show_next_steps() {
    echo ""
    echo "🎉 撮合系統初始化完成！"
    echo ""
    echo "📝 下一步操作:"
    echo "  1. 啟動系統:     ./run.sh start"
    echo "  2. 執行遷移:     ./run.sh migrate"
    echo "  3. 查看狀態:     ./run.sh status"
    echo "  4. 開啟資料庫:   ./run.sh db"
    echo "  5. 執行測試:     ./run.sh test"
    echo "  6. 停止系統:     ./run.sh stop"
    echo ""
    echo "🔗 API 地址: http://localhost:8080"
    echo "🗄️  MySQL 地址: localhost:3306"
    echo "🌐 Adminer 地址: http://localhost:8081"
    echo ""
    echo "🚀 快速啟動: ./run.sh start && ./run.sh migrate"
    echo ""
}

# 主要執行流程
main() {
    check_dependencies
    create_directories
    setup_env
    install_go_deps
    setup_docker_network
    pull_docker_images
    set_permissions
    verify_setup
    show_next_steps
}

# 捕捉錯誤並清理
trap 'echo "❌ 初始化過程中發生錯誤，請檢查上方錯誤訊息"; exit 1' ERR

# 執行主要流程
main "$@" 