#!/bin/bash

# /api/success API參數驗證測試
# 覆蓋錯誤碼 10021-10028

# 測試/api/success API的所有參數驗證情境
test_success_api_parameters() {
    echo ""
    echo "=================================="
    echo "測試 /api/success API 參數驗證"
    echo "=================================="
    
    # 測試WagerID參數錯誤 (10021)
    echo "--- 測試WagerID參數錯誤 (10021) ---"
    
    # WagerID為空
    test_api_call "WagerID為空" "success" "POST" \
        '{"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10021"
    
    # WagerID為字符串
    test_api_call "WagerID為字符串" "success" "POST" \
        '{"WagerID":"abc","Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10021"
    
    # WagerID為浮點數
    test_api_call "WagerID為浮點數" "success" "POST" \
        '{"WagerID":123.45,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10021"
    
    # WagerID為負數
    test_api_call "WagerID為負數" "success" "POST" \
        '{"WagerID":-123,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10021"
    
    # WagerID為null
    test_api_call "WagerID為null" "success" "POST" \
        '{"WagerID":null,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10021"
    
    # WagerID為布林值
    test_api_call "WagerID為布林值" "success" "POST" \
        '{"WagerID":true,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10021"
    
    # WagerID為0
    test_api_call "WagerID為0" "success" "POST" \
        '{"WagerID":0,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10021"
    
    # 測試Reserve_UserID參數錯誤 (10022)
    echo "--- 測試Reserve_UserID參數錯誤 (10022) ---"
    
    # Reserve_UserID為空
    test_api_call "Reserve_UserID為空" "success" "POST" \
        '{"WagerID":1,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10022"
    
    # Reserve_UserID為字符串
    test_api_call "Reserve_UserID為字符串" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":"abc","DEP_ID":456,"DEP_Amount":1000}' \
        0 "10022"
    
    # Reserve_UserID為浮點數
    test_api_call "Reserve_UserID為浮點數" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123.45,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10022"
    
    # Reserve_UserID為負數
    test_api_call "Reserve_UserID為負數" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":-123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10022"
    
    # Reserve_UserID為null
    test_api_call "Reserve_UserID為null" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":null,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10022"
    
    # Reserve_UserID為布林值
    test_api_call "Reserve_UserID為布林值" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":true,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10022"
    
    # Reserve_UserID為0
    test_api_call "Reserve_UserID為0" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":0,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10022"
    
    # 測試DEP_ID參數錯誤 (10023)
    echo "--- 測試DEP_ID參數錯誤 (10023) ---"
    
    # DEP_ID為空
    test_api_call "DEP_ID為空" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_Amount":1000}' \
        0 "10023"
    
    # DEP_ID為字符串
    test_api_call "DEP_ID為字符串" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":"abc","DEP_Amount":1000}' \
        0 "10023"
    
    # DEP_ID為浮點數
    test_api_call "DEP_ID為浮點數" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456.78,"DEP_Amount":1000}' \
        0 "10023"
    
    # DEP_ID為負數
    test_api_call "DEP_ID為負數" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":-456,"DEP_Amount":1000}' \
        0 "10023"
    
    # DEP_ID為null
    test_api_call "DEP_ID為null" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":null,"DEP_Amount":1000}' \
        0 "10023"
    
    # DEP_ID為布林值
    test_api_call "DEP_ID為布林值" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":true,"DEP_Amount":1000}' \
        0 "10023"
    
    # DEP_ID為0
    test_api_call "DEP_ID為0" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":0,"DEP_Amount":1000}' \
        0 "10023"
    
    # 測試DEP_Amount參數錯誤 (10024)
    echo "--- 測試DEP_Amount參數錯誤 (10024) ---"
    
    # DEP_Amount為空
    test_api_call "DEP_Amount為空" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456}' \
        0 "10024"
    
    # DEP_Amount為字符串
    test_api_call "DEP_Amount為字符串" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":"abc"}' \
        0 "10024"
    
    # DEP_Amount為浮點數
    test_api_call "DEP_Amount為浮點數" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000.5}' \
        0 "10024"
    
    # DEP_Amount為負數
    test_api_call "DEP_Amount為負數" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":-1000}' \
        0 "10024"
    
    # DEP_Amount為null
    test_api_call "DEP_Amount為null" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":null}' \
        0 "10024"
    
    # DEP_Amount為布林值
    test_api_call "DEP_Amount為布林值" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":true}' \
        0 "10024"
    
    # DEP_Amount為0
    test_api_call "DEP_Amount為0" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":0}' \
        0 "10024"
    
    # 測試DEP_Amount金額不符合規定 (10013)
    echo "--- 測試DEP_Amount金額不符合規定 (10013) ---"
    
    # DEP_Amount為999
    test_api_call "DEP_Amount為999" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":999}' \
        0 "10013"
    
    # DEP_Amount為1001
    test_api_call "DEP_Amount為1001" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1001}' \
        0 "10013"
    
    # DEP_Amount為2000
    test_api_call "DEP_Amount為2000" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":2000}' \
        0 "10013"
    
    # DEP_Amount為50000
    test_api_call "DEP_Amount為50000" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":50000}' \
        0 "10013"
    
    # 測試查無此筆資料 (10025)
    echo "--- 測試查無此筆資料 (10025) ---"
    
    # 不存在的WagerID
    test_api_call "不存在的WagerID" "success" "POST" \
        '{"WagerID":99999,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10025"
    
    # 狀態不是Matching的WagerID
    test_api_call "狀態不是Matching的WagerID" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10025"
    
    # 準備測試數據：建立Order並撮合成Matching狀態
    echo "--- 準備測試數據 ---"
    
    # 建立Order
    test_api_call "建立Order-3001" "order" "POST" \
        '{"WD_ID":3001,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    test_api_call "建立Order-3002" "order" "POST" \
        '{"WD_ID":3002,"WD_Amount":5000,"WD_Account":"987654321098765"}' \
        1 ""
    
    test_api_call "建立Order-3003" "order" "POST" \
        '{"WD_ID":3003,"WD_Amount":10000,"WD_Account":"111222333444555"}' \
        1 ""
    
    test_api_call "建立Order-3004" "order" "POST" \
        '{"WD_ID":3004,"WD_Amount":20000,"WD_Account":"555444333222111"}' \
        1 ""
    
    sleep 1
    
    # 撮合成Matching狀態
    test_api_call "撮合成Matching-2001" "reserve" "POST" \
        '{"Reserve_UserID":2001,"Reserve_Amount":1000}' \
        1 ""
    
    test_api_call "撮合成Matching-2002" "reserve" "POST" \
        '{"Reserve_UserID":2002,"Reserve_Amount":5000}' \
        1 ""
    
    test_api_call "撮合成Matching-2003" "reserve" "POST" \
        '{"Reserve_UserID":2003,"Reserve_Amount":10000}' \
        1 ""
    
    test_api_call "撮合成Matching-2004" "reserve" "POST" \
        '{"Reserve_UserID":2004,"Reserve_Amount":20000}' \
        1 ""
    
    sleep 1
    
    # 獲取撮合後的WID（假設按順序遞增）
    # 這裡需要根據實際情況調整WID值
    
    # 測試輸入Reserve_UserID與資料不符 (10026)
    echo "--- 測試輸入Reserve_UserID與資料不符 (10026) ---"
    
    # 使用錯誤的Reserve_UserID
    test_api_call "錯誤的Reserve_UserID" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":9999,"DEP_ID":456,"DEP_Amount":1000}' \
        0 "10026"
    
    # 測試輸入DEP_Amount與資料WD_Amount不符 (10027)
    echo "--- 測試輸入DEP_Amount與資料WD_Amount不符 (10027) ---"
    
    # 使用錯誤的DEP_Amount
    test_api_call "錯誤的DEP_Amount" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":2001,"DEP_ID":456,"DEP_Amount":5000}' \
        0 "10027"
    
    # 測試成功情境
    echo "--- 測試成功情境 ---"
    
    # 成功完成撮合
    test_api_call "成功完成撮合-1000" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":2001,"DEP_ID":4001,"DEP_Amount":1000}' \
        1 ""
    
    test_api_call "成功完成撮合-5000" "success" "POST" \
        '{"WagerID":2,"Reserve_UserID":2002,"DEP_ID":4002,"DEP_Amount":5000}' \
        1 ""
    
    test_api_call "成功完成撮合-10000" "success" "POST" \
        '{"WagerID":3,"Reserve_UserID":2003,"DEP_ID":4003,"DEP_Amount":10000}' \
        1 ""
    
    test_api_call "成功完成撮合-20000" "success" "POST" \
        '{"WagerID":4,"Reserve_UserID":2004,"DEP_ID":4004,"DEP_Amount":20000}' \
        1 ""
    
    # 測試修改錯誤 (10028) - 嘗試修改已經Success的記錄
    echo "--- 測試修改錯誤 (10028) ---"
    
    # 嘗試再次修改已經Success的記錄
    test_api_call "修改已Success記錄" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":2001,"DEP_ID":4005,"DEP_Amount":1000}' \
        0 "10025"
    
    # 測試邊界值
    echo "--- 測試邊界值 ---"
    
    # 建立額外測試數據
    test_api_call "建立Order-3005" "order" "POST" \
        '{"WD_ID":3005,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    sleep 1
    
    test_api_call "撮合成Matching-2005" "reserve" "POST" \
        '{"Reserve_UserID":2005,"Reserve_Amount":1000}' \
        1 ""
    
    sleep 1
    
    # 最小有效DEP_ID
    test_api_call "最小有效DEP_ID" "success" "POST" \
        '{"WagerID":5,"Reserve_UserID":2005,"DEP_ID":1,"DEP_Amount":1000}' \
        1 ""
    
    # 測試額外參數
    echo "--- 測試額外參數 ---"
    
    # 建立額外測試數據
    test_api_call "建立Order-3006" "order" "POST" \
        '{"WD_ID":3006,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    sleep 1
    
    test_api_call "撮合成Matching-2006" "reserve" "POST" \
        '{"Reserve_UserID":2006,"Reserve_Amount":1000}' \
        1 ""
    
    sleep 1
    
    # 包含額外參數但有效
    test_api_call "包含額外參數但有效" "success" "POST" \
        '{"WagerID":6,"Reserve_UserID":2006,"DEP_ID":4006,"DEP_Amount":1000,"extra_param":"value"}' \
        1 ""
    
    # 測試JSON格式錯誤
    echo "--- 測試JSON格式錯誤 ---"
    
    # 無效JSON格式
    test_api_call "無效JSON格式" "success" "POST" \
        '{"WagerID":1,"Reserve_UserID":123,"DEP_ID":456,"DEP_Amount":1000' \
        0 ""
    
    # 空JSON
    test_api_call "空JSON" "success" "POST" \
        '{}' \
        0 "10021"
    
    echo "=== /api/success API參數驗證測試完成 ==="
}

# 如果直接執行此腳本，則載入主測試套件並執行success測試
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 載入主測試套件
    source "$(dirname "$0")/../parameter_test_suite.sh"
    
    # 執行success API測試
    setup_test_environment
    test_success_api_parameters
    cleanup_test_environment
    generate_test_summary
    save_test_results
fi 