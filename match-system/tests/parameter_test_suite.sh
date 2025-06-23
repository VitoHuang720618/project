#!/bin/bash

# API參數驗證測試套件
# 覆蓋所有8個API的參數驗證情境

# 全域變數設定
API_BASE_URL="http://localhost:8080/api"
TEST_RESULTS_FILE="parameter_test_results_$(date +%Y%m%d_%H%M%S).json"
FAILED_TESTS_COUNT=0
TOTAL_TESTS_COUNT=0
TEST_RESULTS=()

# 顏色輸出設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 記錄測試結果
log_test_result() {
    local test_name="$1"
    local api_endpoint="$2"
    local request_data="$3"
    local expected_success="$4"
    local expected_error_code="$5"
    local actual_response="$6"
    local test_status="$7"
    local error_message="$8"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local result=$(cat << EOF
{
    "timestamp": "$timestamp",
    "test_name": "$test_name",
    "api_endpoint": "$api_endpoint",
    "request_data": $request_data,
    "expected_success": $expected_success,
    "expected_error_code": "$expected_error_code",
    "actual_response": $actual_response,
    "test_status": "$test_status",
    "error_message": "$error_message"
}
EOF
    )
    
    TEST_RESULTS+=("$result")
}

# 通用API測試函數
test_api_call() {
    local test_name="$1"
    local endpoint="$2"
    local method="$3"
    local data="$4"
    local expected_success="$5"
    local expected_error_code="$6"
    
    TOTAL_TESTS_COUNT=$((TOTAL_TESTS_COUNT + 1))
    
    echo -e "${BLUE}測試 $TOTAL_TESTS_COUNT: $test_name${NC}"
    echo "  端點: $endpoint"
    echo "  請求: $data"
    
    # 執行API調用
    local response
    if [[ "$method" == "POST" ]]; then
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$API_BASE_URL/$endpoint" 2>/dev/null)
    elif [[ "$method" == "GET" ]]; then
        response=$(curl -s -X GET \
            "$API_BASE_URL/$endpoint" 2>/dev/null)
    fi
    
    # 檢查curl是否成功執行
    if [[ $? -ne 0 ]] || [[ -z "$response" ]]; then
        echo -e "  ${RED}✗ API調用失敗${NC}"
        FAILED_TESTS_COUNT=$((FAILED_TESTS_COUNT + 1))
        log_test_result "$test_name" "$endpoint" "$data" "$expected_success" "$expected_error_code" "null" "FAILED" "API調用失敗"
        return 1
    fi
    
    echo "  響應: $response"
    
    # 驗證響應格式
    if ! validate_response_format "$response" "$expected_success" "$expected_error_code" "$endpoint"; then
        echo -e "  ${RED}✗ 響應格式驗證失敗${NC}"
        FAILED_TESTS_COUNT=$((FAILED_TESTS_COUNT + 1))
        log_test_result "$test_name" "$endpoint" "$data" "$expected_success" "$expected_error_code" "$response" "FAILED" "響應格式驗證失敗"
        return 1
    fi
    
    echo -e "  ${GREEN}✓ 測試通過${NC}"
    log_test_result "$test_name" "$endpoint" "$data" "$expected_success" "$expected_error_code" "$response" "PASSED" ""
    return 0
}

# 響應格式驗證器
validate_response_format() {
    local response="$1"
    local expected_success="$2"
    local expected_error_code="$3"
    local api_name="$4"
    
    # 檢查是否為有效JSON
    if ! echo "$response" | jq . >/dev/null 2>&1; then
        echo "    錯誤: 響應不是有效的JSON格式"
        return 1
    fi
    
    # 解析JSON響應
    local success=$(echo "$response" | jq -r '.Success // empty')
    local runtime=$(echo "$response" | jq -r '.RunTime // empty')
    local error_code=$(echo "$response" | jq -r '.ErrCode // empty')
    
    # 驗證Success欄位
    if [[ "$success" != "$expected_success" ]]; then
        echo "    錯誤: Success欄位不符 - 預期:$expected_success, 實際:$success"
        return 1
    fi
    
    # 驗證RunTime是否為整數
    if [[ -n "$runtime" ]] && ! [[ "$runtime" =~ ^[0-9]+$ ]]; then
        echo "    錯誤: RunTime欄位不是整數 - 實際:$runtime"
        return 1
    fi
    
    # 驗證錯誤碼
    if [[ "$expected_success" == "0" ]] && [[ -n "$expected_error_code" ]]; then
        if [[ "$error_code" != "$expected_error_code" ]]; then
            echo "    錯誤: 錯誤碼不符 - 預期:$expected_error_code, 實際:$error_code"
            return 1
        fi
    fi
    
    # 根據API類型驗證特定欄位
    validate_api_specific_fields "$response" "$api_name" "$expected_success"
    
    return 0
}

