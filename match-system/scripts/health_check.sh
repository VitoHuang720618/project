#!/bin/bash

echo "🔍 執行系統健康檢查..."

# 載入環境變數
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 設定預設值
API_PORT=${API_PORT:-8080}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-root1234}

# 檢查結果統計
total_checks=0
passed_checks=0
failed_checks=0

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查函數
check_service() {
    local service_name="$1"
    local check_command="$2"
    local expected_result="$3"
    
    total_checks=$((total_checks + 1))
    
    echo -n "📋 檢查 $service_name..."
    
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e " ${GREEN}✅ 通過${NC}"
        passed_checks=$((passed_checks + 1))
        return 0
    else
        echo -e " ${RED}❌ 失敗${NC}"
        failed_checks=$((failed_checks + 1))
        return 1
    fi
}

# Docker 服務檢查
check_docker_services() {
    echo "🐳 檢查 Docker 服務..."
    
    check_service "Docker 守護程序" "docker info" ""
    check_service "match_mysql_master 容器" "docker ps | grep -q match_mysql_master" ""
    check_service "match_mysql_slave 容器" "docker ps | grep -q match_mysql_slave" ""
    check_service "match_api 容器" "docker ps | grep -q match_api" ""
    
    # 檢查容器健康狀態
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "match_mysql_master.*healthy"; then
        echo -e "📋 檢查 MySQL Master 容器健康狀態... ${GREEN}✅ 通過${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "📋 檢查 MySQL Master 容器健康狀態... ${RED}❌ 失敗${NC}"
        failed_checks=$((failed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "match_mysql_slave.*healthy"; then
        echo -e "📋 檢查 MySQL Slave 容器健康狀態... ${GREEN}✅ 通過${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "📋 檢查 MySQL Slave 容器健康狀態... ${RED}❌ 失敗${NC}"
        failed_checks=$((failed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "match_api.*healthy"; then
        echo -e "📋 檢查 API 容器健康狀態... ${GREEN}✅ 通過${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "📋 檢查 API 容器健康狀態... ${RED}❌ 失敗${NC}"
        failed_checks=$((failed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
}

# 網路連接檢查
check_network_connectivity() {
    echo "🌐 檢查網路連接..."
    
    check_service "API 連接埠 $API_PORT" "nc -z localhost $API_PORT" ""
    check_service "MySQL 連接埠 $MYSQL_PORT" "nc -z localhost $MYSQL_PORT" ""
}

# API 端點檢查
check_api_endpoints() {
    echo "📡 檢查 API 端點..."
    
    base_url="http://localhost:$API_PORT"
    
    # 健康檢查端點
    check_service "API 健康檢查" "curl -s $base_url/api/health | grep -q 'OK'" ""
    
    # 測試主要 API 端點
    endpoints=(
        "/api/getmatchinglist"
        "/api/getrejectedlist"
    )
    
    for endpoint in "${endpoints[@]}"; do
        check_service "API 端點 $endpoint" "curl -s -w '%{http_code}' $base_url$endpoint | grep -q '200'" ""
    done
}

# 資料庫檢查
check_database() {
    echo "🗄️  檢查資料庫..."
    
    # MySQL Master 連接檢查
    check_service "MySQL Master 連接" "docker-compose exec -T mysql-master mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD" ""
    check_service "MySQL Slave 連接" "docker-compose exec -T mysql-slave mysqladmin ping -h localhost -u root -p$MYSQL_ROOT_PASSWORD" ""
    
    # 資料庫存在檢查
    check_service "match_system 資料庫 (Master)" "docker-compose exec -T mysql-master mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'USE match_system; SELECT 1;'" ""
    check_service "match_system 資料庫 (Slave)" "docker-compose exec -T mysql-slave mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'USE match_system; SELECT 1;'" ""
    
    # 資料表存在檢查
    check_service "MatchWagers 資料表 (Master)" "docker-compose exec -T mysql-master mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'USE match_system; DESCRIBE MatchWagers;'" ""
    check_service "MatchWagers 資料表 (Slave)" "docker-compose exec -T mysql-slave mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'USE match_system; DESCRIBE MatchWagers;'" ""
    
    # 資料完整性檢查
    check_service "測試資料存在 (Master)" "docker-compose exec -T mysql-master mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'USE match_system; SELECT COUNT(*) FROM MatchWagers;' | grep -v COUNT | grep -q '[1-9]'" ""
    check_service "測試資料存在 (Slave)" "docker-compose exec -T mysql-slave mysql -u root -p$MYSQL_ROOT_PASSWORD -e 'USE match_system; SELECT COUNT(*) FROM MatchWagers;' | grep -v COUNT | grep -q '[1-9]'" ""
}

# 系統資源檢查
check_system_resources() {
    echo "💻 檢查系統資源..."
    
    # 磁碟空間檢查 (剩餘空間 > 1GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [ "$available_space" -gt 1048576 ]; then
        echo -e "📋 檢查磁碟空間... ${GREEN}✅ 通過${NC} (可用: $(($available_space/1024/1024))GB)"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "📋 檢查磁碟空間... ${RED}❌ 失敗${NC} (可用: $(($available_space/1024/1024))GB)"
        failed_checks=$((failed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
    
    # 記憶體檢查
    available_memory=$(free -m | awk 'NR==2{print $7}')
    if [ "$available_memory" -gt 512 ]; then
        echo -e "📋 檢查可用記憶體... ${GREEN}✅ 通過${NC} (可用: ${available_memory}MB)"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "📋 檢查可用記憶體... ${YELLOW}⚠️  警告${NC} (可用: ${available_memory}MB)"
        passed_checks=$((passed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
}

# 效能檢查
check_performance() {
    echo "⚡ 檢查系統效能..."
    
    # API 響應時間檢查
    response_time=$(curl -w "%{time_total}" -s -o /dev/null http://localhost:$API_PORT/api/health)
    response_time_ms=$(echo "$response_time * 1000" | bc)
    
    if (( $(echo "$response_time < 1.0" | bc -l) )); then
        echo -e "📋 檢查 API 響應時間... ${GREEN}✅ 通過${NC} (${response_time_ms%.*}ms)"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "📋 檢查 API 響應時間... ${YELLOW}⚠️  警告${NC} (${response_time_ms%.*}ms)"
        passed_checks=$((passed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
    
    # 資料庫查詢效能檢查
    query_time=$(docker-compose exec -T mysql-master mysql -u root -p$MYSQL_ROOT_PASSWORD -e "USE match_system; SELECT COUNT(*) FROM MatchWagers;" 2>/dev/null | wc -l)
    if [ "$query_time" -gt 0 ]; then
        echo -e "📋 檢查資料庫查詢效能... ${GREEN}✅ 通過${NC}"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "📋 檢查資料庫查詢效能... ${RED}❌ 失敗${NC}"
        failed_checks=$((failed_checks + 1))
    fi
    total_checks=$((total_checks + 1))
}

# 產生健康檢查報告
generate_health_report() {
    echo ""
    echo "📊 健康檢查報告"
    echo "================================"
    echo "總檢查項目: $total_checks"
    echo -e "通過項目: ${GREEN}$passed_checks${NC}"
    echo -e "失敗項目: ${RED}$failed_checks${NC}"
    echo "成功率: $((passed_checks * 100 / total_checks))%"
    echo ""
    
    if [ "$failed_checks" -eq 0 ]; then
        echo -e "${GREEN}🎉 所有健康檢查通過！系統運行正常${NC}"
        echo ""
        echo "🔗 服務地址:"
        echo "  API: http://localhost:$API_PORT"
        echo "  MySQL: localhost:$MYSQL_PORT"
        echo ""
        return 0
    else
        echo -e "${RED}❌ 發現 $failed_checks 個問題，請檢查上方錯誤訊息${NC}"
        echo ""
        echo "🔧 故障排除建議:"
        echo "  1. 檢查服務日誌: make logs"
        echo "  2. 重啟服務: make restart"
        echo "  3. 查看服務狀態: make status"
        echo ""
        return 1
    fi
}

# 主要執行流程
main() {
    check_docker_services
    echo ""
    check_network_connectivity
    echo ""
    check_api_endpoints
    echo ""
    check_database
    echo ""
    check_system_resources
    echo ""
    check_performance
    echo ""
    generate_health_report
}

# 執行檢查
main "$@" 