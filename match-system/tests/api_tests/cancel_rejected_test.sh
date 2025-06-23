#!/bin/bash

# /api/cancel 和 /api/rejected API參數驗證測試
# 覆蓋錯誤碼 10031-10034

# 測試/api/cancel和/api/rejected API的所有參數驗證情境
test_cancel_rejected_api_parameters() {
    echo ""
    echo "=================================="
    echo "測試 /api/cancel 和 /api/rejected API 參數驗證"
    echo "=================================="
    
    for endpoint in "cancel" "rejected"; do
        echo ""
        echo "--- 測試 /api/$endpoint API ---"
        
        # 測試WagerID參數錯誤 (10031)
        echo "--- 測試WagerID參數錯誤 (10031) ---"
        
        # WagerID為空
        test_api_call "[$endpoint] WagerID為空" "$endpoint" "POST" \
            '{"Reserve_UserID":123}' \
            0 "10031"
        
        # WagerID為字符串
        test_api_call "[$endpoint] WagerID為字符串" "$endpoint" "POST" \
            '{"WagerID":"abc","Reserve_UserID":123}' \
            0 "10031"
        
        # WagerID為浮點數
        test_api_call "[$endpoint] WagerID為浮點數" "$endpoint" "POST" \
            '{"WagerID":123.45,"Reserve_UserID":123}' \
            0 "10031"
        
        # WagerID為負數
        test_api_call "[$endpoint] WagerID為負數" "$endpoint" "POST" \
            '{"WagerID":-123,"Reserve_UserID":123}' \
            0 "10031"
        
        # WagerID為null
        test_api_call "[$endpoint] WagerID為null" "$endpoint" "POST" \
            '{"WagerID":null,"Reserve_UserID":123}' \
            0 "10031"
        
        # WagerID為布林值
        test_api_call "[$endpoint] WagerID為布林值" "$endpoint" "POST" \
            '{"WagerID":true,"Reserve_UserID":123}' \
            0 "10031"
        
        # WagerID為0
        test_api_call "[$endpoint] WagerID為0" "$endpoint" "POST" \
            '{"WagerID":0,"Reserve_UserID":123}' \
            0 "10031"
        
        # 測試Reserve_UserID參數錯誤 (10032)
        echo "--- 測試Reserve_UserID參數錯誤 (10032) ---"
        
        # Reserve_UserID為空
        test_api_call "[$endpoint] Reserve_UserID為空" "$endpoint" "POST" \
            '{"WagerID":1}' \
            0 "10032"
        
        # Reserve_UserID為字符串
        test_api_call "[$endpoint] Reserve_UserID為字符串" "$endpoint" "POST" \
            '{"WagerID":1,"Reserve_UserID":"abc"}' \
            0 "10032"
        
        # Reserve_UserID為浮點數
        test_api_call "[$endpoint] Reserve_UserID為浮點數" "$endpoint" "POST" \
            '{"WagerID":1,"Reserve_UserID":123.45}' \
            0 "10032"
        
        # Reserve_UserID為負數
        test_api_call "[$endpoint] Reserve_UserID為負數" "$endpoint" "POST" \
            '{"WagerID":1,"Reserve_UserID":-123}' \
            0 "10032"
        
        # Reserve_UserID為null
        test_api_call "[$endpoint] Reserve_UserID為null" "$endpoint" "POST" \
            '{"WagerID":1,"Reserve_UserID":null}' \
            0 "10032"
        
        # Reserve_UserID為布林值
        test_api_call "[$endpoint] Reserve_UserID為布林值" "$endpoint" "POST" \
            '{"WagerID":1,"Reserve_UserID":true}' \
            0 "10032"
        
        # Reserve_UserID為0
        test_api_call "[$endpoint] Reserve_UserID為0" "$endpoint" "POST" \
            '{"WagerID":1,"Reserve_UserID":0}' \
            0 "10032"
        
        # 測試查無此筆資料 (10033)
        echo "--- 測試查無此筆資料 (10033) ---"
        
        # 不存在的WagerID
        test_api_call "[$endpoint] 不存在的WagerID" "$endpoint" "POST" \
            '{"WagerID":99999,"Reserve_UserID":123}' \
            0 "10033"
        
        # 測試JSON格式錯誤
        echo "--- 測試JSON格式錯誤 ---"
        
        # 無效JSON格式
        test_api_call "[$endpoint] 無效JSON格式" "$endpoint" "POST" \
            '{"WagerID":1,"Reserve_UserID":123' \
            0 ""
        
        # 空JSON
        test_api_call "[$endpoint] 空JSON" "$endpoint" "POST" \
            '{}' \
            0 "10031"
        
        # 測試額外參數
        echo "--- 測試額外參數 ---"
        
        # 包含額外參數
        test_api_call "[$endpoint] 包含額外參數" "$endpoint" "POST" \
            '{"WagerID":99999,"Reserve_UserID":123,"extra_param":"value"}' \
            0 "10033"
    done
    
    # 準備測試數據：建立Order並撮合成Matching狀態用於測試
    echo ""
    echo "--- 準備測試數據 ---"
    
    # 建立Order用於cancel測試
    test_api_call "建立Order-4001" "order" "POST" \
        '{"WD_ID":4001,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    test_api_call "建立Order-4002" "order" "POST" \
        '{"WD_ID":4002,"WD_Amount":5000,"WD_Account":"987654321098765"}' \
        1 ""
    
    # 建立Order用於rejected測試（需要設置為較早時間）
    test_api_call "建立Order-4003" "order" "POST" \
        '{"WD_ID":4003,"WD_Amount":10000,"WD_Account":"111222333444555"}' \
        1 ""
    
    test_api_call "建立Order-4004" "order" "POST" \
        '{"WD_ID":4004,"WD_Amount":20000,"WD_Account":"555444333222111"}' \
        1 ""
    
    sleep 1
    
    # 撮合成Matching狀態用於cancel測試
    test_api_call "撮合成Matching-3001" "reserve" "POST" \
        '{"Reserve_UserID":3001,"Reserve_Amount":1000}' \
        1 ""
    
    test_api_call "撮合成Matching-3002" "reserve" "POST" \
        '{"Reserve_UserID":3002,"Reserve_Amount":5000}' \
        1 ""
    
    sleep 1
    
    # 測試cancel API的成功情境
    echo ""
    echo "--- 測試 /api/cancel 成功情境 ---"
    
    # 成功取消撮合
    test_api_call "成功取消撮合-1000" "cancel" "POST" \
        '{"WagerID":1,"Reserve_UserID":3001}' \
        1 ""
    
    test_api_call "成功取消撮合-5000" "cancel" "POST" \
        '{"WagerID":2,"Reserve_UserID":3002}' \
        1 ""
    
    # 測試輸入Reserve_UserID與資料不符 (10034)
    echo "--- 測試輸入Reserve_UserID與資料不符 (10034) ---"
    
    # 建立更多測試數據
    test_api_call "建立Order-4005" "order" "POST" \
        '{"WD_ID":4005,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    sleep 1
    
    test_api_call "撮合成Matching-3003" "reserve" "POST" \
        '{"Reserve_UserID":3003,"Reserve_Amount":1000}' \
        1 ""
    
    sleep 1
    
    # 使用錯誤的Reserve_UserID
    test_api_call "[cancel] 錯誤的Reserve_UserID" "cancel" "POST" \
        '{"WagerID":3,"Reserve_UserID":9999}' \
        0 "10034"
    
    # 測試rejected API的特殊情境
    echo ""
    echo "--- 測試 /api/rejected 特殊情境 ---"
    
    # rejected API需要測試時間條件
    # 由於測試環境中的Order都是新建立的，可能不會滿足15分鐘超時條件
    # 這裡測試查無此筆資料的情況
    
    test_api_call "[rejected] 不滿足時間條件" "rejected" "POST" \
        '{"WagerID":1,"Reserve_UserID":3001}' \
        0 "10033"
    
    # 測試邊界值
    echo ""
    echo "--- 測試邊界值 ---"
    
    # 最小有效WagerID
    test_api_call "[cancel] 最小有效WagerID" "cancel" "POST" \
        '{"WagerID":1,"Reserve_UserID":3001}' \
        0 "10033"  # 已經被取消了
    
    # 最大有效WagerID
    test_api_call "[cancel] 最大有效WagerID" "cancel" "POST" \
        '{"WagerID":2147483647,"Reserve_UserID":123}' \
        0 "10033"
    
    # 最小有效Reserve_UserID
    test_api_call "[cancel] 最小有效Reserve_UserID" "cancel" "POST" \
        '{"WagerID":3,"Reserve_UserID":1}' \
        0 "10034"
    
    # 最大有效Reserve_UserID
    test_api_call "[cancel] 最大有效Reserve_UserID" "cancel" "POST" \
        '{"WagerID":3,"Reserve_UserID":2147483647}' \
        0 "10034"
    
    # 測試HTTP方法錯誤
    echo ""
    echo "--- 測試HTTP方法錯誤 ---"
    
    # 使用GET方法
    test_api_call "[cancel] 使用GET方法" "cancel" "GET" \
        '' \
        0 ""
    
    test_api_call "[rejected] 使用GET方法" "rejected" "GET" \
        '' \
        0 ""
    
    # 測試重複操作
    echo ""
    echo "--- 測試重複操作 ---"
    
    # 嘗試取消已經取消的記錄
    test_api_call "[cancel] 重複取消" "cancel" "POST" \
        '{"WagerID":1,"Reserve_UserID":3001}' \
        0 "10033"
    
    # 測試狀態不符的情況
    echo ""
    echo "--- 測試狀態不符的情況 ---"
    
    # 建立Order但不撮合，直接嘗試cancel
    test_api_call "建立Order-4006" "order" "POST" \
        '{"WD_ID":4006,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
        1 ""
    
    sleep 1
    
    # 嘗試取消Order狀態的記錄（應該失敗）
    test_api_call "[cancel] 取消Order狀態記錄" "cancel" "POST" \
        '{"WagerID":4,"Reserve_UserID":123}' \
        0 "10033"
    
    echo "=== /api/cancel 和 /api/rejected API參數驗證測試完成 ==="
}

# 如果直接執行此腳本，則載入主測試套件並執行cancel/rejected測試
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 載入主測試套件
    source "$(dirname "$0")/../parameter_test_suite.sh"
    
    # 執行cancel/rejected API測試
    setup_test_environment
    test_cancel_rejected_api_parameters
    cleanup_test_environment
    generate_test_summary
    save_test_results
fi 