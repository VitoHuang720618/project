#!/bin/bash

# /api/order API參數驗證測試
# 覆蓋錯誤碼 10001-10005

# 測試/api/order API的所有參數驗證情境
test_order_api_parameters() {
    echo ""
    echo "=================================="
    echo "測試 /api/order API 參數驗證"
    echo "=================================="
    
    # 測試WD_ID參數錯誤 (10001)
    echo "--- 測試WD_ID參數錯誤 (10001) ---"
    
    # WD_ID為空
    test_api_call "WD_ID為空" "order" "POST" \
        '{"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        0 "10001"
    
    # WD_ID為字符串
    test_api_call "WD_ID為字符串" "order" "POST" \
        '{"WD_ID":"abc","WD_Amount":1000,"WD_Account":"123456789012345"}' \
        0 "10001"
    
    # WD_ID為浮點數
    test_api_call "WD_ID為浮點數" "order" "POST" \
        '{"WD_ID":123.45,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        0 "10001"
    
    # WD_ID為負數
    test_api_call "WD_ID為負數" "order" "POST" \
        '{"WD_ID":-123,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        0 "10001"
    
    # WD_ID為null
    test_api_call "WD_ID為null" "order" "POST" \
        '{"WD_ID":null,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        0 "10001"
    
    # WD_ID為布林值
    test_api_call "WD_ID為布林值" "order" "POST" \
        '{"WD_ID":true,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        0 "10001"
    
    # 測試WD_Amount參數錯誤 (10002)
    echo "--- 測試WD_Amount參數錯誤 (10002) ---"
    
    # WD_Amount為空
    test_api_call "WD_Amount為空" "order" "POST" \
        '{"WD_ID":123,"WD_Account":"123456789012345"}' \
        0 "10002"
    
    # WD_Amount為字符串
    test_api_call "WD_Amount為字符串" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":"abc","WD_Account":"123456789012345"}' \
        0 "10002"
    
    # WD_Amount為浮點數
    test_api_call "WD_Amount為浮點數" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000.5,"WD_Account":"123456789012345"}' \
        0 "10002"
    
    # WD_Amount為負數
    test_api_call "WD_Amount為負數" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":-1000,"WD_Account":"123456789012345"}' \
        0 "10002"
    
    # WD_Amount為null
    test_api_call "WD_Amount為null" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":null,"WD_Account":"123456789012345"}' \
        0 "10002"
    
    # WD_Amount為布林值
    test_api_call "WD_Amount為布林值" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":true,"WD_Account":"123456789012345"}' \
        0 "10002"
    
    # 測試WD_Account參數錯誤 (10003)
    echo "--- 測試WD_Account參數錯誤 (10003) ---"
    
    # WD_Account為空
    test_api_call "WD_Account為空" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000}' \
        0 "10003"
    
    # WD_Account為數字
    test_api_call "WD_Account為數字" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":123456789012345}' \
        0 "10003"
    
    # WD_Account為空字符串
    test_api_call "WD_Account為空字符串" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":""}' \
        0 "10003"
    
    # WD_Account為null
    test_api_call "WD_Account為null" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":null}' \
        0 "10003"
    
    # WD_Account為布林值
    test_api_call "WD_Account為布林值" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":true}' \
        0 "10003"
    
    # 測試WD_Account參數不合法 (10004)
    echo "--- 測試WD_Account參數不合法 (10004) ---"
    
    # WD_Account太短
    test_api_call "WD_Account太短" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"12345"}' \
        0 "10004"
    
    # WD_Account太長
    test_api_call "WD_Account太長" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"1234567890123456"}' \
        0 "10004"
    
    # WD_Account包含非數字字符
    test_api_call "WD_Account包含非數字字符" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"12345abc7890123"}' \
        0 "10004"
    
    # WD_Account包含特殊字符
    test_api_call "WD_Account包含特殊字符" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"12345-67890123"}' \
        0 "10004"
    
    # WD_Account包含空格
    test_api_call "WD_Account包含空格" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"12345 67890123"}' \
        0 "10004"
    
    # 測試WD_Amount金額不符合規定 (10005)
    echo "--- 測試WD_Amount金額不符合規定 (10005) ---"
    
    # WD_Amount為999
    test_api_call "WD_Amount為999" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":999,"WD_Account":"123456789012345"}' \
        0 "10005"
    
    # WD_Amount為1001
    test_api_call "WD_Amount為1001" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1001,"WD_Account":"123456789012345"}' \
        0 "10005"
    
    # WD_Amount為0
    test_api_call "WD_Amount為0" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":0,"WD_Account":"123456789012345"}' \
        0 "10005"
    
    # WD_Amount為2000
    test_api_call "WD_Amount為2000" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":2000,"WD_Account":"123456789012345"}' \
        0 "10005"
    
    # WD_Amount為3000
    test_api_call "WD_Amount為3000" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":3000,"WD_Account":"123456789012345"}' \
        0 "10005"
    
    # WD_Amount為50000
    test_api_call "WD_Amount為50000" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":50000,"WD_Account":"123456789012345"}' \
        0 "10005"
    
    # 測試成功情境
    echo "--- 測試成功情境 ---"
    
    # 有效的1000金額
    test_api_call "有效的1000金額" "order" "POST" \
        '{"WD_ID":1001,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    # 有效的5000金額
    test_api_call "有效的5000金額" "order" "POST" \
        '{"WD_ID":1002,"WD_Amount":5000,"WD_Account":"987654321098765"}' \
        1 ""
    
    # 有效的10000金額
    test_api_call "有效的10000金額" "order" "POST" \
        '{"WD_ID":1003,"WD_Amount":10000,"WD_Account":"111222333444555"}' \
        1 ""
    
    # 有效的20000金額
    test_api_call "有效的20000金額" "order" "POST" \
        '{"WD_ID":1004,"WD_Amount":20000,"WD_Account":"555444333222111"}' \
        1 ""
    
    # 測試邊界值
    echo "--- 測試邊界值 ---"
    
    # 最小有效WD_ID
    test_api_call "最小有效WD_ID" "order" "POST" \
        '{"WD_ID":1,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    # 最大有效WD_ID (32位整數)
    test_api_call "最大有效WD_ID" "order" "POST" \
        '{"WD_ID":2147483647,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    # 15位數字帳戶
    test_api_call "15位數字帳戶" "order" "POST" \
        '{"WD_ID":1005,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    # 測試額外參數
    echo "--- 測試額外參數 ---"
    
    # 包含額外參數但有效
    test_api_call "包含額外參數但有效" "order" "POST" \
        '{"WD_ID":1006,"WD_Amount":1000,"WD_Account":"123456789012345","extra_param":"value"}' \
        1 ""
    
    # 測試JSON格式錯誤
    echo "--- 測試JSON格式錯誤 ---"
    
    # 無效JSON格式
    test_api_call "無效JSON格式" "order" "POST" \
        '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"123456789012345"' \
        0 ""
    
    # 空JSON
    test_api_call "空JSON" "order" "POST" \
        '{}' \
        0 "10001"
    
    echo "=== /api/order API參數驗證測試完成 ==="
}

# 如果直接執行此腳本，則載入主測試套件並執行order測試
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 載入主測試套件
    source "$(dirname "$0")/../parameter_test_suite.sh"
    
    # 執行order API測試
    setup_test_environment
    test_order_api_parameters
    cleanup_test_environment
    generate_test_summary
    save_test_results
fi 