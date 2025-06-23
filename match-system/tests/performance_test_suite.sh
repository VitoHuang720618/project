#!/bin/bash
# 性能測試套件

set -e

API_URL="http://localhost:8080"
DB_CONTAINER="725a3bb4abc7"
DB_USER="root"
DB_PASS="root1234"
DB_NAME="match_system"

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

# 資料庫操作
db_query() {
    docker exec "$DB_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -sN -e "$1" 2>/dev/null
}

db_exec() {
    docker exec "$DB_CONTAINER" mysql -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "$1" 2>/dev/null
}

# 性能測試結果記錄
declare -a performance_results=()

record_performance() {
    local test_name="$1"
    local duration="$2"
    local requests="$3"
    local rps=$(echo "scale=2; $requests / $duration" | bc)
    
    echo -e "${CYAN}$test_name${NC}: ${duration}s, ${requests}請求, ${rps} RPS"
    performance_results+=("$test_name|$duration|$requests|$rps")
}

# 並發Order測試
test_concurrent_orders() {
    log_info "=== 並發Order性能測試 ==="
    
    local concurrent_levels=(5 10 20)
    
    for level in "${concurrent_levels[@]}"; do
        log_info "測試 $level 個並發Order請求..."
        
        local start_time=$(date +%s.%N)
        local pids=()
        local success_count=0
        
        # 清理之前的結果檔案
        rm -f /tmp/perf_order_*.result
        
        # 發送並發請求
        for i in $(seq 1 $level); do
            {
                local response=$(curl -s -w "%{http_code}" -X POST "$API_URL/api/order" \
                    -H "Content-Type: application/json" \
                    -d "{\"WD_ID\":$((60000+i)),\"WD_Amount\":1000,\"WD_Account\":\"123456789012345\"}" \
                    2>/dev/null || echo "000")
                echo "$response" > /tmp/perf_order_$i.result
            } &
            pids+=($!)
        done
        
        # 等待所有請求完成
        for pid in "${pids[@]}"; do
            wait $pid
        done
        
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        
        # 統計成功請求數
        for i in $(seq 1 $level); do
            if [ -f "/tmp/perf_order_$i.result" ]; then
                local response=$(cat "/tmp/perf_order_$i.result")
                local http_code="${response: -3}"
                if [ "$http_code" = "200" ]; then
                    success_count=$((success_count + 1))
                fi
            fi
        done
        
        record_performance "並發Order($level)" "$duration" "$success_count"
        
        # 清理
        rm -f /tmp/perf_order_*.result
        
        # 短暫休息避免系統過載
        sleep 2
    done
}

# 查詢性能測試
test_query_performance() {
    log_info "=== 查詢性能測試 ==="
    
    local query_limits=(10 50 100)
    
    for limit in "${query_limits[@]}"; do
        log_info "測試查詢 $limit 筆資料..."
        
        local start_time=$(date +%s.%N)
        
        local response=$(curl -s -X POST "$API_URL/api/getwagerslist" \
            -H "Content-Type: application/json" \
            -d "{\"Date_S\":\"2025-01-01\",\"Date_E\":\"2025-12-31\",\"State\":\"All\",\"Page\":1,\"Limit\":$limit}")
        
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        
        # 檢查是否成功
        local success=$(echo "$response" | jq -r '.Success // "0"' 2>/dev/null)
        if [ "$success" = "1" ]; then
            record_performance "查詢${limit}筆" "$duration" "1"
        else
            log_error "查詢 $limit 筆資料失敗"
        fi
        
        sleep 1
    done
}

# 混合負載測試
test_mixed_workload() {
    log_info "=== 混合負載測試 ==="
    
    log_info "執行混合API請求..."
    local start_time=$(date +%s.%N)
    local pids=()
    local total_requests=0
    
    # 模擬真實使用場景：多種API混合使用
    for i in {1..10}; do
        # Order請求
        {
            curl -s -X POST "$API_URL/api/order" \
                -H "Content-Type: application/json" \
                -d "{\"WD_ID\":$((80000+i)),\"WD_Amount\":$((1000 + i*100)),\"WD_Account\":\"123456789012345\"}" \
                > /tmp/mixed_order_$i.result 2>/dev/null
        } &
        pids+=($!)
        total_requests=$((total_requests + 1))
        
        # 查詢請求
        {
            curl -s -X POST "$API_URL/api/getwagerslist" \
                -H "Content-Type: application/json" \
                -d '{"Date_S":"2025-01-01","Date_E":"2025-12-31","State":"All","Page":1,"Limit":10}' \
                > /tmp/mixed_query_$i.result 2>/dev/null
        } &
        pids+=($!)
        total_requests=$((total_requests + 1))
    done
    
    # 等待所有請求完成
    for pid in "${pids[@]}"; do
        wait $pid
    done
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)
    
    record_performance "混合負載" "$duration" "$total_requests"
    
    # 清理
    rm -f /tmp/mixed_*.result
}

# 生成性能報告
generate_performance_report() {
    log_info "=== 性能測試報告 ==="
    
    echo -e "\n${BLUE}詳細性能指標:${NC}"
    printf "%-25s %-10s %-10s %-10s\n" "測試項目" "耗時(s)" "請求數" "RPS"
    printf "%-25s %-10s %-10s %-10s\n" "--------" "------" "-----" "---"
    
    for result in "${performance_results[@]}"; do
        IFS='|' read -r name duration requests rps <<< "$result"
        printf "%-25s %-10s %-10s %-10s\n" "$name" "$duration" "$requests" "$rps"
    done
    
    # 生成HTML報告
    local report_file="performance_report_$(date +%Y%m%d_%H%M%S).html"
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>撮合系統性能測試報告</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .metric { margin: 5px 0; }
    </style>
</head>
<body>
    <h1>撮合系統性能測試報告</h1>
    <div class="summary">
        <h2>測試總結</h2>
        <div class="metric">執行時間: $(date)</div>
        <div class="metric">測試項目數: ${#performance_results[@]}</div>
    </div>
    
    <h2>性能指標</h2>
    <table>
        <tr><th>測試項目</th><th>耗時(秒)</th><th>請求數</th><th>RPS</th></tr>
EOF
    
    for result in "${performance_results[@]}"; do
        IFS='|' read -r name duration requests rps <<< "$result"
        echo "        <tr><td>$name</td><td>$duration</td><td>$requests</td><td>$rps</td></tr>" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF
    </table>
</body>
</html>
EOF
    
    log_success "性能測試HTML報告已生成: $report_file"
}

# 主執行函數
main() {
    log_info "開始執行性能測試套件..."
    
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
    
    log_info "API地址: $API_URL"
    
    # 執行性能測試
    test_concurrent_orders
    test_query_performance
    test_mixed_workload
    
    # 生成報告
    generate_performance_report
    
    log_success "性能測試完成！"
}

# 執行主函數
main "$@" 