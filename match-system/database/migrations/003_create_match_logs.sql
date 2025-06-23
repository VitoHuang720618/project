SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET CHARACTER SET utf8mb4;
SET character_set_connection = utf8mb4;
SET character_set_results = utf8mb4;
SET character_set_client = utf8mb4;

CREATE TABLE MatchLogs (
    ID INT AUTO_INCREMENT PRIMARY KEY COMMENT '日誌 ID',
    WID INT NOT NULL COMMENT '委託單 ID',
    WD_ID INT NOT NULL COMMENT '出款單號',
    State ENUM('Order', 'Rejected', 'Matching', 'Success', 'Cancel') NOT NULL COMMENT '狀態',
    LogData TEXT COMMENT '詳細紀錄',
    AddDateTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '時間',
    INDEX idx_wid (WID),
    INDEX idx_wd_id (WD_ID),
    INDEX idx_state (State),
    INDEX idx_add_datetime (AddDateTime),
    FOREIGN KEY (WID) REFERENCES MatchWagers(WID) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='撮合系統日誌表'; 