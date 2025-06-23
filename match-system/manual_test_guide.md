# 撮合系統手動測試指南 - 終端機版本

## 🚀 前置準備

```bash
# 啟動服務
pkill -f match-system 2>/dev/null || true
./match-system &
sleep 2
```

```bash
# 清空資料庫重新開始
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "DELETE FROM MatchLogs; DELETE FROM MatchWagers; ALTER TABLE MatchWagers AUTO_INCREMENT = 1;"
```

```bash
# 檢查服務狀態
curl -s http://localhost:8080/api/getwagerslist -X POST -H "Content-Type: application/json" -d '{"Date_S":"2025-01-01","Date_E":"2025-12-31","State":"All","Page":1,"Limit":10}' | jq .
```

---

## 🔄 流程1：Order → Rejected（超時失效）

```bash
# 步驟1：創建出款單
echo "=== 創建出款單 WID=1 ==="
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": 10001,"WD_Amount": 1000,"WD_Account": "123456789012345"}' | jq .
```

```bash
# 步驟2：驗證Order狀態
echo "=== 驗證Order狀態 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT WID, WD_ID, State, WD_DateTime FROM MatchWagers WHERE WID = 1;"
```

```bash
# 步驟3：模擬超時（修改時間戳為16分鐘前）
echo "=== 模擬超時 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "UPDATE MatchWagers SET WD_DateTime = DATE_SUB(NOW(), INTERVAL 16 MINUTE) WHERE WID = 1;"
```

```bash
# 步驟4：調用rejected API
echo "=== 調用rejected API ==="
curl -s -X POST http://localhost:8080/api/rejected -H "Content-Type: application/json" -d '{"WagerID": 1,"Reserve_UserID": 9001}' | jq .
```

```bash
# 步驟5：驗證Rejected狀態
echo "=== 驗證Rejected狀態 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT WID, WD_ID, State, Finish_DateTime FROM MatchWagers WHERE WID = 1;"
```

---

## 🔄 流程2：Order → Matching → Success（完整成交）

```bash
# 步驟1：創建出款單
echo "=== 創建出款單 WID=2 ==="
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": 20001,"WD_Amount": 5000,"WD_Account": "987654321098765"}' | jq .
```

```bash
# 步驟2：預約入款（撮合）
echo "=== 預約入款撮合 ==="
curl -s -X POST http://localhost:8080/api/reserve -H "Content-Type: application/json" -d '{"Reserve_UserID": 8001,"Reserve_Amount": 5000}' | jq .
```

```bash
# 步驟3：驗證Matching狀態
echo "=== 驗證Matching狀態 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT WID, WD_ID, State, Reserve_UserID, Reserve_DateTime FROM MatchWagers WHERE WID = 2;"
```

```bash
# 步驟4：確認成交
echo "=== 確認成交 ==="
curl -s -X POST http://localhost:8080/api/success -H "Content-Type: application/json" -d '{"WagerID": 2,"Reserve_UserID": 8001,"DEP_ID": 30001,"DEP_Amount": 5000}' | jq .
```

```bash
# 步驟5：驗證Success狀態
echo "=== 驗證Success狀態 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT WID, WD_ID, State, DEP_ID, DEP_Amount, Finish_DateTime FROM MatchWagers WHERE WID = 2;"
```

---

## 🔄 流程3：Order → Matching → Cancel（取消撮合）

```bash
# 步驟1：創建出款單
echo "=== 創建出款單 WID=3 ==="
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": 30001,"WD_Amount": 10000,"WD_Account": "111122223333444"}' | jq .
```

```bash
# 步驟2：預約入款（撮合）
echo "=== 預約入款撮合 ==="
curl -s -X POST http://localhost:8080/api/reserve -H "Content-Type: application/json" -d '{"Reserve_UserID": 7001,"Reserve_Amount": 10000}' | jq .
```

```bash
# 步驟3：取消撮合
echo "=== 取消撮合 ==="
curl -s -X POST http://localhost:8080/api/cancel -H "Content-Type: application/json" -d '{"WagerID": 3,"Reserve_UserID": 7001}' | jq .
```

```bash
# 步驟4：驗證Cancel狀態
echo "=== 驗證Cancel狀態 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT WID, WD_ID, State, Finish_DateTime FROM MatchWagers WHERE WID = 3;"
```

---

## 📊 查詢API測試

```bash
# 委託單列表查詢（全部）
echo "=== 委託單列表查詢（全部） ==="
curl -s -X POST http://localhost:8080/api/getwagerslist -H "Content-Type: application/json" -d '{"Date_S": "2025-01-01","Date_E": "2025-12-31","State": "All","Page": 1,"Limit": 10}' | jq .
```

```bash
# 查詢特定狀態（Order）
echo "=== 查詢Order狀態 ==="
curl -s -X POST http://localhost:8080/api/getwagerslist -H "Content-Type: application/json" -d '{"Date_S": "2025-01-01","Date_E": "2025-12-31","State": "Order","Page": 1,"Limit": 5}' | jq .
```

```bash
# 查詢撮合中列表
echo "=== 查詢撮合中列表 ==="
curl -s -X POST http://localhost:8080/api/getmatchinglist -H "Content-Type: application/json" -d '{"Page": 1,"Limit": 10}' | jq .
```

```bash
# 查詢失效單列表
echo "=== 查詢失效單列表 ==="
curl -s -X POST http://localhost:8080/api/getrejectedlist -H "Content-Type: application/json" -d '{"Page": 1,"Limit": 10}' | jq .
```

---

## ❌ 錯誤處理測試

```bash
# Order API - 金額不符合規定
echo "=== 測試金額錯誤（應該回傳10005） ==="
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": 40001,"WD_Amount": 999,"WD_Account": "123456789012345"}' | jq .
```

