-- Slave 設定
-- 停止複製（如果正在運行）
STOP SLAVE;

-- 設定 Master 連線
CHANGE MASTER TO
    MASTER_HOST = 'mysql-master',
    MASTER_PORT = 3306,
    MASTER_USER = 'repl',
    MASTER_PASSWORD = 'repl_password',
    MASTER_AUTO_POSITION = 1;

-- 啟動複製
START SLAVE;

-- 檢查 Slave 狀態
SHOW SLAVE STATUS\G 