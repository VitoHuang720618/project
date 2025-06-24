#!/bin/bash

echo "=== Master 狀態 ==="
docker exec match_mysql_master mysql -uroot -proot1234 -e "SHOW MASTER STATUS;"

echo ""
echo "=== Slave 狀態 ==="
docker exec match_mysql_slave mysql -uroot -proot1234 -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running|Master_Host|Seconds_Behind_Master)"

echo ""
echo "=== 測試複製 ==="
echo "在 Master 插入測試資料..."
docker exec match_mysql_master mysql -uroot -proot1234 match_system -e "
INSERT INTO MatchWagers (WD_ID, WD_Amount, WD_Account, WD_Date, WD_DateTime, State) 
VALUES (999999, 1000, 'TEST_REPL', NOW(), NOW(), 'Order');"

echo "等待複製..."
sleep 2

echo "檢查 Slave 是否有資料..."
SLAVE_COUNT=$(docker exec match_mysql_slave mysql -uroot -proot1234 match_system -e "SELECT COUNT(*) FROM MatchWagers WHERE WD_ID = 999999;" | tail -1)
MASTER_COUNT=$(docker exec match_mysql_master mysql -uroot -proot1234 match_system -e "SELECT COUNT(*) FROM MatchWagers WHERE WD_ID = 999999;" | tail -1)

echo "Master 記錄數: $MASTER_COUNT"
echo "Slave 記錄數: $SLAVE_COUNT"

if [ "$SLAVE_COUNT" = "$MASTER_COUNT" ] && [ "$SLAVE_COUNT" != "0" ]; then
    echo "✅ 複製正常工作！"
    # 清理測試資料
    docker exec match_mysql_master mysql -uroot -proot1234 match_system -e "DELETE FROM MatchWagers WHERE WD_ID = 999999;"
else
    echo "❌ 複製可能有問題！"
fi 