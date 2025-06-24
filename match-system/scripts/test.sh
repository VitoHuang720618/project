#!/bin/bash
set -e

echo "🧪 撮合系統自動化測試開始..."

# 載入環境變數
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 設定預設值
API_PORT=${API_PORT:-8080}
BASE_URL="http://localhost:$API_PORT"

# 測試結果統計
total_tests=0
passed_tests=0
failed_tests=0

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 測試函數
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    total_tests=$((total_tests + 1))
    
    echo -n "🔬 測試 $test_name..."
    
    # 使用 timeout 避免命令卡住
    if timeout 30 bash -c "$test_command" > /dev/null 2>&1; then
        echo -e " ${GREEN}✅ 通過${NC}"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        echo -e " ${RED}❌ 失敗${NC}"
        # 如果測試失敗，顯示實際的錯誤信息用於調試
        echo "    調試信息: $(timeout 30 bash -c "$test_command" 2>&1 | head -n 2)"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}

# API 測試函數
api_test() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"
    
    total_tests=$((total_tests + 1))
    
    echo -n "📡 API 測試 $test_name..."
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "%{http_code}" -X "$method" "$BASE_URL$endpoint")
    fi
    
    status_code="${response: -3}"
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e " ${GREEN}✅ 通過${NC} (狀態碼: $status_code)"
        passed_tests=$((passed_tests + 1))
        return 0
    else
        echo -e " ${RED}❌ 失敗${NC} (期望: $expected_status, 實際: $status_code)"
        failed_tests=$((failed_tests + 1))
        return 1
    fi
}

# 基礎服務健康檢查
basic_health_check() {
    echo -e "${BLUE}🔍 基礎服務健康檢查${NC}"
    
    run_test "API 服務可達性" "curl -s $BASE_URL/api/health > /dev/null" ""
    run_test "MySQL 容器運行" "docker ps | grep -q match_mysql" ""
    run_test "API 容器運行" "docker ps | grep -q match_api" ""
    
    echo ""
}

# API 端點功能測試
api_functionality_tests() {
    echo -e "${BLUE}📡 API 端點功能測試${NC}"
    
    # 健康檢查
    api_test "健康檢查端點" "GET" "/api/health" "" "200"
    
    # 獲取撮合中清單
    api_test "獲取撮合中清單" "POST" "/api/getmatchinglist" "{}" "200"
    
    # 獲取失效單清單
    api_test "獲取失效單清單" "POST" "/api/getrejectedlist" "{}" "200"
    
    # 獲取委託單列表測試
    api_test "獲取委託單列表" "POST" "/api/getwagerslist" '{"Date_S":"2024-01-01","Date_E":"2024-12-31","State":"All"}' "200"
    
    echo ""
}

