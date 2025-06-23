#!/bin/bash

# /api/reserve API參數驗證測試
# 覆蓋錯誤碼 10011-10014

# 測試/api/reserve API的所有參數驗證情境
test_reserve_api_parameters() {
    echo ""
    echo "=================================="
    echo "測試 /api/reserve API 參數驗證"
    echo "=================================="
    
    # 測試Reserve_UserID參數錯誤 (10011)
    echo "--- 測試Reserve_UserID參數錯誤 (10011) ---"
    
    # Reserve_UserID為空
    test_api_call "Reserve_UserID為空" "reserve" "POST" \
        '{"Reserve_Amount":1000}' \
        0 "10011"
    
    # Reserve_UserID為字符串
    test_api_call "Reserve_UserID為字符串" "reserve" "POST" \
        '{"Reserve_UserID":"abc","Reserve_Amount":1000}' \
        0 "10011"
    
    # Reserve_UserID為浮點數
    test_api_call "Reserve_UserID為浮點數" "reserve" "POST" \
        '{"Reserve_UserID":123.45,"Reserve_Amount":1000}' \
        0 "10011"
    
    # Reserve_UserID為負數
    test_api_call "Reserve_UserID為負數" "reserve" "POST" \
        '{"Reserve_UserID":-123,"Reserve_Amount":1000}' \
        0 "10011"
    
    # Reserve_UserID為null
    test_api_call "Reserve_UserID為null" "reserve" "POST" \
        '{"Reserve_UserID":null,"Reserve_Amount":1000}' \
        0 "10011"
    
    # Reserve_UserID為布林值
    test_api_call "Reserve_UserID為布林值" "reserve" "POST" \
        '{"Reserve_UserID":true,"Reserve_Amount":1000}' \
        0 "10011"
    
    # Reserve_UserID為0
    test_api_call "Reserve_UserID為0" "reserve" "POST" \
        '{"Reserve_UserID":0,"Reserve_Amount":1000}' \
        0 "10011"
    
    # 測試Reserve_Amount參數錯誤 (10012)
    echo "--- 測試Reserve_Amount參數錯誤 (10012) ---"
    
    # Reserve_Amount為空
    test_api_call "Reserve_Amount為空" "reserve" "POST" \
        '{"Reserve_UserID":123}' \
        0 "10012"
    
    # Reserve_Amount為字符串
    test_api_call "Reserve_Amount為字符串" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":"abc"}' \
        0 "10012"
    
    # Reserve_Amount為浮點數
    test_api_call "Reserve_Amount為浮點數" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":1000.5}' \
        0 "10012"
    
    # Reserve_Amount為負數
    test_api_call "Reserve_Amount為負數" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":-1000}' \
        0 "10012"
    
    # Reserve_Amount為null
    test_api_call "Reserve_Amount為null" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":null}' \
        0 "10012"
    
    # Reserve_Amount為布林值
    test_api_call "Reserve_Amount為布林值" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":true}' \
        0 "10012"
    
    # Reserve_Amount為0
    test_api_call "Reserve_Amount為0" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":0}' \
        0 "10012"
    
    # 測試Reserve_Amount金額不符合規定 (10013)
    echo "--- 測試Reserve_Amount金額不符合規定 (10013) ---"
    
    # Reserve_Amount為999
    test_api_call "Reserve_Amount為999" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":999}' \
        0 "10013"
    
    # Reserve_Amount為1001
    test_api_call "Reserve_Amount為1001" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":1001}' \
        0 "10013"
    
    # Reserve_Amount為2000
    test_api_call "Reserve_Amount為2000" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":2000}' \
        0 "10013"
    
    # Reserve_Amount為3000
    test_api_call "Reserve_Amount為3000" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":3000}' \
        0 "10013"
    
    # Reserve_Amount為4999
    test_api_call "Reserve_Amount為4999" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":4999}' \
        0 "10013"
    
    # Reserve_Amount為5001
    test_api_call "Reserve_Amount為5001" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":5001}' \
        0 "10013"
    
    # Reserve_Amount為9999
    test_api_call "Reserve_Amount為9999" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":9999}' \
        0 "10013"
    
    # Reserve_Amount為10001
    test_api_call "Reserve_Amount為10001" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":10001}' \
        0 "10013"
    
    # Reserve_Amount為19999
    test_api_call "Reserve_Amount為19999" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":19999}' \
        0 "10013"
    
    # Reserve_Amount為20001
    test_api_call "Reserve_Amount為20001" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":20001}' \
        0 "10013"
    
    # Reserve_Amount為50000
    test_api_call "Reserve_Amount為50000" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":50000}' \
        0 "10013"
    
    # 測試無匹配出款單 (10014)
    echo "--- 測試無匹配出款單 (10014) ---"
    
    # 使用不存在的金額測試
    test_api_call "無匹配出款單-不存在金額" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":1000}' \
        0 "10014"
    
    # 測試成功情境（需要先建立對應的Order）
    echo "--- 測試成功情境 ---"
    
    # 首先建立一些Order來測試撮合
    echo "建立測試用的Order數據..."
    
    # 建立1000金額的Order
    test_api_call "建立1000金額Order" "order" "POST" \
        '{"WD_ID":2001,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    # 建立5000金額的Order
    test_api_call "建立5000金額Order" "order" "POST" \
        '{"WD_ID":2002,"WD_Amount":5000,"WD_Account":"987654321098765"}' \
        1 ""
    
    # 建立10000金額的Order
    test_api_call "建立10000金額Order" "order" "POST" \
        '{"WD_ID":2003,"WD_Amount":10000,"WD_Account":"111222333444555"}' \
        1 ""
    
    # 建立20000金額的Order
    test_api_call "建立20000金額Order" "order" "POST" \
        '{"WD_ID":2004,"WD_Amount":20000,"WD_Account":"555444333222111"}' \
        1 ""
    
    # 等待一秒確保數據已插入
    sleep 1
    
    # 測試成功的撮合
    test_api_call "成功撮合1000金額" "reserve" "POST" \
        '{"Reserve_UserID":1001,"Reserve_Amount":1000}' \
        1 ""
    
    test_api_call "成功撮合5000金額" "reserve" "POST" \
        '{"Reserve_UserID":1002,"Reserve_Amount":5000}' \
        1 ""
    
    test_api_call "成功撮合10000金額" "reserve" "POST" \
        '{"Reserve_UserID":1003,"Reserve_Amount":10000}' \
        1 ""
    
    test_api_call "成功撮合20000金額" "reserve" "POST" \
        '{"Reserve_UserID":1004,"Reserve_Amount":20000}' \
        1 ""
    
    # 測試邊界值
    echo "--- 測試邊界值 ---"
    
    # 最小有效Reserve_UserID
    test_api_call "最小有效Reserve_UserID" "reserve" "POST" \
        '{"Reserve_UserID":1,"Reserve_Amount":1000}' \
        0 "10014"
    
    # 最大有效Reserve_UserID (32位整數)
    test_api_call "最大有效Reserve_UserID" "reserve" "POST" \
        '{"Reserve_UserID":2147483647,"Reserve_Amount":1000}' \
        0 "10014"
    
    # 測試額外參數
    echo "--- 測試額外參數 ---"
    
    # 建立額外的Order用於測試
    test_api_call "建立額外Order" "order" "POST" \
        '{"WD_ID":2005,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    sleep 1
    
    # 包含額外參數但有效
    test_api_call "包含額外參數但有效" "reserve" "POST" \
        '{"Reserve_UserID":1005,"Reserve_Amount":1000,"extra_param":"value"}' \
        1 ""
    
    # 測試JSON格式錯誤
    echo "--- 測試JSON格式錯誤 ---"
    
    # 無效JSON格式
    test_api_call "無效JSON格式" "reserve" "POST" \
        '{"Reserve_UserID":123,"Reserve_Amount":1000' \
        0 ""
    
    # 空JSON
    test_api_call "空JSON" "reserve" "POST" \
        '{}' \
        0 "10011"
    
    # 測試重複撮合（已經撮合的Order不能再次撮合）
    echo "--- 測試重複撮合 ---"
    
    # 嘗試撮合已經被撮合的Order
    test_api_call "重複撮合" "reserve" "POST" \
        '{"Reserve_UserID":1006,"Reserve_Amount":1000}' \
        0 "10014"
    
    echo "=== /api/reserve API參數驗證測試完成 ==="
}

# 如果直接執行此腳本，則載入主測試套件並執行reserve測試
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 載入主測試套件
    source "$(dirname "$0")/../parameter_test_suite.sh"
    
    # 執行reserve API測試
    setup_test_environment
    test_reserve_api_parameters
    cleanup_test_environment
    generate_test_summary
    save_test_results
fi 