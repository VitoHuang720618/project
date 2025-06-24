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

# 顯示選單
show_menu() {
    clear
    echo "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo "${BLUE}║          🚀 撮合系統管理工具 🚀           ║${NC}"
    echo "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "${YELLOW}🚀 快速部署${NC}"
    echo "  ${GREEN}1)${NC} 一鍵完整部署 (推薦新用戶)"
    echo "  ${GREEN}2)${NC} 快速啟動 (假設已建置)"
    echo ""
    echo "${YELLOW}🔧 服務管理${NC}"
    echo "  ${GREEN}3)${NC} 初始化專案環境"
    echo "  ${GREEN}4)${NC} 啟動所有服務"
    echo "  ${GREEN}5)${NC} 停止所有服務"  
    echo "  ${GREEN}6)${NC} 重啟所有服務"
    echo "  ${GREEN}7)${NC} 查看服務狀態"
    echo "  ${GREEN}8)${NC} 查看服務日誌"
    echo ""
    echo "${YELLOW}📊 資料庫管理${NC}"
    echo "  ${GREEN}9)${NC} 執行資料庫遷移"
    echo " ${GREEN}10)${NC} 載入測試資料"
    echo " ${GREEN}11)${NC} 設置 Master-Slave 複製"
    echo " ${GREEN}12)${NC} 檢查資料庫狀態"
    echo " ${GREEN}13)${NC} 開啟 Adminer 管理介面"
    echo ""
    echo "${YELLOW}🧪 測試與監控${NC}"
    echo " ${GREEN}14)${NC} 執行健康檢查"
    echo " ${GREEN}15)${NC} 執行完整測試"
    echo ""
    echo "${YELLOW}🔨 開發工具${NC}"
    echo " ${GREEN}16)${NC} 開發模式啟動"
    echo " ${GREEN}17)${NC} 重新建置服務"
    echo " ${GREEN}18)${NC} 清理環境"
    echo ""
    echo "${YELLOW}🗑️ 清理${NC}"
    echo " ${GREEN}19)${NC} 移除資料庫服務和資料"
    echo ""
    echo "${YELLOW}❓ 其他${NC}"
    echo " ${GREEN}20)${NC} 顯示指令幫助"
    echo "  ${RED}0)${NC} 退出"
    echo ""
    echo -n "${BLUE}請選擇操作 (0-20): ${NC}"
}

# 顯示指令幫助
show_help() {
    echo "${BLUE}🚀 撮合系統管理工具${NC}"
    echo ""
    echo "使用方式: ./run.sh [指令] 或直接執行 ./run.sh 進入選單模式"
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
    echo "  dbstatus  - 檢查 Master-Slave 資料庫狀態"
    echo "  replication - 設置 Master-Slave 複製"
    echo "  remove-db - 移除 Adminer 和 MySQL 服務及資料"
    echo "  help      - 顯示此幫助訊息"
    echo ""
    echo "快速啟動: ./run.sh setup && ./run.sh start && ./run.sh replication"
    echo ""
}