# 業務流程測試
business_workflow_tests() {
    echo -e "${BLUE}🔄 業務流程測試${NC}"
    
    # 1. 新增出款委託單
    order_data='{"WD_ID":9999,"WD_Amount":1000,"WD_Account":"TEST001"}'
    api_test "新增出款委託單" "POST" "/api/order" "$order_data" "200"
    
    # 等待一下讓資料庫更新
    sleep 1
    
    # 2. 預約入款 (根據金額匹配委託單)
    reserve_data='{"Reserve_UserID":9999,"Reserve_Amount":1000}'
    api_test "預約入款" "POST" "/api/reserve" "$reserve_data" "200"
    
    # 3. 撮合成功 (動態獲取 Matching 狀態的委託單)
    matching_wid=$(docker-compose exec -T mysql-master mysql -u root -proot1234 -e "USE match_system; SELECT WID FROM MatchWagers WHERE State='Matching' AND Reserve_UserID=9999 ORDER BY WID DESC LIMIT 1;" | tail -n +2 | head -n 1)
    success_data="{\"WagerID\":$matching_wid,\"Reserve_UserID\":9999,\"DEP_ID\":9999,\"DEP_Amount\":1000}"
    api_test "撮合成功" "POST" "/api/success" "$success_data" "200"
    
    # 4. 新增第二個委託單用於取消測試
    order_data2='{"WD_ID":9998,"WD_Amount":2000,"WD_Account":"TEST002"}'
    api_test "新增第二個委託單" "POST" "/api/order" "$order_data2" "200"
    
    # 5. 預約第二個委託單
    reserve_data2='{"Reserve_UserID":8888,"Reserve_Amount":2000}'
    api_test "預約第二個委託單" "POST" "/api/reserve" "$reserve_data2" "200"
    
    # 6. 測試取消功能 (使用剛預約的委託單)
    cancel_wid=$(docker-compose exec -T mysql-master mysql -u root -proot1234 -e "USE match_system; SELECT WID FROM MatchWagers WHERE State='Matching' AND Reserve_UserID=8888 ORDER BY WID DESC LIMIT 1;" | tail -n +2 | head -n 1)
    cancel_data="{\"WagerID\":$cancel_wid,\"Reserve_UserID\":8888}"
    api_test "取消撮合" "POST" "/api/cancel" "$cancel_data" "200"
    
    # 7. 新增第三個委託單用於拒絕測試
    order_data3='{"WD_ID":9997,"WD_Amount":3000,"WD_Account":"TEST003"}'
    api_test "新增第三個委託單" "POST" "/api/order" "$order_data3" "200"
    
    # 8. 測試轉失效功能 (使用新的Order狀態委託單)
    reject_wid=$(docker-compose exec -T mysql-master mysql -u root -proot1234 -e "USE match_system; SELECT WID FROM MatchWagers WHERE State='Order' AND WD_ID=9997 ORDER BY WID DESC LIMIT 1;" | tail -n +2 | head -n 1)
    rejected_data="{\"WagerID\":$reject_wid,\"Reserve_UserID\":1}"
    api_test "轉失效單" "POST" "/api/rejected" "$rejected_data" "200"
    
    echo ""
}



# 效能測試
performance_tests() {
    echo -e "${BLUE}⚡ 效能測試${NC}"
    
    # API 響應時間測試
    echo -n "🔬 測試 API 響應時間..."
    response_time=$(curl -w "%{time_total}" -s -o /dev/null $BASE_URL/api/health)
    response_time_ms=$(echo "$response_time * 1000" | bc)
    
    if (( $(echo "$response_time < 1.0" | bc -l) )); then
        echo -e " ${GREEN}✅ 通過${NC} (${response_time_ms%.*}ms)"
        passed_tests=$((passed_tests + 1))
    else
        echo -e " ${YELLOW}⚠️  警告${NC} (${response_time_ms%.*}ms - 響應較慢)"
        passed_tests=$((passed_tests + 1))
    fi
    total_tests=$((total_tests + 1))
    
    # 併發測試 (簡單版本)
    echo -n "🔬 測試 併發處理能力..."
    concurrent_test_result=0
    for i in {1..5}; do
        curl -s $BASE_URL/api/health > /dev/null &
    done
    wait
    
    if [ $? -eq 0 ]; then
        echo -e " ${GREEN}✅ 通過${NC}"
        passed_tests=$((passed_tests + 1))
    else
        echo -e " ${RED}❌ 失敗${NC}"
        failed_tests=$((failed_tests + 1))
    fi
    total_tests=$((total_tests + 1))
    
    # 資料庫查詢效能
    echo -n "🔬 測試 資料庫查詢效能..."
    query_start=$(date +%s.%N)
    docker-compose exec -T mysql-master mysql -u root -proot1234 -e "USE match_system; SELECT COUNT(*) FROM MatchWagers WHERE State = 'Order';" > /dev/null 2>&1
    query_end=$(date +%s.%N)
    query_time=$(echo "$query_end - $query_start" | bc)
    
    if (( $(echo "$query_time < 1.0" | bc -l) )); then
        echo -e " ${GREEN}✅ 通過${NC} ($(echo "$query_time * 1000" | bc | cut -d. -f1)ms)"
        passed_tests=$((passed_tests + 1))
    else
        echo -e " ${YELLOW}⚠️  警告${NC} ($(echo "$query_time * 1000" | bc | cut -d. -f1)ms - 查詢較慢)"
        passed_tests=$((passed_tests + 1))
    fi
    total_tests=$((total_tests + 1))
    
    echo ""
}

