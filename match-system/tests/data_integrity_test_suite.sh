#!/bin/bash
# 資料完整性測試套件

set -e

API_URL="http://localhost:8080"
DB_CONTAINER="725a3bb4abc7"
DB_USER="root"
DB_PASS="root1234"
DB_NAME="match_system"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# 資料庫操作函數
db_query() {
    docker exec "$DB_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "$1" 2>/dev/null
}

db_exec() {
    docker exec "$DB_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$1" 2>/dev/null
}

# 測試結果記錄
test_result() {
    local test_name="$1"
    local success="$2"
    local message="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$success" = "true" ]; then
        log_success "$test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "$test_name - $message"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# 驗證資料庫狀態
verify_db_state() {
    local wid="$1"
    local expected_state="$2"
    local actual_state=$(db_query "SELECT State FROM MatchWagers WHERE WID = $wid")
    
    if [ "$actual_state" = "$expected_state" ]; then
        return 0
    else
        return 1
    fi
}

# 驗證日誌記錄
verify_log_exists() {
    local wid="$1"
    local action="$2"
    local count=$(db_query "SELECT COUNT(*) FROM MatchLogs WHERE WagerID = $wid AND Action = '$action'")
    
    if [ "$count" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# 狀態轉換一致性測試
test_state_transitions() {
    log_info "=== 狀態轉換一致性測試 ==="
    
    # 測試1: Order → Matching → Success
    test_order_to_success_consistency() {
        local test_name="Order→Success狀態轉換一致性"
        
        # 創建Order
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":100001,"WD_Amount":5000,"WD_Account":"111222333444555"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 驗證初始狀態
        if ! verify_db_state "$wid" "Order"; then
            test_result "$test_name" "false" "初始狀態不正確"
            return
        fi
        
        # 執行Reserve
        curl -s -X POST "$API_URL/api/reserve" -H "Content-Type: application/json" \
            -d '{"Reserve_UserID":8001,"Reserve_Amount":5000}' > /dev/null
        
        # 驗證Matching狀態
        if ! verify_db_state "$wid" "Matching"; then
            test_result "$test_name" "false" "Reserve後狀態不正確"
            return
        fi
        
        # 驗證Reserve欄位
        local reserve_data=$(db_query "SELECT Reserve_UserID, Reserve_DateTime FROM MatchWagers WHERE WID = $wid")
        if [ -z "$reserve_data" ]; then
            test_result "$test_name" "false" "Reserve欄位未正確設置"
            return
        fi
        
        # 執行Success
        curl -s -X POST "$API_URL/api/success" -H "Content-Type: application/json" \
            -d "{\"WagerID\":$wid,\"Reserve_UserID\":8001,\"DEP_ID\":200001,\"DEP_Amount\":5000}" > /dev/null
        
        # 驗證Success狀態和相關欄位
        if ! verify_db_state "$wid" "Success"; then
            test_result "$test_name" "false" "Success後狀態不正確"
            return
        fi
        
        local success_data=$(db_query "SELECT DEP_ID, DEP_Amount, Finish_DateTime FROM MatchWagers WHERE WID = $wid")
        if [ -z "$success_data" ]; then
            test_result "$test_name" "false" "Success欄位未正確設置"
            return
        fi
        
        test_result "$test_name" "true" ""
    }
    
    # 測試2: Order → Matching → Cancel
    test_order_to_cancel_consistency() {
        local test_name="Order→Cancel狀態轉換一致性"
        
        # 創建Order
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":100002,"WD_Amount":10000,"WD_Account":"222333444555666"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 執行Reserve
        curl -s -X POST "$API_URL/api/reserve" -H "Content-Type: application/json" \
            -d '{"Reserve_UserID":7001,"Reserve_Amount":10000}' > /dev/null
        
        # 驗證Matching狀態
        if ! verify_db_state "$wid" "Matching"; then
            test_result "$test_name" "false" "Reserve後狀態不正確"
            return
        fi
        
        # 執行Cancel
        curl -s -X POST "$API_URL/api/cancel" -H "Content-Type: application/json" \
            -d "{\"WagerID\":$wid,\"Reserve_UserID\":7001}" > /dev/null
        
        # 驗證Cancel狀態
        if ! verify_db_state "$wid" "Cancel"; then
            test_result "$test_name" "false" "Cancel後狀態不正確"
            return
        fi
        
        # 驗證Finish_DateTime已設置
        local finish_time=$(db_query "SELECT Finish_DateTime FROM MatchWagers WHERE WID = $wid")
        if [ -z "$finish_time" ] || [ "$finish_time" = "NULL" ]; then
            test_result "$test_name" "false" "Finish_DateTime未設置"
            return
        fi
        
        test_result "$test_name" "true" ""
    }
    
    # 測試3: Order → Rejected
    test_order_to_rejected_consistency() {
        local test_name="Order→Rejected狀態轉換一致性"
        
        # 創建Order
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":100003,"WD_Amount":1000,"WD_Account":"333444555666777"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 模擬超時（設置為16分鐘前）
        db_exec "UPDATE MatchWagers SET WD_DateTime = DATE_SUB(NOW(), INTERVAL 16 MINUTE) WHERE WID = $wid"
        
        # 執行Rejected
        curl -s -X POST "$API_URL/api/rejected" -H "Content-Type: application/json" \
            -d "{\"WagerID\":$wid,\"Reserve_UserID\":9001}" > /dev/null
        
        # 驗證Rejected狀態
        if ! verify_db_state "$wid" "Rejected"; then
            test_result "$test_name" "false" "Rejected後狀態不正確"
            return
        fi
        
        # 驗證Finish_DateTime已設置
        local finish_time=$(db_query "SELECT Finish_DateTime FROM MatchWagers WHERE WID = $wid")
        if [ -z "$finish_time" ] || [ "$finish_time" = "NULL" ]; then
            test_result "$test_name" "false" "Finish_DateTime未設置"
            return
        fi
        
        test_result "$test_name" "true" ""
    }
    
    test_order_to_success_consistency
    test_order_to_cancel_consistency
    test_order_to_rejected_consistency
}

# 日誌完整性測試
test_log_integrity() {
    log_info "=== 日誌完整性測試 ==="
    
    # 測試Order創建日誌
    test_order_log_integrity() {
        local test_name="Order創建日誌完整性"
        
        # 創建Order
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":101001,"WD_Amount":2000,"WD_Account":"444555666777888"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 檢查是否有create_order日誌
        if verify_log_exists "$wid" "create_order"; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "缺少create_order日誌"
        fi
    }
    
    # 測試Reserve日誌
    test_reserve_log_integrity() {
        local test_name="Reserve日誌完整性"
        
        # 創建Order
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":101002,"WD_Amount":3000,"WD_Account":"555666777888999"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 執行Reserve
        curl -s -X POST "$API_URL/api/reserve" -H "Content-Type: application/json" \
            -d '{"Reserve_UserID":8002,"Reserve_Amount":3000}' > /dev/null
        
        # 檢查是否有create_reserve日誌
        if verify_log_exists "$wid" "create_reserve"; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "缺少create_reserve日誌"
        fi
    }
    
    # 測試狀態變更日誌
    test_state_change_log_integrity() {
        local test_name="狀態變更日誌完整性"
        
        # 創建Order並完成整個流程
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":101003,"WD_Amount":4000,"WD_Account":"666777888999000"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 執行Reserve
        curl -s -X POST "$API_URL/api/reserve" -H "Content-Type: application/json" \
            -d '{"Reserve_UserID":8003,"Reserve_Amount":4000}' > /dev/null
        
        # 執行Success
        curl -s -X POST "$API_URL/api/success" -H "Content-Type: application/json" \
            -d "{\"WagerID\":$wid,\"Reserve_UserID\":8003,\"DEP_ID\":200003,\"DEP_Amount\":4000}" > /dev/null
        
        # 檢查狀態變更日誌
        local state_change_count=$(db_query "SELECT COUNT(*) FROM MatchLogs WHERE WagerID = $wid AND Action = 'state_change'")
        
        if [ "$state_change_count" -ge 1 ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "缺少狀態變更日誌"
        fi
    }
    
    test_order_log_integrity
    test_reserve_log_integrity
    test_state_change_log_integrity
}

# 資料關聯性測試
test_data_relationships() {
    log_info "=== 資料關聯性測試 ==="
    
    # 測試金額一致性
    test_amount_consistency() {
        local test_name="金額一致性測試"
        
        # 創建Order
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":102001,"WD_Amount":5000,"WD_Account":"777888999000111"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 執行Reserve
        curl -s -X POST "$API_URL/api/reserve" -H "Content-Type: application/json" \
            -d '{"Reserve_UserID":8004,"Reserve_Amount":5000}' > /dev/null
        
        # 執行Success
        curl -s -X POST "$API_URL/api/success" -H "Content-Type: application/json" \
            -d "{\"WagerID\":$wid,\"Reserve_UserID\":8004,\"DEP_ID\":200004,\"DEP_Amount\":5000}" > /dev/null
        
        # 檢查WD_Amount和DEP_Amount是否一致
        local amounts=$(db_query "SELECT WD_Amount, DEP_Amount FROM MatchWagers WHERE WID = $wid")
        local wd_amount=$(echo "$amounts" | cut -f1)
        local dep_amount=$(echo "$amounts" | cut -f2)
        
        if [ "$wd_amount" = "$dep_amount" ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "WD_Amount($wd_amount) != DEP_Amount($dep_amount)"
        fi
    }
    
    # 測試UserID一致性
    test_userid_consistency() {
        local test_name="UserID一致性測試"
        
        # 創建Order
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":102002,"WD_Amount":6000,"WD_Account":"888999000111222"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        local user_id=8005
        
        # 執行Reserve
        curl -s -X POST "$API_URL/api/reserve" -H "Content-Type: application/json" \
            -d "{\"Reserve_UserID\":$user_id,\"Reserve_Amount\":6000}" > /dev/null
        
        # 執行Success
        curl -s -X POST "$API_URL/api/success" -H "Content-Type: application/json" \
            -d "{\"WagerID\":$wid,\"Reserve_UserID\":$user_id,\"DEP_ID\":200005,\"DEP_Amount\":6000}" > /dev/null
        
        # 檢查Reserve_UserID是否一致
        local db_user_id=$(db_query "SELECT Reserve_UserID FROM MatchWagers WHERE WID = $wid")
        
        if [ "$db_user_id" = "$user_id" ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "UserID不一致 (期望:$user_id, 實際:$db_user_id)"
        fi
    }
    
    # 測試時間戳邏輯
    test_timestamp_logic() {
        local test_name="時間戳邏輯測試"
        
        # 創建Order
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":102003,"WD_Amount":7000,"WD_Account":"999000111222333"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 執行Reserve
        curl -s -X POST "$API_URL/api/reserve" -H "Content-Type: application/json" \
            -d '{"Reserve_UserID":8006,"Reserve_Amount":7000}' > /dev/null
        
        # 執行Success
        curl -s -X POST "$API_URL/api/success" -H "Content-Type: application/json" \
            -d "{\"WagerID\":$wid,\"Reserve_UserID\":8006,\"DEP_ID\":200006,\"DEP_Amount\":7000}" > /dev/null
        
        # 檢查時間戳邏輯：WD_DateTime <= Reserve_DateTime <= Finish_DateTime
        local timestamps=$(db_query "SELECT WD_DateTime, Reserve_DateTime, Finish_DateTime FROM MatchWagers WHERE WID = $wid")
        local wd_time=$(echo "$timestamps" | cut -f1)
        local reserve_time=$(echo "$timestamps" | cut -f2)
        local finish_time=$(echo "$timestamps" | cut -f3)
        
        # 簡單檢查是否都有值
        if [ -n "$wd_time" ] && [ -n "$reserve_time" ] && [ -n "$finish_time" ] && \
           [ "$wd_time" != "NULL" ] && [ "$reserve_time" != "NULL" ] && [ "$finish_time" != "NULL" ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "時間戳設置不完整"
        fi
    }
    
    test_amount_consistency
    test_userid_consistency
    test_timestamp_logic
}

# ACID特性測試
test_acid_properties() {
    log_info "=== ACID特性測試 ==="
    
    # 測試原子性（Atomicity）
    test_atomicity() {
        local test_name="原子性測試"
        
        # 嘗試執行一個會失敗的Success操作
        local response=$(curl -s -X POST "$API_URL/api/success" -H "Content-Type: application/json" \
            -d '{"WagerID":999999,"Reserve_UserID":8007,"DEP_ID":200007,"DEP_Amount":1000}')
        
        local success=$(echo "$response" | jq -r '.Success // "0"')
        
        # 檢查失敗的操作是否沒有產生部分更新
        local partial_update=$(db_query "SELECT COUNT(*) FROM MatchWagers WHERE WID = 999999")
        
        if [ "$success" = "0" ] && [ "$partial_update" = "0" ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "可能存在部分更新"
        fi
    }
    
    # 測試一致性（Consistency）
    test_consistency() {
        local test_name="一致性測試"
        
        # 檢查所有Success狀態的記錄是否都有完整的欄位
        local incomplete_success=$(db_query "SELECT COUNT(*) FROM MatchWagers WHERE State = 'Success' AND (DEP_ID IS NULL OR DEP_Amount IS NULL OR Finish_DateTime IS NULL)")
        
        if [ "$incomplete_success" = "0" ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "發現不完整的Success記錄: $incomplete_success"
        fi
    }
    
    # 測試隔離性（Isolation）
    test_isolation() {
        local test_name="隔離性測試"
        
        # 這個測試比較複雜，這裡做簡化版本
        # 檢查是否存在狀態不一致的情況
        local inconsistent_states=$(db_query "SELECT COUNT(*) FROM MatchWagers WHERE State = 'Matching' AND (Reserve_UserID IS NULL OR Reserve_DateTime IS NULL)")
        
        if [ "$inconsistent_states" = "0" ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "發現狀態不一致的記錄: $inconsistent_states"
        fi
    }
    
    # 測試持久性（Durability）
    test_durability() {
        local test_name="持久性測試"
        
        # 創建一個Order然後檢查是否持久化
        local response=$(curl -s -X POST "$API_URL/api/order" -H "Content-Type: application/json" \
            -d '{"WD_ID":103001,"WD_Amount":8000,"WD_Account":"000111222333444"}')
        local wid=$(echo "$response" | jq -r '.Data.WID // "null"')
        
        if [ "$wid" = "null" ]; then
            test_result "$test_name" "false" "無法創建Order"
            return
        fi
        
        # 短暫等待後檢查資料是否仍存在
        sleep 1
        local exists=$(db_query "SELECT COUNT(*) FROM MatchWagers WHERE WID = $wid")
        
        if [ "$exists" = "1" ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "資料未持久化"
        fi
    }
    
    test_atomicity
    test_consistency
    test_isolation
    test_durability
}

# 併發資料一致性測試
test_concurrent_consistency() {
    log_info "=== 併發資料一致性測試 ==="
    
    # 測試併發Order創建
    test_concurrent_order_consistency() {
        local test_name="併發Order一致性測試"
        
        log_info "執行併發Order創建..."
        local pids=()
        local base_id=104000
        
        # 同時創建多個Order
        for i in {1..10}; do
            {
                curl -s -X POST "$API_URL/api/order" \
                    -H "Content-Type: application/json" \
                    -d "{\"WD_ID\":$((base_id + i)),\"WD_Amount\":1000,\"WD_Account\":\"123456789012345\"}" \
                    > /tmp/concurrent_order_$i.result 2>/dev/null
            } &
            pids+=($!)
        done
        
        # 等待所有請求完成
        for pid in "${pids[@]}"; do
            wait $pid
        done
        
        # 檢查是否所有Order都正確創建
        local created_count=$(db_query "SELECT COUNT(*) FROM MatchWagers WHERE WD_ID BETWEEN $((base_id + 1)) AND $((base_id + 10))")
        
        # 清理
        rm -f /tmp/concurrent_order_*.result
        
        if [ "$created_count" = "10" ]; then
            test_result "$test_name" "true" ""
        else
            test_result "$test_name" "false" "併發創建不一致，期望10個，實際$created_count個"
        fi
    }
    
    test_concurrent_order_consistency
}

# 生成完整性測試報告
generate_integrity_report() {
    log_info "=== 資料完整性測試報告 ==="
    
    local success_rate=$(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)
    
    echo -e "${CYAN}總測試數:${NC} $TOTAL_TESTS"
    echo -e "${GREEN}通過:${NC} $PASSED_TESTS"
    echo -e "${RED}失敗:${NC} $FAILED_TESTS"
    echo -e "${CYAN}完整性率:${NC} ${success_rate}%"
    
    # 檢查資料庫整體狀態
    echo -e "\n${BLUE}資料庫狀態總覽:${NC}"
    echo "Order狀態: $(db_query "SELECT COUNT(*) FROM MatchWagers WHERE State = 'Order'")"
    echo "Matching狀態: $(db_query "SELECT COUNT(*) FROM MatchWagers WHERE State = 'Matching'")"
    echo "Success狀態: $(db_query "SELECT COUNT(*) FROM MatchWagers WHERE State = 'Success'")"
    echo "Cancel狀態: $(db_query "SELECT COUNT(*) FROM MatchWagers WHERE State = 'Cancel'")"
    echo "Rejected狀態: $(db_query "SELECT COUNT(*) FROM MatchWagers WHERE State = 'Rejected'")"
    echo "總日誌記錄: $(db_query "SELECT COUNT(*) FROM MatchLogs")"
}

# 主執行函數
main() {
    log_info "開始執行資料完整性測試套件..."
    
    # 檢查依賴
    if ! command -v bc &> /dev/null; then
        log_error "需要安裝 bc 工具"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "需要安裝 jq 工具"
        exit 1
    fi
    
    # 檢查API服務
    if ! curl -s "$API_URL/api/getwagerslist" -X POST -H "Content-Type: application/json" \
        -d '{"Date_S":"2025-01-01","Date_E":"2025-12-31","State":"All","Page":1,"Limit":1}' > /dev/null; then
        log_error "API服務未運行: $API_URL"
        exit 1
    fi
    
    # 執行所有完整性測試
    test_state_transitions
    test_log_integrity
    test_data_relationships
    test_acid_properties
    test_concurrent_consistency
    
    # 生成報告
    generate_integrity_report
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "所有資料完整性測試通過！"
        exit 0
    else
        log_error "發現 $FAILED_TESTS 個資料完整性問題"
        exit 1
    fi
}

# 執行主函數
main "$@" 