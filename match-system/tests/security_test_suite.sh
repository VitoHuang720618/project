#!/bin/bash
# 安全性測試套件

set -e

API_URL="http://localhost:8080"
DB_CONTAINER="725a3bb4abc7"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }

# 安全測試函數
test_security_api() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    local response=$(curl -s -w "%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$API_URL$endpoint" 2>/dev/null || echo "000")
    local http_code="${response: -3}"
    local response_body="${response%???}"
    
    # 安全測試應該返回400或拒絕請求
    if [[ "$http_code" == "400" || "$http_code" == "200" ]]; then
        # 檢查是否正確拒絕了惡意請求
        local success_value=$(echo "$response_body" | jq -r '.Success // "null"' 2>/dev/null)
        if [ "$success_value" = "0" ] || [ "$http_code" = "400" ]; then
            log_success "$test_name - 正確拒絕惡意請求"
            PASSED_TESTS=$((PASSED_TESTS + 1))
            return 0
        fi
    fi
    
    log_error "$test_name - 安全檢查失敗 (HTTP: $http_code)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    return 1
}

# SQL注入測試
test_sql_injection() {
    log_info "=== SQL注入防護測試 ==="
    
    # 各種SQL注入攻擊模式
    local injection_payloads=(
        "'; DROP TABLE MatchWagers; --"
        "1' OR '1'='1"
        "1; UPDATE MatchWagers SET State='Hacked'; --"
        "1 UNION SELECT * FROM MatchWagers --"
        "1'; INSERT INTO MatchWagers VALUES(999999); --"
        "' OR 1=1 --"
        "admin'--"
        "admin' OR '1'='1"
    )
    
    for payload in "${injection_payloads[@]}"; do
        test_security_api "SQL注入測試: ${payload:0:20}..." "POST" "/api/order" \
            "{\"WD_ID\":\"$payload\",\"WD_Amount\":1000,\"WD_Account\":\"123456789012345\"}"
    done
    
    # 測試其他參數的SQL注入
    test_security_api "Account SQL注入" "POST" "/api/order" \
        '{"WD_ID":1001,"WD_Amount":1000,"WD_Account":"123'\''OR 1=1--"}'
    
    test_security_api "Reserve UserID SQL注入" "POST" "/api/reserve" \
        '{"Reserve_UserID":"1001'\'' OR 1=1--","Reserve_Amount":1000}'
}

# XSS攻擊測試
test_xss_protection() {
    log_info "=== XSS攻擊防護測試 ==="
    
    local xss_payloads=(
        "<script>alert('XSS')</script>"
        "javascript:alert('XSS')"
        "<img src=x onerror=alert('XSS')>"
        "<svg onload=alert('XSS')>"
        "'\"><script>alert('XSS')</script>"
    )
    
    for payload in "${xss_payloads[@]}"; do
        test_security_api "XSS測試: ${payload:0:20}..." "POST" "/api/order" \
            "{\"WD_ID\":1001,\"WD_Amount\":1000,\"WD_Account\":\"$payload\"}"
    done
}

# 參數篡改測試
test_parameter_tampering() {
    log_info "=== 參數篡改防護測試 ==="
    
    # 超大數值測試
    test_security_api "超大WD_ID" "POST" "/api/order" \
        '{"WD_ID":999999999999999999999,"WD_Amount":1000,"WD_Account":"123456789012345"}'
    
    test_security_api "超大金額" "POST" "/api/order" \
        '{"WD_ID":1001,"WD_Amount":999999999999,"WD_Account":"123456789012345"}'
    
    # 負數測試
    test_security_api "負數WD_ID" "POST" "/api/order" \
        '{"WD_ID":-1,"WD_Amount":1000,"WD_Account":"123456789012345"}'
    
    test_security_api "負數金額" "POST" "/api/order" \
        '{"WD_ID":1001,"WD_Amount":-1000,"WD_Account":"123456789012345"}'
    
    # 浮點數測試（應該被拒絕）
    test_security_api "浮點數WD_ID" "POST" "/api/order" \
        '{"WD_ID":1001.5,"WD_Amount":1000,"WD_Account":"123456789012345"}'
    
    # 空值和null測試
    test_security_api "Null WD_ID" "POST" "/api/order" \
        '{"WD_ID":null,"WD_Amount":1000,"WD_Account":"123456789012345"}'
    
    test_security_api "空字串WD_ID" "POST" "/api/order" \
        '{"WD_ID":"","WD_Amount":1000,"WD_Account":"123456789012345"}'
}

