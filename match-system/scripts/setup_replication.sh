#!/bin/bash

echo "等待 MySQL Master 啟動..."
until docker exec match_mysql_master mysqladmin ping -h localhost --silent; do
    echo "等待 MySQL Master..."
    sleep 3
done

echo "等待 MySQL Slave 啟動..."
until docker exec match_mysql_slave mysqladmin ping -h localhost --silent; do
    echo "等待 MySQL Slave..."
    sleep 3
done

echo "設置 Master 複製用戶..."
docker exec -i match_mysql_master mysql -uroot -proot1234 <<EOF
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'repl_password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
SHOW MASTER STATUS;
EOF

echo "等待 Master 準備就緒..."
sleep 5

echo "設置 Slave 複製..."
docker exec -i match_mysql_slave mysql -uroot -proot1234 <<EOF
STOP SLAVE;
RESET SLAVE ALL;
CHANGE MASTER TO
    MASTER_HOST = 'mysql-master',
    MASTER_PORT = 3306,
    MASTER_USER = 'repl',
    MASTER_PASSWORD = 'repl_password',
    MASTER_AUTO_POSITION = 1;
START SLAVE;
SHOW SLAVE STATUS\G
EOF

echo "複製設置完成！"
echo ""
echo "檢查複製狀態："
docker exec match_mysql_slave mysql -uroot -proot1234 -e "SHOW SLAVE STATUS\G" | grep -E "(Slave_IO_Running|Slave_SQL_Running)" 