```bash
# Order API - 帳戶格式錯誤
echo "=== 測試帳戶格式錯誤（應該回傳10004） ==="
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": 40002,"WD_Amount": 1000,"WD_Account": "123abc"}' | jq .
```

```bash
# Order API - 數字字串測試（正常行為：會被接受並轉換）
echo "=== 測試數字字串（會被接受並轉換為整數） ==="
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": "40003","WD_Amount": 1000,"WD_Account": "123456789012345"}' | jq .
```

```bash
# Order API - 無效字串測試
echo "=== 測試無效字串（應該回傳10001） ==="
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": "abc","WD_Amount": 1000,"WD_Account": "123456789012345"}' | jq .
```

```bash
# Reserve API - 金額不符合規定
echo "=== 測試預約金額錯誤（應該回傳10013） ==="
curl -s -X POST http://localhost:8080/api/reserve -H "Content-Type: application/json" -d '{"Reserve_UserID": 5001,"Reserve_Amount": 888}' | jq .
```

```bash
# Success API - 不存在的WagerID
echo "=== 測試不存在的WagerID（應該回傳10025） ==="
curl -s -X POST http://localhost:8080/api/success -H "Content-Type: application/json" -d '{"WagerID": 99999,"Reserve_UserID": 5001,"DEP_ID": 50001,"DEP_Amount": 1000}' | jq .
```

```bash
# Cancel API - 不存在的WagerID
echo "=== 測試不存在的WagerID（應該回傳10033） ==="
curl -s -X POST http://localhost:8080/api/cancel -H "Content-Type: application/json" -d '{"WagerID": 99999,"Reserve_UserID": 5001}' | jq .
```

```bash
# 日期格式錯誤測試
echo "=== 測試日期格式錯誤（應該回傳10041） ==="
curl -s -X POST http://localhost:8080/api/getwagerslist -H "Content-Type: application/json" -d '{"Date_S": "2024-13-01","Date_E": "2024-01-31","State": "All","Page": 1,"Limit": 10}' | jq .
```

---

## 🔍 資料庫狀態檢查

```bash
# 查看所有委託單狀態
echo "=== 所有委託單狀態 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT WID, WD_ID, State, WD_Amount, WD_Account, Reserve_UserID, DEP_ID, DEP_Amount, WD_DateTime, Reserve_DateTime, Finish_DateTime FROM MatchWagers ORDER BY WID;"
```

```bash
# 查看狀態統計
echo "=== 狀態統計 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT State, COUNT(*) as Count FROM MatchWagers GROUP BY State;"
```

```bash
# 查看日誌記錄
echo "=== 日誌記錄 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT ID, WID, WD_ID, State, AddDateTime FROM MatchLogs ORDER BY ID;"
```

---

## 🎯 一鍵執行完整測試

```bash
# 完整測試流程 - 一次執行所有主要功能
echo "=== 開始完整測試 ==="

# 清空並重啟
pkill -f match-system 2>/dev/null || true
./match-system &
sleep 2
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "DELETE FROM MatchLogs; DELETE FROM MatchWagers; ALTER TABLE MatchWagers AUTO_INCREMENT = 1;"

# 流程1: Order → Rejected
echo "流程1: Order → Rejected"
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": 10001,"WD_Amount": 1000,"WD_Account": "123456789012345"}' | jq .
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "UPDATE MatchWagers SET WD_DateTime = DATE_SUB(NOW(), INTERVAL 16 MINUTE) WHERE WID = 1;"
curl -s -X POST http://localhost:8080/api/rejected -H "Content-Type: application/json" -d '{"WagerID": 1,"Reserve_UserID": 9001}' | jq .

# 流程2: Order → Matching → Success
echo "流程2: Order → Matching → Success"
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": 20001,"WD_Amount": 5000,"WD_Account": "987654321098765"}' | jq .
curl -s -X POST http://localhost:8080/api/reserve -H "Content-Type: application/json" -d '{"Reserve_UserID": 8001,"Reserve_Amount": 5000}' | jq .
curl -s -X POST http://localhost:8080/api/success -H "Content-Type: application/json" -d '{"WagerID": 2,"Reserve_UserID": 8001,"DEP_ID": 30001,"DEP_Amount": 5000}' | jq .

# 流程3: Order → Matching → Cancel
echo "流程3: Order → Matching → Cancel"
curl -s -X POST http://localhost:8080/api/order -H "Content-Type: application/json" -d '{"WD_ID": 30001,"WD_Amount": 10000,"WD_Account": "111122223333444"}' | jq .
curl -s -X POST http://localhost:8080/api/reserve -H "Content-Type: application/json" -d '{"Reserve_UserID": 7001,"Reserve_Amount": 10000}' | jq .
curl -s -X POST http://localhost:8080/api/cancel -H "Content-Type: application/json" -d '{"WagerID": 3,"Reserve_UserID": 7001}' | jq .

# 最終狀態檢查
echo "=== 最終狀態檢查 ==="
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT WID, WD_ID, State, WD_Amount FROM MatchWagers ORDER BY WID;"
docker exec e7cc3c069e3e mysql -u root -proot1234 match_system -e "SELECT State, COUNT(*) as Count FROM MatchWagers GROUP BY State;"

echo "=== 測試完成！應該有1個Rejected、1個Success、1個Cancel ==="
```

---

## 📋 預期結果檢查

完成測試後，你應該看到：

**狀態統計結果：**
```
State     | Count
----------|------
Rejected  |   1
Success   |   1  
Cancel    |   1
```

**錯誤碼對照：**
- 10004: 帳戶格式錯誤
- 10005: 金額不符合規定
- 10013: 預約金額錯誤
- 10025: Success API找不到資料
- 10033: Cancel API找不到資料
- 10041: 日期格式錯誤 