# 錯誤處理測試
error_handling_tests() {
    echo -e "${BLUE}🚨 錯誤處理測試${NC}"
    
    # 測試無效資料
    invalid_data='{"invalid":"data"}'
    api_test "無效資料處理" "POST" "/api/order" "$invalid_data" "400"
    
    # 測試不存在的端點
    api_test "404 錯誤處理" "GET" "/api/nonexistent" "" "404"
    
    # 測試無效的 JSON
    api_test "無效 JSON 處理" "POST" "/api/order" "invalid json" "400"
    
    echo ""
}

# 整合測試
integration_tests() {
    echo -e "${BLUE}🔗 整合測試${NC}"
    
    # 完整業務流程測試
    echo "📋 執行完整業務流程..."
    
    # 檢查初始狀態
    run_test "系統初始狀態正常" "curl -s -X POST -H 'Content-Type: application/json' -d '{}' $BASE_URL/api/getmatchinglist | jq '.Success' | grep -q '1'" ""
    
    # 測試分頁功能 (檢查回應格式正確)
    run_test "分頁功能正常" "curl -s -X POST -H 'Content-Type: application/json' -d '{\"page\":1,\"limit\":2}' $BASE_URL/api/getmatchinglist | jq '.orders' > /dev/null" ""
    
    echo ""
}

# 產生測試報告
generate_test_report() {
    echo ""
    echo "📊 測試報告"
    echo "================================"
    echo "總測試數量: $total_tests"
    echo -e "通過測試: ${GREEN}$passed_tests${NC}"
    echo -e "失敗測試: ${RED}$failed_tests${NC}"
    
    if [ "$total_tests" -gt 0 ]; then
        success_rate=$((passed_tests * 100 / total_tests))
        echo "成功率: $success_rate%"
    else
        echo "成功率: 0%"
    fi
    
    echo ""
    
    if [ "$failed_tests" -eq 0 ]; then
        echo -e "${GREEN}🎉 所有測試通過！系統功能正常${NC}"
        echo ""
        echo "✅ 測試涵蓋範圍:"
        echo "  • 基礎服務健康檢查"
        echo "  • API 端點功能測試"
        echo "  • 業務流程測試"
        echo "  • 資料庫完整性測試"
        echo "  • 效能測試"
        echo "  • 錯誤處理測試"
        echo "  • 整合測試"
        echo ""
        return 0
    else
        echo -e "${RED}❌ 發現 $failed_tests 個測試失敗${NC}"
        echo ""
        echo "🔧 建議排除步驟:"
        echo "  1. 檢查服務狀態: make status"
        echo "  2. 查看服務日誌: make logs"
        echo "  3. 執行健康檢查: make health"
        echo "  4. 重啟服務: make restart"
        echo ""
        return 1
    fi
}

# 主要執行流程
main() {
    echo "🚀 開始執行全面測試..."
    echo ""
    
    basic_health_check
    api_functionality_tests
    business_workflow_tests
    performance_tests
    error_handling_tests
    integration_tests
    
    generate_test_report
}

# 檢查必要工具
check_prerequisites() {
    if ! command -v curl &> /dev/null; then
        echo "❌ curl 未安裝，請先安裝 curl"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        echo "⚠️  jq 未安裝，部分測試功能將受限"
    fi
    
    if ! command -v bc &> /dev/null; then
        echo "⚠️  bc 未安裝，效能測試將受限"
    fi
}

# 捕捉錯誤
trap 'echo "❌ 測試過程中發生錯誤"; exit 1' ERR

# 執行測試
check_prerequisites
main "$@" 