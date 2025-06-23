#!/bin/bash

# /api/getrejectedlist 和 /api/getmatchinglist API參數驗證測試
# 這些API沒有明確的錯誤碼定義

# 測試查詢API的參數驗證情境
test_query_apis_parameters() {
    echo ""
    echo "=================================="
    echo "測試查詢API參數驗證"
    echo "=================================="
    
    for endpoint in "getrejectedlist" "getmatchinglist"; do
        echo ""
        echo "--- 測試 /api/$endpoint API ---"
        
        # 測試正常情況
        echo "--- 測試正常情況 ---"
        
        # 空JSON請求
        test_api_call "[$endpoint] 空JSON請求" "$endpoint" "POST" \
            '{}' \
            1 ""
        
        # 測試HTTP方法錯誤
        echo "--- 測試HTTP方法錯誤 ---"
        
        # 使用GET方法
        test_api_call "[$endpoint] 使用GET方法" "$endpoint" "GET" \
            '' \
            0 ""
        
        # 測試JSON格式錯誤
        echo "--- 測試JSON格式錯誤 ---"
        
        # 無效JSON格式
        test_api_call "[$endpoint] 無效JSON格式" "$endpoint" "POST" \
            '{invalid json' \
            0 ""
        
        # 非JSON格式
        test_api_call "[$endpoint] 非JSON格式" "$endpoint" "POST" \
            'not json at all' \
            0 ""
        
        # 測試額外參數
        echo "--- 測試額外參數 ---"
        
        # 包含無關參數
        test_api_call "[$endpoint] 包含無關參數" "$endpoint" "POST" \
            '{"invalid_param":"value","another_param":123}' \
            1 ""
        
        # 包含null值參數
        test_api_call "[$endpoint] 包含null值參數" "$endpoint" "POST" \
            '{"param1":null,"param2":"value"}' \
            1 ""
        
        # 包含各種類型參數
        test_api_call "[$endpoint] 包含各種類型參數" "$endpoint" "POST" \
            '{"string_param":"test","number_param":123,"boolean_param":true,"array_param":[1,2,3],"object_param":{"key":"value"}}' \
            1 ""
        
        # 測試Content-Type錯誤
        echo "--- 測試Content-Type錯誤 ---"
        
        # 測試不同的Content-Type（需要修改curl命令）
        # 這裡我們測試一些邊界情況
        
        # 測試空請求體
        test_api_call "[$endpoint] 空請求體" "$endpoint" "POST" \
            '' \
            0 ""
        
        # 測試特殊字符
        echo "--- 測試特殊字符 ---"
        
        # 包含特殊字符的參數
        test_api_call "[$endpoint] 包含特殊字符" "$endpoint" "POST" \
            '{"special_chars":"!@#$%^&*()_+-=[]{}|;:,.<>?","unicode":"測試中文字符"}' \
            1 ""
        
        # 測試超長參數
        echo "--- 測試超長參數 ---"
        
        # 超長字符串參數
        local long_string=$(printf 'a%.0s' {1..1000})
        test_api_call "[$endpoint] 超長字符串參數" "$endpoint" "POST" \
            "{\"long_param\":\"$long_string\"}" \
            1 ""
        
        # 測試深層嵌套JSON
        echo "--- 測試深層嵌套JSON ---"
        
        # 深層嵌套對象
        test_api_call "[$endpoint] 深層嵌套對象" "$endpoint" "POST" \
            '{"level1":{"level2":{"level3":{"level4":{"level5":"deep_value"}}}}}' \
            1 ""
        
        # 大型數組
        test_api_call "[$endpoint] 大型數組" "$endpoint" "POST" \
            '{"large_array":[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]}' \
            1 ""
    done
    
    # 測試API特定功能
    echo ""
    echo "--- 測試API特定功能 ---"
    
    # 為了更好地測試這些API，我們需要先建立一些測試數據
    echo "建立測試數據..."
    
    # 建立一些Order
    test_api_call "建立測試Order-5001" "order" "POST" \
        '{"WD_ID":5001,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    test_api_call "建立測試Order-5002" "order" "POST" \
        '{"WD_ID":5002,"WD_Amount":5000,"WD_Account":"987654321098765"}' \
        1 ""
    
    sleep 1
    
    # 撮合一些Order成為Matching狀態
    test_api_call "撮合測試Order-4001" "reserve" "POST" \
        '{"Reserve_UserID":4001,"Reserve_Amount":1000}' \
        1 ""
    
    sleep 1
    
    # 測試getmatchinglist返回數據格式
    echo "--- 測試getmatchinglist返回數據格式 ---"
    
    test_api_call "getmatchinglist返回數據" "getmatchinglist" "POST" \
        '{}' \
        1 ""
    
    # 測試getrejectedlist返回數據格式
    echo "--- 測試getrejectedlist返回數據格式 ---"
    
    test_api_call "getrejectedlist返回數據" "getrejectedlist" "POST" \
        '{}' \
        1 ""
    
    # 測試併發請求
    echo "--- 測試併發請求 ---"
    
    # 同時發送多個請求
    for i in {1..5}; do
        test_api_call "getmatchinglist併發請求-$i" "getmatchinglist" "POST" \
            '{}' \
            1 "" &
    done
    wait
    
    for i in {1..5}; do
        test_api_call "getrejectedlist併發請求-$i" "getrejectedlist" "POST" \
            '{}' \
            1 "" &
    done
    wait
    
    # 測試響應時間
    echo "--- 測試響應時間 ---"
    
    # 連續請求測試
    for i in {1..3}; do
        test_api_call "getmatchinglist連續請求-$i" "getmatchinglist" "POST" \
            '{}' \
            1 ""
        
        test_api_call "getrejectedlist連續請求-$i" "getrejectedlist" "POST" \
            '{}' \
            1 ""
    done
    
    # 測試不同的JSON結構
    echo "--- 測試不同的JSON結構 ---"
    
    # 數組作為根元素
    test_api_call "getmatchinglist數組根元素" "getmatchinglist" "POST" \
        '[{"key":"value"}]' \
        0 ""
    
    test_api_call "getrejectedlist數組根元素" "getrejectedlist" "POST" \
        '[{"key":"value"}]' \
        0 ""
    
    # 字符串作為根元素
    test_api_call "getmatchinglist字符串根元素" "getmatchinglist" "POST" \
        '"string_value"' \
        0 ""
    
    test_api_call "getrejectedlist字符串根元素" "getrejectedlist" "POST" \
        '"string_value"' \
        0 ""
    
    # 數字作為根元素
    test_api_call "getmatchinglist數字根元素" "getmatchinglist" "POST" \
        '123' \
        0 ""
    
    test_api_call "getrejectedlist數字根元素" "getrejectedlist" "POST" \
        '123' \
        0 ""
    
    # 布林值作為根元素
    test_api_call "getmatchinglist布林值根元素" "getmatchinglist" "POST" \
        'true' \
        0 ""
    
    test_api_call "getrejectedlist布林值根元素" "getrejectedlist" "POST" \
        'false' \
        0 ""
    
    # null作為根元素
    test_api_call "getmatchinglist null根元素" "getmatchinglist" "POST" \
        'null' \
        0 ""
    
    test_api_call "getrejectedlist null根元素" "getrejectedlist" "POST" \
        'null' \
        0 ""
    
    echo "=== 查詢API參數驗證測試完成 ==="
}

# 如果直接執行此腳本，則載入主測試套件並執行查詢API測試
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 載入主測試套件
    source "$(dirname "$0")/../parameter_test_suite.sh"
    
    # 執行查詢API測試
    setup_test_environment
    test_query_apis_parameters
    cleanup_test_environment
    generate_test_summary
    save_test_results
fi 