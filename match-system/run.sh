#!/bin/zsh

# 撮合系統管理腳本
# 使用方式: ./run.sh [指令]

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 顯示幫助
show_help() {
    echo "${BLUE}🚀 撮合系統管理工具${NC}"
    echo ""
    echo "使用方式: ./run.sh [指令]"
    echo ""
    echo "可用指令:"
    echo "  setup     - 初始化專案環境"
    echo "  start     - 啟動所有服務"
    echo "  stop      - 停止所有服務"
    echo "  restart   - 重啟所有服務"
    echo "  test      - 執行完整測試"
    echo "  health    - 檢查服務健康狀態"
    echo "  status    - 查看服務狀態"
    echo "  logs      - 查看服務日誌"
    echo "  clean     - 清理環境和資料"
    echo "  build     - 重新建置服務"
    echo "  migrate   - 執行資料庫遷移"
    echo "  seed      - 載入測試資料"
    echo "  deploy    - 一鍵完整部署 (clean + setup + start + migrate)"
    echo "  dev       - 開發模式啟動"
    echo "  db        - 開啟 Adminer 資料庫管理 (http://localhost:8081)"
    echo "  remove-db - 移除 Adminer 和 MySQL 服務及資料"
    echo "  help      - 顯示此幫助訊息"
    echo ""
    echo "快速啟動: ./run.sh setup && ./run.sh start && ./run.sh test"
    echo ""
}

