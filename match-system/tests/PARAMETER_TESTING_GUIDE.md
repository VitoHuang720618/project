# 撮合系統API參數驗證測試指南

## 概述

本測試框架專門針對撮合系統的8個API進行全面的參數驗證測試，涵蓋所有定義的錯誤碼(10001-10043)和各種參數驗證情境。

## 測試覆蓋範圍

### API端點覆蓋 (8個)
1. **POST /api/order** - 委託單創建 (錯誤碼: 10001-10005)
2. **POST /api/reserve** - 預約撮合 (錯誤碼: 10011-10014)
3. **POST /api/success** - 交易成功 (錯誤碼: 10021-10028)
4. **POST /api/cancel** - 取消委託 (錯誤碼: 10031-10034)
5. **POST /api/rejected** - 拒絕委託 (錯誤碼: 10031-10034)
6. **POST /api/getwagerslist** - 查詢委託單列表 (錯誤碼: 10041-10043)
7. **POST /api/getrejectedlist** - 查詢拒絕列表
8. **POST /api/getmatchinglist** - 查詢撮合列表

### 錯誤碼覆蓋 (34個)

#### Order API (10001-10005)
- `10001`: WD_ID參數錯誤
- `10002`: WD_Amount參數錯誤
- `10003`: WD_Account參數錯誤
- `10004`: WD_Account參數不合法
- `10005`: WD_Amount金額不符合規定

#### Reserve API (10011-10014)
- `10011`: Reserve_UserID參數錯誤
- `10012`: Reserve_Amount參數錯誤
- `10013`: Reserve_Amount金額不符合規定
- `10014`: 無匹配出款單

#### Success API (10021-10028)
- `10021`: WagerID參數錯誤
- `10022`: Reserve_UserID參數錯誤
- `10023`: DEP_ID參數錯誤
- `10024`: DEP_Amount參數錯誤
- `10025`: 查無此筆資料
- `10026`: Reserve_UserID不符
- `10027`: 金額不符
- `10028`: 修改錯誤

#### Cancel/Rejected API (10031-10034)
- `10031`: WagerID參數錯誤
- `10032`: Reserve_UserID參數錯誤
- `10033`: 查無此筆資料
- `10034`: Reserve_UserID不符

#### GetWagersList API (10041-10043)
- `10041`: 日期參數錯誤
- `10042`: 搜尋日期區間超過三個月
- `10043`: 委託單狀態參數錯誤

### 測試分類覆蓋

#### 1. 參數類型驗證
- **Integer 參數**: WD_ID, WD_Amount, Reserve_UserID, Reserve_Amount, WagerID, DEP_ID, DEP_Amount
- **String 參數**: WD_Account, Date_S, Date_E, State
- **測試情境**: null, 空值, 字符串, 浮點數, 負數, 布林值, 0值

#### 2. 參數格式驗證
- **帳戶格式**: 15位數字 (WD_Account)
- **日期格式**: YYYY-MM-DD (Date_S, Date_E)
- **狀態枚舉**: All, Order, Rejected, Matching, Success, Cancel

#### 3. 業務規則驗證
- **金額限制**: 只允許 1000, 5000, 10000, 20000
- **日期範圍**: 查詢區間不超過3個月
- **帳戶規則**: 必須是15位純數字

#### 4. 響應格式驗證
- **JSON結構**: 有效的JSON格式
- **必要欄位**: Success, RunTime, EorCode
- **API特定欄位**: WID, WD_ID, WD_Amount, WD_Account, Finish_DateTime等

## 快速開始

### 環境準備

1. **安裝依賴**
```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install curl jq

# CentOS/RHEL
sudo yum install curl jq
```

2. **確認API服務運行**
```bash
curl -s http://localhost:8080/health
```

3. **設置執行權限**
```bash
chmod +x tests/run_parameter_tests.sh
chmod +x tests/parameter_test_suite.sh
chmod +x tests/api_tests/*.sh
```

### 執行測試

#### 1. 執行所有參數驗證測試
```bash
cd tests
./run_parameter_tests.sh
```

#### 2. 執行特定API測試
```bash
# 只測試 Order API
./run_parameter_tests.sh -a order

# 只測試 Reserve API  
./run_parameter_tests.sh -a reserve

# 只測試 Success API
./run_parameter_tests.sh -a success

# 只測試 Cancel/Rejected API
./run_parameter_tests.sh -a cancel

# 只測試 GetWagersList API
./run_parameter_tests.sh -a getwagerslist

# 只測試查詢API (getrejectedlist, getmatchinglist)
./run_parameter_tests.sh -a query
```

