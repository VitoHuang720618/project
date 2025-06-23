#!/bin/bash

# 快速測試示例 - 展示如何使用參數驗證測試框架
# 這個腳本展示了基本的測試使用方法

echo "=========================================="
echo "撮合系統API參數驗證測試 - 快速示例"
echo "=========================================="

# 設定基本變數
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_BASE_URL="http://localhost:8080"

# 檢查API服務是否運行
echo "檢查API服務狀態..."
if curl -s "$API_BASE_URL/health" > /dev/null 2>&1; then
    echo "✓ API服務正在運行"
else
    echo "⚠ API服務可能未運行，但仍會執行測試"
fi

echo ""
echo "載入測試框架..."

# 載入主測試框架
if [[ -f "$SCRIPT_DIR/parameter_test_suite.sh" ]]; then
    source "$SCRIPT_DIR/parameter_test_suite.sh"
    echo "✓ 主測試框架載入成功"
else
    echo "✗ 找不到主測試框架"
    exit 1
fi

# 載入Order API測試
if [[ -f "$SCRIPT_DIR/api_tests/order_test.sh" ]]; then
    source "$SCRIPT_DIR/api_tests/order_test.sh"
    echo "✓ Order API測試模組載入成功"
else
    echo "✗ 找不到Order API測試模組"
    exit 1
fi

echo ""
echo "=========================================="
echo "執行Order API參數驗證測試示例"
echo "=========================================="

# 執行幾個示例測試
echo "測試1: WD_ID參數錯誤 (應該返回錯誤碼10001)"
test_api_call "WD_ID為空" "order" "POST" \
    '{"WD_Amount":1000,"WD_Account":"123456789012345"}' \
    0 "10001"

echo ""
echo "測試2: WD_Amount金額不符合規定 (應該返回錯誤碼10005)"
test_api_call "WD_Amount為999" "order" "POST" \
    '{"WD_ID":123,"WD_Amount":999,"WD_Account":"123456789012345"}' \
    0 "10005"

echo ""
echo "測試3: WD_Account格式錯誤 (應該返回錯誤碼10004)"
test_api_call "WD_Account太短" "order" "POST" \
    '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"12345"}' \
    0 "10004"

echo ""
echo "測試4: 正常創建Order (應該成功)"
test_api_call "有效的1000金額" "order" "POST" \
    '{"WD_ID":1001,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
    1 ""

echo ""
echo "=========================================="
echo "測試完成統計"
echo "=========================================="
echo "總測試數: $TOTAL_TESTS_COUNT"
echo "通過測試: $((TOTAL_TESTS_COUNT - FAILED_TESTS_COUNT))"
echo "失敗測試: $FAILED_TESTS_COUNT"

if [[ $FAILED_TESTS_COUNT -eq 0 ]]; then
    echo "🎉 所有測試都通過了！"
else
    echo "⚠ 有 $FAILED_TESTS_COUNT 個測試失敗"
fi

echo ""
echo "=========================================="
echo "如何執行完整的測試套件"
echo "=========================================="
echo "執行所有API測試:"
echo "  ./run_parameter_tests.sh"
echo ""
echo "執行特定API測試:"
echo "  ./run_parameter_tests.sh -a order"
echo "  ./run_parameter_tests.sh -a reserve"
echo "  ./run_parameter_tests.sh -a success"
echo ""
echo "詳細模式執行:"
echo "  ./run_parameter_tests.sh -v"
echo ""
echo "查看幫助:"
echo "  ./run_parameter_tests.sh -h"
echo ""
echo "更多資訊請參考: PARAMETER_TESTING_GUIDE.md" 