# 執行指令
case "${1:-help}" in
    "setup")
        echo "${BLUE}🔧 初始化專案環境...${NC}"
        chmod +x scripts/*.sh
        ./scripts/setup.sh
        ;;
    "start")
        echo "${BLUE}🚀 啟動撮合系統...${NC}"
        ./scripts/start.sh
        ;;
    "stop")
        echo "${BLUE}🛑 停止所有服務...${NC}"
        docker-compose down
        ;;
    "restart")
        echo "${BLUE}🔄 重啟撮合系統...${NC}"
        docker-compose down
        ./scripts/start.sh
        ;;
    "test")
        echo "${BLUE}🧪 執行完整測試...${NC}"
        ./scripts/test.sh
        ;;
    "health")
        echo "${BLUE}🔍 檢查服務健康狀態...${NC}"
        ./scripts/health_check.sh
        ;;
    "status")
        echo "${BLUE}📊 服務狀態:${NC}"
        docker-compose ps
        ;;
    "logs")
        echo "${BLUE}📄 查看服務日誌...${NC}"
        docker-compose logs -f
        ;;
    "clean")
        echo "${BLUE}🧹 清理環境...${NC}"
        ./scripts/clean.sh
        ;;
    "build")
        echo "${BLUE}🔨 重新建置服務...${NC}"
        docker-compose build --no-cache
        ;;
    "migrate")
        echo "${BLUE}📊 執行資料庫遷移...${NC}"
        
        # 檢查 MySQL 是否運行
        if ! docker-compose ps mysql-db | grep -q "Up"; then
            echo "${RED}❌ MySQL 服務未運行，請先執行 ./run.sh start${NC}"
            exit 1
        fi
        
        # 等待 MySQL 就緒
        echo "${YELLOW}⏳ 等待 MySQL 服務就緒...${NC}"
        for i in {1..30}; do
            if docker-compose exec -T mysql-db mysqladmin ping -h localhost -u root -proot1234 > /dev/null 2>&1; then
                echo "${GREEN}✅ MySQL 服務就緒${NC}"
                break
            fi
            
            if [ $i -eq 30 ]; then
                echo "${RED}❌ MySQL 服務連接超時${NC}"
                exit 1
            fi
            
            echo "⏳ 等待 MySQL 就緒... ($i/30)"
            sleep 2
        done
        
        # 執行遷移
        echo "${BLUE}🔄 正在執行資料庫遷移...${NC}"
        if go run cmd/migrate/main.go; then
            echo "${GREEN}✅ 資料庫遷移完成${NC}"
        else
            echo "${RED}❌ 資料庫遷移失敗${NC}"
            exit 1
        fi
        ;;
    "seed")
        echo "${BLUE}🌱 載入測試資料...${NC}"
        
        # 檢查 MySQL 是否運行
        if ! docker-compose ps mysql-db | grep -q "Up"; then
            echo "${RED}❌ MySQL 服務未運行，請先執行 ./run.sh start${NC}"
            exit 1
        fi
        
        # 等待 MySQL 就緒
        echo "${YELLOW}⏳ 等待 MySQL 服務就緒...${NC}"
        for i in {1..30}; do
            if docker-compose exec -T mysql-db mysqladmin ping -h localhost -u root -proot1234 > /dev/null 2>&1; then
                echo "${GREEN}✅ MySQL 服務就緒${NC}"
                break
            fi
            
            if [ $i -eq 30 ]; then
                echo "${RED}❌ MySQL 服務連接超時${NC}"
                exit 1
            fi
            
            echo "⏳ 等待 MySQL 就緒... ($i/30)"
            sleep 2
        done
        
        # 載入測試資料
        echo "${BLUE}🔄 正在載入測試資料...${NC}"
        
        echo "📊 載入 MatchWagers 測試資料..."
        if cat database/seeds/001_test_data.sql | docker-compose exec -T mysql-db mysql -u root -proot1234 match_system; then
            echo "${GREEN}✅ MatchWagers 測試資料載入完成${NC}"
        else
            echo "${YELLOW}⚠️  MatchWagers 測試資料可能已存在${NC}"
        fi
        
        echo "📊 載入 MatchLogs 測試資料..."
        if cat database/seeds/002_logs_test_data.sql | docker-compose exec -T mysql-db mysql -u root -proot1234 match_system; then
            echo "${GREEN}✅ MatchLogs 測試資料載入完成${NC}"
        else
            echo "${YELLOW}⚠️  MatchLogs 測試資料可能已存在${NC}"
        fi
        
        echo "${GREEN}✅ 測試資料載入完成${NC}"
        ;;
    "deploy")
        echo "${BLUE}🚀 開始一鍵完整部署...${NC}"
        echo ""
        
        # 檢查環境變數
        LOAD_TEST_DATA=${LOAD_TEST_DATA:-"false"}
        
        echo "${BLUE}🧹 第1步: 清理環境${NC}"
        ./run.sh clean
        echo ""
        
        echo "${BLUE}🔧 第2步: 初始化環境${NC}"
        ./run.sh setup
        echo ""
        
        echo "${BLUE}🚀 第3步: 啟動服務${NC}"
        ./run.sh start
        echo ""
        
        # 如果設置了載入測試資料的環境變數
        if [ "$LOAD_TEST_DATA" = "true" ]; then
            echo "${BLUE}🌱 第4步: 載入測試資料${NC}"
            ./run.sh seed
            echo ""
        fi
        
        echo "${BLUE}🔍 第5步: 執行健康檢查${NC}"
        ./run.sh health
        echo ""
        
        echo "${GREEN}🎉 一鍵部署完成！${NC}"
        echo ""
        echo "${BLUE}📊 系統狀態:${NC}"
        docker-compose ps
        echo ""
        echo "${BLUE}🔗 服務地址:${NC}"
        echo "  API:      http://localhost:8080"
        echo "  Adminer:  http://localhost:8081"
        echo ""
        echo "${BLUE}💡 提示:${NC}"
        echo "  - 如需載入測試資料，請設置: LOAD_TEST_DATA=true ./run.sh deploy"
        echo "  - 查看API測試: ./run.sh test"
        echo "  - 查看服務日誌: ./run.sh logs"
        ;;
    "dev")
        echo "${BLUE}🔥 啟動開發模式...${NC}"
        docker-compose -f docker-compose.yml up
        ;;
    "db")
        echo "${BLUE}💾 開啟 Adminer 資料庫管理介面...${NC}"
        echo "${GREEN}📋 資料庫連線資訊:${NC}"
        echo "   🌐 Adminer: http://localhost:8081"
        echo "   🗄️  伺服器: mysql-db"
        echo "   👤 使用者: root"
        echo "   🔑 密碼: root1234"
        echo "   📊 資料庫: match_system"
        echo ""
        echo "正在檢查 Adminer 服務狀態..."
        
        if docker-compose --env-file docker.env ps adminer | grep -q "Up"; then
            echo "${GREEN}✅ Adminer 已在運行${NC}"
            open "http://localhost:8081" 2>/dev/null || echo "請手動開啟: http://localhost:8081"
        else
            echo "${YELLOW}⚠️  Adminer 未運行，正在啟動...${NC}"
            docker-compose --env-file docker.env up -d adminer
            echo "${GREEN}✅ Adminer 啟動完成${NC}"
            sleep 3
            open "http://localhost:8081" 2>/dev/null || echo "請手動開啟: http://localhost:8081"
        fi
        ;;
    "remove-db")
        echo "${BLUE}🗑️  移除資料庫服務和資料...${NC}"
        echo "${RED}⚠️  警告：此操作將完全移除以下內容：${NC}"
        echo "   - Adminer 容器和映像"
        echo "   - MySQL 容器和映像"
        echo "   - 所有資料庫資料（包含 MatchWagers 表）"
        echo "   - Docker 卷和網路"
        echo ""
        
        # 確認操作
        read -p "確定要繼續嗎？輸入 'YES' 確認: " confirm
        if [ "$confirm" = "YES" ]; then
            echo "${BLUE}🛑 停止所有服務...${NC}"
            docker-compose --env-file docker.env down
            
            echo "${BLUE}🗑️  移除容器...${NC}"
            docker rm -f match_mysql match_adminer 2>/dev/null || true
            
            echo "${BLUE}🗑️  移除映像...${NC}"
            docker rmi mysql:8.0 adminer:4.8.1 2>/dev/null || true
            
            echo "${BLUE}🗑️  移除卷...${NC}"
            docker volume rm match-system_mysql_data 2>/dev/null || true
            
            echo "${BLUE}🗑️  移除網路...${NC}"
            docker network rm match-system_match_network 2>/dev/null || true
            
            echo "${BLUE}🧹 清理未使用的資源...${NC}"
            docker system prune -f
            
            echo "${GREEN}✅ 資料庫服務和資料已完全移除${NC}"
            echo "${YELLOW}💡 如需重新啟動，請執行: ./run.sh setup && ./run.sh start${NC}"
        else
            echo "${YELLOW}❌ 操作已取消${NC}"
        fi
        ;;
    "help"|*)
        show_help
        ;;
esac 