#### 3. 詳細模式執行
```bash
# 詳細輸出模式
./run_parameter_tests.sh -v

# 安靜模式（只顯示結果）
./run_parameter_tests.sh -q
```

#### 4. 直接執行個別測試模組
```bash
# 載入測試框架後執行特定測試
source parameter_test_suite.sh
source api_tests/order_test.sh
test_order_api_parameters
```

## 測試結果解讀

### 控制台輸出

```bash
[INFO] ==========================================
[INFO] 開始執行 Order API 參數驗證測試
[INFO] ==========================================
[PASS] 測試 1: WD_ID為空
[PASS] 測試 2: WD_ID為字符串
[FAIL] 測試 3: WD_Amount為浮點數
[INFO] Order API 測試完成：
[INFO]   執行時間: 15秒
[INFO]   測試數量: 45
[INFO]   通過: 43
[INFO]   失敗: 2
[INFO]   通過率: 95%
```

### 測試報告文件

執行完成後會在 `tests/results/` 目錄下生成：

1. **詳細日誌**: `parameter_test_detailed_YYYYMMDD_HHMMSS.log`
2. **JSON報告**: `parameter_test_summary_YYYYMMDD_HHMMSS.json`
3. **HTML報告**: `parameter_test_report_YYYYMMDD_HHMMSS.html`

### JSON報告結構

```json
{
    "test_execution_summary": {
        "timestamp": "2024-01-15T10:30:00+08:00",
        "duration_seconds": 120,
        "total_tests": 280,
        "passed_tests": 275,
        "failed_tests": 5,
        "pass_rate_percentage": 98
    },
    "api_coverage": {
        "total_apis": 8,
        "tested_apis": [...]
    },
    "error_code_coverage": {
        "total_error_codes": 34,
        "tested_error_codes": [...]
    }
}
```

## 測試案例範例

### Order API 測試案例

#### 成功案例
```json
{
    "test_name": "有效的1000金額",
    "request": {
        "WD_ID": 1001,
        "WD_Amount": 1000,
        "WD_Account": "123456789012345"
    },
    "expected_response": {
        "Success": 1,
        "WID": "數字",
        "WD_ID": 1001,
        "WD_Amount": 1000,
        "WD_Account": "123456789012345",
        "WD_Datetime": "YYYY-MM-DD HH:MM:SS"
    }
}
```

#### 錯誤案例 (10001)
```json
{
    "test_name": "WD_ID為空",
    "request": {
        "WD_Amount": 1000,
        "WD_Account": "123456789012345"
    },
    "expected_response": {
        "Success": 0,
        "EorCode": "10001"
    }
}
```

### Reserve API 測試案例

#### 成功案例
```json
{
    "test_name": "成功撮合1000金額",
    "request": {
        "Reserve_UserID": 1001,
        "Reserve_Amount": 1000
    },
    "expected_response": {
        "Success": 1,
        "WID": "數字",
        "WD_ID": "數字",
        "WD_Amount": 1000,
        "WD_Account": "15位數字"
    }
}
```

#### 錯誤案例 (10014)
```json
{
    "test_name": "無匹配出款單",
    "request": {
        "Reserve_UserID": 123,
        "Reserve_Amount": 1000
    },
    "expected_response": {
        "Success": 0,
        "EorCode": "10014"
    }
}
```

## 進階使用

### 自定義測試配置

可以修改 `parameter_test_suite.sh` 中的全域變數：

```bash
# API基礎URL
API_BASE_URL="http://localhost:8080"

# 測試結果文件
TEST_RESULTS_FILE="custom_results.json"

# 測試超時設定
TEST_TIMEOUT=30
```

### 添加新的測試案例

1. **在對應的API測試文件中添加**:
```bash
# 在 api_tests/order_test.sh 中添加
test_api_call "新的測試案例" "order" "POST" \
    '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
    1 ""
```

2. **創建新的測試函數**:
```bash
test_custom_scenario() {
    echo "--- 測試自定義情境 ---"
    
    test_api_call "自定義測試" "order" "POST" \
        '{"custom_data": "test"}' \
        0 "10001"
}
```

### 測試數據管理

#### 動態生成測試數據
```bash
# 生成隨機WD_ID
generate_wd_id() {
    echo $((10000 + RANDOM % 90000))
}

# 生成測試帳戶
generate_account() {
    printf "%015d" $((RANDOM % 1000000000000000))
}
```

#### 測試環境隔離
```bash
# 測試前清理
setup_test_environment() {
    # 清理測試數據
    cleanup_test_data
}

# 測試後清理
cleanup_test_environment() {
    # 恢復環境狀態
    restore_environment
}
```