# 執行選擇的功能
execute_choice() {
    case $1 in
        1) 
            echo "${BLUE}執行一鍵完整部署...${NC}"
            show_notification "撮合系統" "開始一鍵完整部署..."
            
            # 執行一鍵部署邏輯
            echo "${BLUE}🧹 第1步: 清理環境${NC}"
            ./scripts/clean.sh
            echo ""
            
            echo "${BLUE}🔧 第2步: 初始化環境${NC}"
            chmod +x scripts/*.sh
            ./scripts/setup.sh
            echo ""
            
            echo "${BLUE}🚀 第3步: 啟動服務${NC}"
            ./scripts/start.sh
            echo ""
            
            echo "${BLUE}🔗 第4步: 設置 Master-Slave 複製${NC}"
            ./scripts/setup_replication.sh
            echo ""
            
            echo "${BLUE}🔍 第5步: 執行健康檢查${NC}"
            ./scripts/health_check.sh
            echo ""
            
            show_notification "撮合系統" "一鍵部署完成！" "success"
            ;;
        2) 
            echo "${BLUE}快速啟動...${NC}"
            show_notification "撮合系統" "開始快速啟動..."
            ./scripts/start.sh && sleep 2 && ./scripts/setup_replication.sh
            show_notification "撮合系統" "快速啟動完成！" "success"
            ;;
        3) 
            echo "${BLUE}初始化專案環境...${NC}"
            chmod +x scripts/*.sh
            ./scripts/setup.sh
            show_notification "撮合系統" "環境初始化完成！" "success"
            ;;
        4) 
            echo "${BLUE}啟動所有服務...${NC}"  
            ./scripts/start.sh
            show_notification "撮合系統" "服務啟動完成！" "success"
            ;;
        5) 
            echo "${BLUE}停止所有服務...${NC}"
            docker-compose --env-file docker.env down
            show_notification "撮合系統" "服務已停止！" "success"
            ;;
        6) 
            echo "${BLUE}重啟所有服務...${NC}"
            docker-compose --env-file docker.env down
            ./scripts/start.sh
            show_notification "撮合系統" "服務重啟完成！" "success"
            ;;
        7) 
            echo "${BLUE}查看服務狀態...${NC}"
            docker-compose --env-file docker.env ps
            ;;
        8) 
            echo "${BLUE}查看服務日誌...${NC}"
            docker-compose --env-file docker.env logs -f
            ;;
        9) 
            echo "${BLUE}執行資料庫遷移...${NC}"
            # 檢查 MySQL Master 是否運行
            if ! docker-compose --env-file docker.env ps mysql-master | grep -q "Up"; then
                echo "${RED}❌ MySQL Master 服務未運行，請先執行啟動服務${NC}"
                return 1
            fi
            go run cmd/migrate/main.go
            show_notification "撮合系統" "資料庫遷移完成！" "success"
            ;;
        10) 
            echo "${BLUE}載入測試資料...${NC}"
            # 檢查 MySQL Master 是否運行
            if ! docker-compose --env-file docker.env ps mysql-master | grep -q "Up"; then
                echo "${RED}❌ MySQL Master 服務未運行，請先執行啟動服務${NC}"
                return 1
            fi
            cat database/seeds/001_test_data.sql | docker-compose --env-file docker.env exec -T mysql-master mysql -u root -proot1234 match_system
            cat database/seeds/002_logs_test_data.sql | docker-compose --env-file docker.env exec -T mysql-master mysql -u root -proot1234 match_system
            show_notification "撮合系統" "測試資料載入完成！" "success"
            ;;
        11) 
            echo "${BLUE}設置 Master-Slave 複製...${NC}"
            ./scripts/setup_replication.sh
            show_notification "撮合系統" "Master-Slave 複製設置完成！" "success"
            ;;
        12) 
            echo "${BLUE}檢查資料庫狀態...${NC}"
            # Master 狀態
            if docker-compose --env-file docker.env ps mysql-master | grep -q "Up"; then
                echo "${GREEN}✅ MySQL Master 運行中${NC}"
                master_count=$(docker-compose --env-file docker.env exec -T mysql-master mysql -u root -proot1234 -e "SELECT COUNT(*) FROM match_system.MatchWagers;" | tail -n 1)
                echo "   📊 Master MatchWagers 記錄數: $master_count"
            else
                echo "${RED}❌ MySQL Master 未運行${NC}"
            fi
            
            # Slave 狀態
            if docker-compose --env-file docker.env ps mysql-slave | grep -q "Up"; then
                echo "${GREEN}✅ MySQL Slave 運行中${NC}"
                slave_count=$(docker-compose --env-file docker.env exec -T mysql-slave mysql -u root -proot1234 -e "SELECT COUNT(*) FROM match_system.MatchWagers;" | tail -n 1)
                echo "   📊 Slave MatchWagers 記錄數: $slave_count"
            else
                echo "${RED}❌ MySQL Slave 未運行${NC}"
            fi
            ;;
        13) 
            echo "${BLUE}開啟 Adminer...${NC}"
            echo "${GREEN}📋 Master-Slave 資料庫連線資訊:${NC}"
            echo "   🌐 Adminer: http://localhost:8081"
            echo "   🗄️  Master 伺服器: mysql-master"
            echo "   🗄️  Slave 伺服器: mysql-slave"
            echo "   👤 使用者: root"
            echo "   🔑 密碼: root1234"
            echo "   📊 資料庫: match_system"
            
            if docker-compose --env-file docker.env ps adminer | grep -q "Up"; then
                echo "${GREEN}✅ Adminer 已在運行${NC}"
                open "http://localhost:8081" 2>/dev/null || echo "請手動開啟: http://localhost:8081"
            else
                echo "${YELLOW}⚠️  Adminer 未運行，正在啟動...${NC}"
                docker-compose --env-file docker.env up -d adminer
                sleep 3
                open "http://localhost:8081" 2>/dev/null || echo "請手動開啟: http://localhost:8081"
            fi
            show_notification "撮合系統" "Adminer 已開啟！" "success"
            ;;
        14) 
            echo "${BLUE}執行健康檢查...${NC}"
            ./scripts/health_check.sh
            ;;
        15) 
            echo "${BLUE}執行完整測試...${NC}"
            ./scripts/test.sh
            ;;
        16) 
            echo "${BLUE}開發模式啟動...${NC}"
            docker-compose --env-file docker.env -f docker-compose.yml up
            ;;
        17) 
            echo "${BLUE}重新建置服務...${NC}"
            docker-compose --env-file docker.env build --no-cache
            show_notification "撮合系統" "服務重建完成！" "success"
            ;;
        18) 
            echo "${BLUE}清理環境...${NC}"
            ./scripts/clean.sh
            show_notification "撮合系統" "環境清理完成！" "success"
            ;;
        19) 
            echo "${BLUE}移除資料庫...${NC}"
            echo "${RED}⚠️  警告：此操作將完全移除 Master-Slave 資料庫服務和資料${NC}"
            echo -n "${YELLOW}確定要繼續嗎？輸入 'YES' 確認: ${NC}"
            read confirm
            if [ "$confirm" = "YES" ]; then
                docker-compose --env-file docker.env down
                docker volume rm match-system_mysql_master_data match-system_mysql_slave_data 2>/dev/null || true
                docker system prune -f
                echo "${GREEN}✅ Master-Slave 資料庫服務和資料已完全移除${NC}"
            else
                echo "${YELLOW}❌ 操作已取消${NC}"
            fi
            ;;
        20) 
            show_help
            echo ""
            echo "${YELLOW}按 Enter 鍵繼續...${NC}"
            read -r 
            ;;
        0) 
            echo "${GREEN}再見！${NC}"
            show_notification "撮合系統" "系統管理工具已關閉" "success"
            exit 0 
            ;;
        *) 
            echo "${RED}無效選擇，請重新輸入 (0-20)${NC}"
            show_notification "撮合系統" "請輸入 0-20 之間的數字" "error"
            sleep 2 
            ;;
    esac
}

# 顯示彈窗通知 (macOS)
show_notification() {
    local title="$1"
    local message="$2"
    local type="${3:-info}"  # info, error, success
    
    # 檢查是否為 macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        case $type in
            "success")
                osascript -e "display notification \"$message\" with title \"✅ $title\" sound name \"Glass\""
                ;;
            "error")
                osascript -e "display notification \"$message\" with title \"❌ $title\" sound name \"Basso\""
                ;;
            *)
                osascript -e "display notification \"$message\" with title \"🚀 $title\""
                ;;
        esac
    fi
}

# 選單模式主循環
menu_mode() {
    while true; do
        show_menu
        read -r choice
        # 去除空白字符
        choice=$(echo "$choice" | tr -d ' \t\n\r')
        echo ""
        
        # 執行選擇的功能
        execute_choice "$choice"
        
        # 如果不是退出或幫助，等待用戶按鍵
        if [ "$choice" != "0" ] && [ "$choice" != "20" ]; then
            echo ""
            echo "${YELLOW}操作完成！按 Enter 鍵返回選單...${NC}"
            read -r
        fi
    done
}

# 主邏輯
if [ $# -eq 0 ]; then
    # 沒有參數時進入選單模式
    menu_mode
else
    # 有參數時執行對應指令
    case "$1" in
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
        docker-compose --env-file docker.env down
        ;;
    "restart")
        echo "${BLUE}🔄 重啟撮合系統...${NC}"
        docker-compose --env-file docker.env down
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
        docker-compose --env-file docker.env ps
        ;;
    "logs")
        echo "${BLUE}📄 查看服務日誌...${NC}"
        docker-compose --env-file docker.env logs -f
        ;;
    "clean")
        echo "${BLUE}🧹 清理環境...${NC}"
        ./scripts/clean.sh
        ;;
    "build")
        echo "${BLUE}🔨 重新建置服務...${NC}"
        docker-compose --env-file docker.env build --no-cache
        ;;
    "migrate")
        echo "${BLUE}📊 執行資料庫遷移...${NC}"
        
        # 檢查 MySQL Master 是否運行
        if ! docker-compose --env-file docker.env ps mysql-master | grep -q "Up"; then
            echo "${RED}❌ MySQL Master 服務未運行，請先執行 ./run.sh start${NC}"
            exit 1
        fi
        
        # 等待 MySQL Master 就緒
        echo "${YELLOW}⏳ 等待 MySQL Master 服務就緒...${NC}"
        for i in {1..30}; do
            if docker-compose --env-file docker.env exec -T mysql-master mysqladmin ping -h localhost -u root -proot1234 > /dev/null 2>&1; then
                echo "${GREEN}✅ MySQL Master 服務就緒${NC}"
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
        
        # 檢查 MySQL Master 是否運行
        if ! docker-compose --env-file docker.env ps mysql-master | grep -q "Up"; then
            echo "${RED}❌ MySQL Master 服務未運行，請先執行 ./run.sh start${NC}"
            exit 1
        fi
        
        # 等待 MySQL Master 就緒
        echo "${YELLOW}⏳ 等待 MySQL Master 服務就緒...${NC}"
        for i in {1..30}; do
            if docker-compose --env-file docker.env exec -T mysql-master mysqladmin ping -h localhost -u root -proot1234 > /dev/null 2>&1; then
                echo "${GREEN}✅ MySQL Master 服務就緒${NC}"
                break
            fi
            
            if [ $i -eq 30 ]; then
                echo "${RED}❌ MySQL 服務連接超時${NC}"
                exit 1
            fi
            
            echo "⏳ 等待 MySQL 就緒... ($i/30)"
            sleep 2
        done
        
        # 載入測試資料到 Master
        echo "${BLUE}🔄 正在載入測試資料到 Master...${NC}"
        
        echo "📊 載入 MatchWagers 測試資料..."
        if cat database/seeds/001_test_data.sql | docker-compose --env-file docker.env exec -T mysql-master mysql -u root -proot1234 match_system; then
            echo "${GREEN}✅ MatchWagers 測試資料載入完成${NC}"
        else
            echo "${YELLOW}⚠️  MatchWagers 測試資料可能已存在${NC}"
        fi
        
        echo "📊 載入 MatchLogs 測試資料..."
        if cat database/seeds/002_logs_test_data.sql | docker-compose --env-file docker.env exec -T mysql-master mysql -u root -proot1234 match_system; then
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
        
        echo "${BLUE}🔗 第4步: 設置 Master-Slave 複製${NC}"
        ./run.sh replication
        echo ""
        
        # 如果設置了載入測試資料的環境變數  
        if [ "$LOAD_TEST_DATA" = "true" ]; then
            echo "${BLUE}🌱 第5步: 載入測試資料${NC}"
            ./run.sh seed
            echo ""
        fi
        
        echo "${BLUE}🔍 第6步: 執行健康檢查${NC}"
        ./run.sh health
        echo ""
        
        echo "${BLUE}📊 第7步: 檢查資料庫狀態${NC}"
        ./run.sh dbstatus
        echo ""
        
        echo "${GREEN}🎉 一鍵部署完成！${NC}"
        echo ""
        echo "${BLUE}📊 系統狀態:${NC}"
        docker-compose --env-file docker.env ps
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
        docker-compose --env-file docker.env -f docker-compose.yml up
        ;;
    "db")
        echo "${BLUE}💾 開啟 Adminer 資料庫管理介面...${NC}"
        echo "${GREEN}📋 Master-Slave 資料庫連線資訊:${NC}"
        echo "   🌐 Adminer: http://localhost:8081"
        echo "   🗄️  Master 伺服器: mysql-master"
        echo "   🗄️  Slave 伺服器: mysql-slave"
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
    "dbstatus")
        echo "${BLUE}📊 檢查 Master-Slave 資料庫狀態...${NC}"
        
        # 檢查 Master 狀態
        echo "${YELLOW}🔍 檢查 Master 資料庫狀態...${NC}"
        if docker-compose --env-file docker.env ps mysql-master | grep -q "Up"; then
            echo "${GREEN}✅ MySQL Master 運行中${NC}"
            master_count=$(docker-compose --env-file docker.env exec -T mysql-master mysql -u root -proot1234 -e "SELECT COUNT(*) FROM match_system.MatchWagers;" | tail -n 1)
            echo "   📊 Master MatchWagers 記錄數: $master_count"
        else
            echo "${RED}❌ MySQL Master 未運行${NC}"
        fi
        
        # 檢查 Slave 狀態
        echo "${YELLOW}🔍 檢查 Slave 資料庫狀態...${NC}"
        if docker-compose --env-file docker.env ps mysql-slave | grep -q "Up"; then
            echo "${GREEN}✅ MySQL Slave 運行中${NC}"
            slave_count=$(docker-compose --env-file docker.env exec -T mysql-slave mysql -u root -proot1234 -e "SELECT COUNT(*) FROM match_system.MatchWagers;" | tail -n 1)
            echo "   📊 Slave MatchWagers 記錄數: $slave_count"
            
            # 檢查複製狀態
            echo "${YELLOW}🔍 檢查複製狀態...${NC}"
            replication_status=$(docker-compose --env-file docker.env exec -T mysql-slave mysql -u root -proot1234 -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running")
            echo "$replication_status"
        else
            echo "${RED}❌ MySQL Slave 未運行${NC}"
        fi
        
        # API 服務狀態
        echo "${YELLOW}🔍 檢查 API 服務狀態...${NC}"
        if curl -s http://localhost:8080/api/health > /dev/null; then
            echo "${GREEN}✅ API 服務正常${NC}"
            echo "   🌐 健康檢查: http://localhost:8080/api/health"
            echo "   📊 資料庫狀態: http://localhost:8080/api/dbstatus"
        else
            echo "${RED}❌ API 服務無法連接${NC}"
        fi
        ;;
    "replication")
        echo "${BLUE}🔗 設置 Master-Slave 複製...${NC}"
        
        # 檢查服務是否運行
        if ! docker-compose --env-file docker.env ps mysql-master | grep -q "Up"; then
            echo "${RED}❌ MySQL Master 未運行，請先執行 ./run.sh start${NC}"
            exit 1
        fi
        
        if ! docker-compose --env-file docker.env ps mysql-slave | grep -q "Up"; then
            echo "${RED}❌ MySQL Slave 未運行，請先執行 ./run.sh start${NC}"
            exit 1
        fi
        
        # 等待服務就緒
        echo "${YELLOW}⏳ 等待 Master-Slave 服務就緒...${NC}"
        sleep 10
        
        # 執行複製設置腳本
        echo "${BLUE}🔄 執行複製設置...${NC}"
        if [ -f scripts/setup_replication.sh ]; then
            chmod +x scripts/setup_replication.sh
            ./scripts/setup_replication.sh
            echo "${GREEN}✅ Master-Slave 複製設置完成${NC}"
        else
            echo "${RED}❌ 複製設置腳本不存在${NC}"
            exit 1
        fi
        
        # 驗證複製狀態
        echo "${BLUE}🔍 驗證複製狀態...${NC}"
        ./run.sh dbstatus
        ;;
    "remove-db")
        echo "${BLUE}🗑️  移除 Master-Slave 資料庫服務和資料...${NC}"
        echo "${RED}⚠️  警告：此操作將完全移除以下內容：${NC}"
        echo "   - Adminer 容器和映像"
        echo "   - MySQL Master 和 Slave 容器和映像"
        echo "   - 所有資料庫資料（包含 MatchWagers 表）"
        echo "   - Docker 卷和網路"
        echo ""
        
        # 確認操作
        read -p "確定要繼續嗎？輸入 'YES' 確認: " confirm
        if [ "$confirm" = "YES" ]; then
            echo "${BLUE}🛑 停止所有服務...${NC}"
            docker-compose --env-file docker.env down
            
            echo "${BLUE}🗑️  移除容器...${NC}"
            docker rm -f match_mysql_master match_mysql_slave match_adminer 2>/dev/null || true
            
            echo "${BLUE}🗑️  移除映像...${NC}"
            docker rmi mysql:8.0 adminer:4.8.1 2>/dev/null || true
            
            echo "${BLUE}🗑️  移除卷...${NC}"
            docker volume rm match-system_mysql_master_data match-system_mysql_slave_data 2>/dev/null || true
            
            echo "${BLUE}🗑️  移除網路...${NC}"
            docker network rm match-system_match_network 2>/dev/null || true
            
            echo "${BLUE}🧹 清理未使用的資源...${NC}"
            docker system prune -f
            
            echo "${GREEN}✅ Master-Slave 資料庫服務和資料已完全移除${NC}"
            echo "${YELLOW}💡 如需重新啟動，請執行: ./run.sh setup && ./run.sh start && ./run.sh replication${NC}"
        else
            echo "${YELLOW}❌ 操作已取消${NC}"
        fi
        ;;
    "help"|*)
        show_help
        ;;
    esac
fi 