-- 建立 MatchWagers 撮合系統委託單表

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET CHARACTER SET utf8mb4;
SET character_set_connection = utf8mb4;
SET character_set_results = utf8mb4;
SET character_set_client = utf8mb4;

CREATE TABLE IF NOT EXISTS MatchWagers (
    WID INT AUTO_INCREMENT PRIMARY KEY COMMENT '委託單 ID',
    WD_ID INT NOT NULL COMMENT '出款單號',
    WD_Amount SMALLINT NOT NULL COMMENT '出款金額',
    WD_Account VARCHAR(15) NOT NULL COMMENT '出款帳戶',
    WD_Date DATE NOT NULL COMMENT '出款單日期',
    WD_DateTime DATETIME NOT NULL COMMENT '出款建立時間',
    State ENUM('Order', 'Rejected', 'Matching', 'Success', 'Cancel') NOT NULL DEFAULT 'Order' COMMENT '狀態',
    Reserve_UserID INT DEFAULT NULL COMMENT '會員預約入款 ID',
    Reserve_DateTime DATETIME DEFAULT NULL COMMENT '預約入款時間',
    DEP_ID INT DEFAULT NULL COMMENT '入款單號',
    DEP_Amount SMALLINT DEFAULT NULL COMMENT '入款金額',
    Finish_DateTime DATETIME DEFAULT NULL COMMENT '完成時間',
    INDEX idx_state (State),
    INDEX idx_wd_datetime (WD_DateTime)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='撮合系統委託單表'; 