## 故障排除

### 常見問題

#### 1. API服務連接失敗
```bash
# 檢查服務狀態
curl -v http://localhost:8080/health

# 檢查端口占用
lsof -i :8080
```

#### 2. 依賴工具缺失
```bash
# 檢查curl
which curl

# 檢查jq
which jq

# 安裝missing工具
brew install curl jq  # macOS
```

#### 3. 權限問題
```bash
# 設置執行權限
chmod +x tests/*.sh
chmod +x tests/api_tests/*.sh
```

#### 4. 測試數據衝突
```bash
# 清理測試數據
docker exec [container_id] mysql -u root -p[password] [database] -e "DELETE FROM MatchWagers WHERE WD_ID > 10000"
```

### 調試模式

#### 啟用詳細日誌
```bash
# 設置調試模式
export DEBUG=1
./run_parameter_tests.sh -v
```

#### 單步執行測試
```bash
# 載入框架
source parameter_test_suite.sh

# 手動執行單個測試
test_api_call "調試測試" "order" "POST" \
    '{"WD_ID":123,"WD_Amount":1000,"WD_Account":"123456789012345"}' \
    1 ""
```

## 持續集成

### GitHub Actions 配置

```yaml
name: Parameter Validation Tests

on: [push, pull_request]

jobs:
  parameter-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y curl jq
      
      - name: Start API service
        run: |
          docker-compose up -d
          sleep 30
      
      - name: Run parameter tests
        run: |
          cd tests
          chmod +x run_parameter_tests.sh
          ./run_parameter_tests.sh
      
      - name: Upload test results
        uses: actions/upload-artifact@v2
        with:
          name: parameter-test-results
          path: tests/results/
```

### Jenkins Pipeline 配置

```groovy
pipeline {
    agent any
    
    stages {
        stage('Setup') {
            steps {
                sh 'chmod +x tests/run_parameter_tests.sh'
            }
        }
        
        stage('Parameter Tests') {
            steps {
                sh 'cd tests && ./run_parameter_tests.sh'
            }
        }
        
        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: 'tests/results/**/*'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'tests/results',
                    reportFiles: '*.html',
                    reportName: 'Parameter Test Report'
                ])
            }
        }
    }
}
```

## 測試最佳實踐

### 1. 測試設計原則
- **全面覆蓋**: 涵蓋所有參數類型和錯誤情境
- **獨立執行**: 每個測試案例互不依賴
- **可重複**: 測試結果穩定可重現
- **快速反饋**: 盡快發現參數驗證問題

### 2. 測試數據管理
- **隔離環境**: 使用獨立的測試數據
- **動態生成**: 避免硬編碼測試數據
- **清理機制**: 測試後清理臨時數據

### 3. 錯誤處理
- **預期錯誤**: 明確定義預期的錯誤碼
- **異常處理**: 處理網路超時等異常情況
- **詳細日誌**: 記錄失敗原因便於調試

### 4. 性能考量
- **並行執行**: 支援部分測試並行執行
- **超時控制**: 設置合理的測試超時時間
- **資源管理**: 控制測試對系統資源的占用

## 擴展指南

### 添加新API測試

1. **創建新的測試文件**:
```bash
# 創建 api_tests/new_api_test.sh
touch tests/api_tests/new_api_test.sh
chmod +x tests/api_tests/new_api_test.sh
```

2. **實現測試函數**:
```bash
#!/bin/bash

test_new_api_parameters() {
    echo "=== 測試新API參數驗證 ==="
    
    # 參數錯誤測試
    test_api_call "參數錯誤" "newapi" "POST" \
        '{"invalid": "data"}' \
        0 "10050"
    
    # 成功測試
    test_api_call "正常請求" "newapi" "POST" \
        '{"valid": "data"}' \
        1 ""
}
```

3. **更新主執行腳本**:
```bash
# 在 run_parameter_tests.sh 中添加
run_api_tests "New API" "test_new_api_parameters"
```

### 自定義驗證規則

```bash
# 添加自定義響應驗證
validate_custom_response() {
    local response="$1"
    local expected_field="$2"
    
    local field_value=$(echo "$response" | jq -r ".$expected_field // empty")
    
    if [[ -z "$field_value" ]]; then
        echo "錯誤: 缺少必要欄位 $expected_field"
        return 1
    fi
    
    return 0
}
```

---

## 聯絡資訊

如有問題或建議，請聯絡開發團隊或提交Issue到項目倉庫。

**版本**: v1.0  
**最後更新**: 2024-01-15  
**維護者**: 撮合系統開發團隊 