# API特定欄位驗證
validate_api_specific_fields() {
    local response="$1"
    local api_name="$2"
    local expected_success="$3"
    
    if [[ "$expected_success" == "1" ]]; then
        case "$api_name" in
            "order")
                # 驗證order API的特定欄位
                local wid=$(echo "$response" | jq -r '.Data.WID // empty')
                local wd_id=$(echo "$response" | jq -r '.Data.WD_ID // empty')
                local wd_amount=$(echo "$response" | jq -r '.Data.WD_Amount // empty')
                local wd_account=$(echo "$response" | jq -r '.Data.WD_Account // empty')
                local wd_datetime=$(echo "$response" | jq -r '.Data.WD_Datetime // empty')
                
                if [[ -z "$wid" ]] || [[ -z "$wd_id" ]] || [[ -z "$wd_amount" ]] || [[ -z "$wd_account" ]] || [[ -z "$wd_datetime" ]]; then
                    echo "    錯誤: order API響應缺少必要欄位"
                    return 1
                fi
                ;;
            "reserve")
                # 驗證reserve API的特定欄位
                local wid=$(echo "$response" | jq -r '.Data.WID // empty')
                local wd_id=$(echo "$response" | jq -r '.Data.WD_ID // empty')
                local wd_amount=$(echo "$response" | jq -r '.Data.WD_Amount // empty')
                local wd_account=$(echo "$response" | jq -r '.Data.WD_Account // empty')
                
                if [[ -z "$wid" ]] || [[ -z "$wd_id" ]] || [[ -z "$wd_amount" ]] || [[ -z "$wd_account" ]]; then
                    echo "    錯誤: reserve API響應缺少必要欄位"
                    return 1
                fi
                ;;
            "success")
                # 驗證success API的特定欄位
                local wid=$(echo "$response" | jq -r '.Data.WID // empty')
                local finish_datetime=$(echo "$response" | jq -r '.Data.Finish_DateTime // empty')
                
                if [[ -z "$wid" ]] || [[ -z "$finish_datetime" ]]; then
                    echo "    錯誤: success API響應缺少必要欄位"
                    return 1
                fi
                ;;
            "cancel"|"rejected")
                # 驗證cancel/rejected API的特定欄位
                local wid=$(echo "$response" | jq -r '.Data.WID // empty')
                
                if [[ -z "$wid" ]]; then
                    echo "    錯誤: $api_name API響應缺少必要欄位"
                    return 1
                fi
                ;;
            "getwagerslist"|"getrejectedlist"|"getmatchinglist")
                # 驗證查詢API的特定欄位
                local data=$(echo "$response" | jq -r '.Data // empty')
                
                if [[ -z "$data" ]]; then
                    echo "    錯誤: $api_name API響應缺少Data欄位"
                    return 1
                fi
                ;;
        esac
    fi
    
    return 0
}

# 測試環境準備
setup_test_environment() {
    echo -e "${YELLOW}準備測試環境...${NC}"
    
    # 檢查API服務是否運行
    if ! curl -s "$API_BASE_URL/health" >/dev/null 2>&1; then
        echo -e "${RED}警告: API服務可能未運行，測試可能會失敗${NC}"
    fi
    
    # 檢查必要工具
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${RED}錯誤: 需要安裝jq工具來解析JSON響應${NC}"
        exit 1
    fi
    
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}錯誤: 需要安裝curl工具來執行API調用${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}測試環境準備完成${NC}"
}

# 清理測試環境
cleanup_test_environment() {
    echo -e "${YELLOW}清理測試環境...${NC}"
    # 可以在這裡添加清理邏輯
    echo -e "${GREEN}測試環境清理完成${NC}"
}

# 生成測試報告
generate_test_summary() {
    echo ""
    echo "=================================="
    echo "API參數驗證測試結果摘要"
    echo "=================================="
    echo "總測試數: $TOTAL_TESTS_COUNT"
    echo "通過測試: $((TOTAL_TESTS_COUNT - FAILED_TESTS_COUNT))"
    echo "失敗測試: $FAILED_TESTS_COUNT"
    
    if [[ $TOTAL_TESTS_COUNT -gt 0 ]]; then
        local pass_rate=$(( (TOTAL_TESTS_COUNT - FAILED_TESTS_COUNT) * 100 / TOTAL_TESTS_COUNT ))
        echo "通過率: $pass_rate%"
    fi
    
    if [[ $FAILED_TESTS_COUNT -gt 0 ]]; then
        echo -e "${RED}測試失敗，請檢查詳細日誌${NC}"
        return 1
    else
        echo -e "${GREEN}所有測試通過！${NC}"
        return 0
    fi
}

# 保存測試結果到JSON檔案
save_test_results() {
    local results_json="["
    local first=true
    
    for result in "${TEST_RESULTS[@]}"; do
        if [[ "$first" == true ]]; then
            first=false
        else
            results_json+=","
        fi
        results_json+="$result"
    done
    
    results_json+="]"
    
    echo "$results_json" | jq '.' > "$TEST_RESULTS_FILE"
    echo "測試結果已保存到: $TEST_RESULTS_FILE"
}

# 主要測試執行函數
run_parameter_tests() {
    echo -e "${BLUE}開始執行API參數驗證測試${NC}"
    echo "=================================="
    
    setup_test_environment
    
    # 執行各API的參數測試
    test_order_api_parameters
    test_reserve_api_parameters  
    test_success_api_parameters
    test_cancel_rejected_api_parameters
    test_getwagerslist_api_parameters
    test_query_apis_parameters
    test_boundary_values
    
    cleanup_test_environment
    
    generate_test_summary
    save_test_results
    
    return $?
}

# 如果直接執行此腳本，則運行主要測試函數
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_parameter_tests
fi 