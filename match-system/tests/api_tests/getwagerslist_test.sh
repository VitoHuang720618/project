#!/bin/bash

# /api/getwagerslist API參數驗證測試
# 覆蓋錯誤碼 10041-10043

# 測試/api/getwagerslist API的所有參數驗證情境
test_getwagerslist_api_parameters() {
    echo ""
    echo "=================================="
    echo "測試 /api/getwagerslist API 參數驗證"
    echo "=================================="
    
    # 測試日期參數錯誤 (10041)
    echo "--- 測試日期參數錯誤 (10041) ---"
    
    # Date_S為空
    test_api_call "Date_S為空" "getwagerslist" "POST" \
        '{"Date_E":"2024-01-31","State":"All"}' \
        0 "10041"
    
    # Date_E為空
    test_api_call "Date_E為空" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","State":"All"}' \
        0 "10041"
    
    # Date_S格式錯誤
    test_api_call "Date_S格式錯誤-無效日期" "getwagerslist" "POST" \
        '{"Date_S":"invalid-date","Date_E":"2024-01-31","State":"All"}' \
        0 "10041"
    
    # Date_E格式錯誤
    test_api_call "Date_E格式錯誤-無效日期" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"invalid-date","State":"All"}' \
        0 "10041"
    
    # Date_S格式錯誤-月份超出範圍
    test_api_call "Date_S格式錯誤-月份超出範圍" "getwagerslist" "POST" \
        '{"Date_S":"2024-13-01","Date_E":"2024-01-31","State":"All"}' \
        0 "10041"
    
    # Date_E格式錯誤-日期超出範圍
    test_api_call "Date_E格式錯誤-日期超出範圍" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-32","State":"All"}' \
        0 "10041"
    
    # Date_S格式錯誤-使用斜線分隔
    test_api_call "Date_S格式錯誤-使用斜線分隔" "getwagerslist" "POST" \
        '{"Date_S":"2024/01/01","Date_E":"2024-01-31","State":"All"}' \
        0 "10041"
    
    # Date_E格式錯誤-缺少前導零
    test_api_call "Date_E格式錯誤-缺少前導零" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-1-31","State":"All"}' \
        0 "10041"
    
    # Date_S為數字類型
    test_api_call "Date_S為數字類型" "getwagerslist" "POST" \
        '{"Date_S":20240101,"Date_E":"2024-01-31","State":"All"}' \
        0 "10041"
    
    # Date_E為null
    test_api_call "Date_E為null" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":null,"State":"All"}' \
        0 "10041"
    
    # Date_S為空字符串
    test_api_call "Date_S為空字符串" "getwagerslist" "POST" \
        '{"Date_S":"","Date_E":"2024-01-31","State":"All"}' \
        0 "10041"
    
    # Date_E為空字符串
    test_api_call "Date_E為空字符串" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"","State":"All"}' \
        0 "10041"
    
    # 測試搜尋日期區間超過三個月 (10042)
    echo "--- 測試搜尋日期區間超過三個月 (10042) ---"
    
    # 超過三個月-4個月
    test_api_call "超過三個月-4個月" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-05-01","State":"All"}' \
        0 "10042"
    
    # 超過三個月-6個月
    test_api_call "超過三個月-6個月" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-07-01","State":"All"}' \
        0 "10042"
    
    # 超過三個月-1年
    test_api_call "超過三個月-1年" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2025-01-01","State":"All"}' \
        0 "10042"
    
    # 剛好超過三個月
    test_api_call "剛好超過三個月" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-04-02","State":"All"}' \
        0 "10042"
    
    # 測試委託單狀態參數錯誤 (10043)
    echo "--- 測試委託單狀態參數錯誤 (10043) ---"
    
    # State為空
    test_api_call "State為空" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31"}' \
        0 "10043"
    
    # State為無效值
    test_api_call "State為無效值-Invalid" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":"Invalid"}' \
        0 "10043"
    
    # State為小寫
    test_api_call "State為小寫-order" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":"order"}' \
        0 "10043"
    
    # State為小寫
    test_api_call "State為小寫-success" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":"success"}' \
        0 "10043"
    
    # State為數字
    test_api_call "State為數字" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":1}' \
        0 "10043"
    
    # State為null
    test_api_call "State為null" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":null}' \
        0 "10043"
    
    # State為空字符串
    test_api_call "State為空字符串" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":""}' \
        0 "10043"
    
    # State為布林值
    test_api_call "State為布林值" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":true}' \
        0 "10043"
    
    # State為錯誤的狀態名稱
    test_api_call "State為錯誤的狀態名稱-Pending" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":"Pending"}' \
        0 "10043"
    
    test_api_call "State為錯誤的狀態名稱-Complete" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":"Complete"}' \
        0 "10043"
    
    test_api_call "State為錯誤的狀態名稱-Failed" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":"Failed"}' \
        0 "10043"
    
    # 測試成功情境
    echo "--- 測試成功情境 ---"
    
    # 獲取當前日期用於測試
    local current_date=$(date +%Y-%m-%d)
    local yesterday=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null || echo "2024-01-01")
    
    # 有效的All狀態查詢
    test_api_call "有效的All狀態查詢" "getwagerslist" "POST" \
        "{\"Date_S\":\"$yesterday\",\"Date_E\":\"$current_date\",\"State\":\"All\"}" \
        1 ""
    
    # 有效的Order狀態查詢
    test_api_call "有效的Order狀態查詢" "getwagerslist" "POST" \
        "{\"Date_S\":\"$yesterday\",\"Date_E\":\"$current_date\",\"State\":\"Order\"}" \
        1 ""
    
    # 有效的Rejected狀態查詢
    test_api_call "有效的Rejected狀態查詢" "getwagerslist" "POST" \
        "{\"Date_S\":\"$yesterday\",\"Date_E\":\"$current_date\",\"State\":\"Rejected\"}" \
        1 ""
    
    # 有效的Matching狀態查詢
    test_api_call "有效的Matching狀態查詢" "getwagerslist" "POST" \
        "{\"Date_S\":\"$yesterday\",\"Date_E\":\"$current_date\",\"State\":\"Matching\"}" \
        1 ""
    
    # 有效的Success狀態查詢
    test_api_call "有效的Success狀態查詢" "getwagerslist" "POST" \
        "{\"Date_S\":\"$yesterday\",\"Date_E\":\"$current_date\",\"State\":\"Success\"}" \
        1 ""
    
    # 有效的Cancel狀態查詢
    test_api_call "有效的Cancel狀態查詢" "getwagerslist" "POST" \
        "{\"Date_S\":\"$yesterday\",\"Date_E\":\"$current_date\",\"State\":\"Cancel\"}" \
        1 ""
    
    # 測試邊界值
    echo "--- 測試邊界值 ---"
    
    # 剛好三個月
    test_api_call "剛好三個月" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-04-01","State":"All"}' \
        1 ""
    
    # 接近三個月
    test_api_call "接近三個月-89天" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-03-30","State":"All"}' \
        1 ""
    
    # 同一天
    test_api_call "同一天查詢" "getwagerslist" "POST" \
        "{\"Date_S\":\"$current_date\",\"Date_E\":\"$current_date\",\"State\":\"All\"}" \
        1 ""
    
    # 日期順序顛倒（系統應該自動交換）
    test_api_call "日期順序顛倒" "getwagerslist" "POST" \
        "{\"Date_S\":\"$current_date\",\"Date_E\":\"$yesterday\",\"State\":\"All\"}" \
        1 ""
    
    # 測試額外參數
    echo "--- 測試額外參數 ---"
    
    # 包含額外參數但有效
    test_api_call "包含額外參數但有效" "getwagerslist" "POST" \
        "{\"Date_S\":\"$yesterday\",\"Date_E\":\"$current_date\",\"State\":\"All\",\"extra_param\":\"value\"}" \
        1 ""
    
    # 測試JSON格式錯誤
    echo "--- 測試JSON格式錯誤 ---"
    
    # 無效JSON格式
    test_api_call "無效JSON格式" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-31","State":"All"' \
        0 ""
    
    # 空JSON
    test_api_call "空JSON" "getwagerslist" "POST" \
        '{}' \
        0 "10041"
    
    # 測試HTTP方法錯誤
    echo "--- 測試HTTP方法錯誤 ---"
    
    # 使用GET方法
    test_api_call "使用GET方法" "getwagerslist" "GET" \
        '' \
        0 ""
    
    # 測試特殊日期
    echo "--- 測試特殊日期 ---"
    
    # 閏年日期
    test_api_call "閏年日期" "getwagerslist" "POST" \
        '{"Date_S":"2024-02-29","Date_E":"2024-03-01","State":"All"}' \
        1 ""
    
    # 非閏年的2月29日
    test_api_call "非閏年的2月29日" "getwagerslist" "POST" \
        '{"Date_S":"2023-02-29","Date_E":"2023-03-01","State":"All"}' \
        0 "10041"
    
    # 年末日期
    test_api_call "年末日期" "getwagerslist" "POST" \
        '{"Date_S":"2024-12-31","Date_E":"2024-12-31","State":"All"}' \
        1 ""
    
    # 年初日期
    test_api_call "年初日期" "getwagerslist" "POST" \
        '{"Date_S":"2024-01-01","Date_E":"2024-01-01","State":"All"}' \
        1 ""
    
    # 測試分頁參數（如果支援）
    echo "--- 測試分頁參數 ---"
    
    # 包含分頁參數
    test_api_call "包含分頁參數" "getwagerslist" "POST" \
        "{\"Date_S\":\"$yesterday\",\"Date_E\":\"$current_date\",\"State\":\"All\",\"page\":1,\"limit\":10}" \
        1 ""
    
    echo "=== /api/getwagerslist API參數驗證測試完成 ==="
}

# 如果直接執行此腳本，則載入主測試套件並執行getwagerslist測試
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 載入主測試套件
    source "$(dirname "$0")/../parameter_test_suite.sh"
    
    # 執行getwagerslist API測試
    setup_test_environment
    test_getwagerslist_api_parameters
    cleanup_test_environment
    generate_test_summary
    save_test_results
fi 