# 輸入長度測試
test_input_length() {
    log_info "=== 輸入長度限制測試 ==="
    
    # 超長帳戶號碼
    local long_account=$(printf 'A%.0s' {1..1000})
    test_security_api "超長帳戶號碼" "POST" "/api/order" \
        "{\"WD_ID\":1001,\"WD_Amount\":1000,\"WD_Account\":\"$long_account\"}"
    
    # 超長JSON
    local long_json='{"WD_ID":1001,"WD_Amount":1000,"WD_Account":"123456789012345","extra":"'
    long_json+=$(printf 'X%.0s' {1..10000})
    long_json+='"}'
    
    test_security_api "超長JSON" "POST" "/api/order" "$long_json"
}

# 特殊字符測試
test_special_characters() {
    log_info "=== 特殊字符處理測試 ==="
    
    local special_chars=(
        "'\"\\\n\r\t"
        "!@#$%^&*()_+-=[]{}|;:,.<>?"
        "中文測試"
        "🚀🔥💯"
        "\u0000\u0001\u0002"
    )
    
    for chars in "${special_chars[@]}"; do
        test_security_api "特殊字符: ${chars:0:10}..." "POST" "/api/order" \
            "{\"WD_ID\":1001,\"WD_Amount\":1000,\"WD_Account\":\"$chars\"}"
    done
}

# HTTP方法測試
test_http_methods() {
    log_info "=== HTTP方法安全測試 ==="
    
    # 測試不支援的HTTP方法
    for method in "DELETE" "PUT" "PATCH" "HEAD" "OPTIONS"; do
        local response=$(curl -s -w "%{http_code}" -X "$method" "$API_URL/api/order" 2>/dev/null || echo "000")
        local http_code="${response: -3}"
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        if [[ "$http_code" == "405" || "$http_code" == "404" ]]; then
            log_success "$method 方法正確被拒絕"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            log_error "$method 方法未被正確拒絕 (HTTP: $http_code)"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    done
}

# 併發攻擊測試
test_concurrent_attacks() {
    log_info "=== 併發攻擊測試 ==="
    
    log_info "執行併發惡意請求..."
    local pids=()
    
    # 同時發送多個惡意請求
    for i in {1..10}; do
        {
            curl -s -X POST "$API_URL/api/order" \
                -H "Content-Type: application/json" \
                -d "{\"WD_ID\":\"'; DROP TABLE MatchWagers; --\",\"WD_Amount\":1000,\"WD_Account\":\"123456789012345\"}" \
                > /tmp/attack_$i.result 2>/dev/null
        } &
        pids+=($!)
    done
    
    # 等待所有請求完成
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    # 檢查系統是否仍然正常
    local health_check=$(curl -s -X POST "$API_URL/api/getwagerslist" \
        -H "Content-Type: application/json" \
        -d '{"Date_S":"2025-01-01","Date_E":"2025-12-31","State":"All","Page":1,"Limit":1}' 2>/dev/null)
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if echo "$health_check" | jq -e '.Success' > /dev/null 2>&1; then
        log_success "系統在併發攻擊後仍正常運行"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        log_error "系統在併發攻擊後可能受損"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    # 清理
    rm -f /tmp/attack_*.result
}

# 主執行函數
main() {
    log_info "開始執行安全性測試套件..."
    
    # 檢查API服務
    if ! curl -s "$API_URL/api/getwagerslist" -X POST -H "Content-Type: application/json" \
        -d '{"Date_S":"2025-01-01","Date_E":"2025-12-31","State":"All","Page":1,"Limit":1}' > /dev/null; then
        log_error "API服務未運行: $API_URL"
        exit 1
    fi
    
    # 執行所有安全測試
    test_sql_injection
    test_xss_protection
    test_parameter_tampering
    test_input_length
    test_special_characters
    test_http_methods
    test_concurrent_attacks
    
    # 生成報告
    log_info "=== 安全測試報告 ==="
    echo -e "${BLUE}總測試數:${NC} $TOTAL_TESTS"
    echo -e "${GREEN}通過:${NC} $PASSED_TESTS"
    echo -e "${RED}失敗:${NC} $FAILED_TESTS"
    
    local success_rate=$(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)
    echo -e "${BLUE}安全防護率:${NC} ${success_rate}%"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "所有安全測試通過！系統安全防護良好"
        exit 0
    else
        log_error "發現 $FAILED_TESTS 個安全問題，需要檢查"
        exit 1
    fi
}

# 執行主函數
main "$@" 