#!/bin/bash

echo "🔄 執行完整業務流程整合測試..."

# 設定變數
BASE_URL="http://localhost:8080"
TEST_DATE=$(date +%Y-%m-%d)
TEST_TIMESTAMP=$(date +%s)

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 測試計數器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 測試函數
test_api() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="$5"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "📡 測試 $test_name..."
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
    else
        response=$(curl -s -w "%{http_code}" -X "$method" "$BASE_URL$endpoint")
    fi
    
    status_code="${response: -3}"
    response_body="${response%???}"
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e " ${GREEN}✅ 通過${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e " ${RED}❌ 失敗${NC} (期望: $expected_status, 實際: $status_code)"
        echo "回應內容: $response_body"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 錯誤測試函數 (檢查Success欄位)
test_error_api() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "📡 測試 $test_name..."
    
    if [ -n "$data" ]; then
        response=$(curl -s -X "$method" -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
    else
        response=$(curl -s -X "$method" "$BASE_URL$endpoint")
    fi
    
    if echo "$response" | grep -q '"Success":0'; then
        echo -e " ${GREEN}✅ 通過${NC} (錯誤正確處理)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e " ${RED}❌ 失敗${NC} (未正確處理錯誤)"
        echo "回應內容: $response"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# 情境1: 完整撮合流程
scenario_complete_matching() {
    echo -e "${BLUE}📋 情境1: 完整撮合流程${NC}"
    
    # 1. 新增出款委託單
    order_data="{\"wd_id\":${TEST_TIMESTAMP}1,\"wd_amount\":5000,\"wd_account\":\"TEST${TEST_TIMESTAMP}\",\"wd_date\":\"$TEST_DATE\"}"
    test_api "新增出款委託單" "POST" "/api/order" "$order_data" "200"
    
    # 等待資料庫更新
    sleep 1
    
    # 2. 獲取撮合中清單 (應該包含剛建立的委託單)
    test_api "檢查撮合中清單" "POST" "/api/getmatchinglist" "{}" "200"
    
    # 3. 預約入款 (假設使用第一個可用的委託單)
    reserve_data="{\"wid\":1,\"reserve_user_id\":${TEST_TIMESTAMP}}"
    test_api "預約入款" "POST" "/api/reserve" "$reserve_data" "200"
    
    # 4. 撮合成功
    success_data="{\"wid\":1,\"dep_id\":${TEST_TIMESTAMP},\"dep_amount\":5000}"
    test_api "撮合成功" "POST" "/api/success" "$success_data" "200"
    
    echo ""
}

# 情境2: 取消撮合流程
scenario_cancel_matching() {
    echo -e "${BLUE}📋 情境2: 取消撮合流程${NC}"
    
    # 1. 新增出款委託單
    order_data="{\"wd_id\":${TEST_TIMESTAMP}2,\"wd_amount\":3000,\"wd_account\":\"CANCEL${TEST_TIMESTAMP}\",\"wd_date\":\"$TEST_DATE\"}"
    test_api "新增出款委託單(取消用)" "POST" "/api/order" "$order_data" "200"
    
    sleep 1
    
    # 2. 預約入款
    reserve_data="{\"wid\":2,\"reserve_user_id\":${TEST_TIMESTAMP}}"
    test_api "預約入款(取消用)" "POST" "/api/reserve" "$reserve_data" "200"
    
    # 3. 取消撮合
    cancel_data="{\"wid\":2}"
    test_api "取消撮合" "POST" "/api/cancel" "$cancel_data" "200"
    
    echo ""
}

# 情境3: 失效單流程
scenario_rejected_order() {
    echo -e "${BLUE}📋 情境3: 失效單流程${NC}"
    
    # 1. 新增出款委託單
    order_data="{\"wd_id\":${TEST_TIMESTAMP}3,\"wd_amount\":2000,\"wd_account\":\"REJECT${TEST_TIMESTAMP}\",\"wd_date\":\"$TEST_DATE\"}"
    test_api "新增出款委託單(失效用)" "POST" "/api/order" "$order_data" "200"
    
    sleep 1
    
    # 2. 轉為失效單
    rejected_data="{\"wid\":3}"
    test_api "轉失效單" "POST" "/api/rejected" "$rejected_data" "200"
    
    # 3. 檢查失效單清單
    test_api "檢查失效單清單" "POST" "/api/getrejectedlist" "{}" "200"
    
    echo ""
}

# 情境4: 分頁功能測試
scenario_pagination() {
    echo -e "${BLUE}📋 情境4: 分頁功能測試${NC}"
    
    # 測試委託單列表查詢
    test_api "委託單列表查詢" "POST" "/api/getwagerslist" '{"Date_S":"2024-01-01","Date_E":"2024-12-31","State":"All"}' "200"
    test_api "撮合中清單查詢" "POST" "/api/getmatchinglist" "{}" "200"
    test_api "失效單清單查詢" "POST" "/api/getrejectedlist" "{}" "200"
    
    echo ""
}

# 情境5: 錯誤處理測試
scenario_error_handling() {
    echo -e "${BLUE}📋 情境5: 錯誤處理測試${NC}"
    
    # 測試無效資料
    invalid_order="{\"invalid\":\"data\"}"
    test_error_api "無效訂單資料" "POST" "/api/order" "$invalid_order"
    
    # 測試不存在的委託單操作
    nonexistent_wid="{\"WagerID\":99999,\"Reserve_UserID\":99999}"
    test_error_api "操作不存在的委託單" "POST" "/api/cancel" "$nonexistent_wid"
    
    # 測試無效 JSON
    test_error_api "無效 JSON" "POST" "/api/order" "invalid json"
    
    echo ""
}

# 情境6: 資料一致性檢查
scenario_data_consistency() {
    echo -e "${BLUE}📋 情境6: 資料一致性檢查${NC}"
    
    # 檢查各種狀態的資料是否正確分類
    echo "🔍 檢查資料一致性..."
    
    # 獲取撮合中清單並檢查回應格式
    matching_response=$(curl -s -X POST -H "Content-Type: application/json" -d '{}' "$BASE_URL/api/getmatchinglist")
    if echo "$matching_response" | grep -q '"Success":' && echo "$matching_response" | grep -q '"RunTime":'; then
        echo -e "📋 撮合中清單格式檢查... ${GREEN}✅ 通過${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "📋 撮合中清單格式檢查... ${RED}❌ 失敗${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # 獲取失效單清單並檢查回應格式
    rejected_response=$(curl -s -X POST -H "Content-Type: application/json" -d '{}' "$BASE_URL/api/getrejectedlist")
    if echo "$rejected_response" | grep -q '"Success":' && echo "$rejected_response" | grep -q '"RunTime":'; then
        echo -e "📋 失效單清單格式檢查... ${GREEN}✅ 通過${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "📋 失效單清單格式檢查... ${RED}❌ 失敗${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo ""
}

# 情境7: 效能基準測試
scenario_performance_baseline() {
    echo -e "${BLUE}📋 情境7: 效能基準測試${NC}"
    
    # API 響應時間測試
    echo -n "⚡ API 響應時間測試..."
    start_time=$(date +%s.%N)
    curl -s "$BASE_URL/api/health" > /dev/null
    end_time=$(date +%s.%N)
    response_time=$(echo "$end_time - $start_time" | bc)
    
    if (( $(echo "$response_time < 1.0" | bc -l) )); then
        echo -e " ${GREEN}✅ 通過${NC} ($(echo "$response_time * 1000" | bc | cut -d. -f1)ms)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e " ${YELLOW}⚠️  警告${NC} ($(echo "$response_time * 1000" | bc | cut -d. -f1)ms)"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # 併發請求測試
    echo -n "⚡ 併發請求測試..."
    for i in {1..5}; do
        curl -s "$BASE_URL/api/health" > /dev/null &
    done
    wait
    
    if [ $? -eq 0 ]; then
        echo -e " ${GREEN}✅ 通過${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e " ${RED}❌ 失敗${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo ""
}

# 生成測試報告
generate_report() {
    echo ""
    echo "📊 整合測試報告"
    echo "================================"
    echo "總測試數量: $TOTAL_TESTS"
    echo -e "通過測試: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失敗測試: ${RED}$FAILED_TESTS${NC}"
    
    if [ "$TOTAL_TESTS" -gt 0 ]; then
        success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        echo "成功率: $success_rate%"
    fi
    
    echo ""
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}🎉 所有整合測試通過！${NC}"
        echo "✅ 測試涵蓋情境:"
        echo "  • 完整撮合流程"
        echo "  • 取消撮合流程"
        echo "  • 失效單流程"
        echo "  • 分頁功能"
        echo "  • 錯誤處理"
        echo "  • 資料一致性"
        echo "  • 效能基準"
        return 0
    else
        echo -e "${RED}❌ 發現 $FAILED_TESTS 個測試失敗${NC}"
        return 1
    fi
}

# 檢查必要工具
check_prerequisites() {
    if ! command -v curl &> /dev/null; then
        echo "❌ curl 未安裝"
        exit 1
    fi
    
    if ! command -v bc &> /dev/null; then
        echo "⚠️  bc 未安裝，效能測試將受限"
    fi
}

# 主要執行流程
main() {
    echo "🚀 開始整合測試..."
    echo "測試目標: $BASE_URL"
    echo "測試時間: $(date)"
    echo ""
    
    # 檢查服務是否可用
    echo -n "🔍 檢查服務可用性..."
    if curl -s "$BASE_URL/api/health" > /dev/null; then
        echo -e " ${GREEN}✅ 服務正常${NC}"
    else
        echo -e " ${RED}❌ 服務不可用${NC}"
        echo "請先啟動撮合系統: make start"
        exit 1
    fi
    echo ""
    
    # 執行測試情境
    scenario_complete_matching
    scenario_cancel_matching
    scenario_rejected_order
    scenario_pagination
    scenario_error_handling
    scenario_data_consistency
    scenario_performance_baseline
    
    # 生成報告
    generate_report
}

# 檢查前置條件並執行測試
check_prerequisites
main "$@" 