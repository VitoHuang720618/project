-- 撮合系統最佳化表結構
-- 版本: 1.0
-- 建立日期: 2024-01-01

-- 建立撮合委託單表
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
    
    -- 基礎索引
    INDEX idx_state (State),
    INDEX idx_wd_datetime (WD_DateTime),
    
    -- 複合索引 (業務邏輯最佳化)
    INDEX idx_state_amount (State, WD_Amount) COMMENT '預約入款查詢最佳化',
    INDEX idx_reserve_user_state (Reserve_UserID, State) COMMENT '用戶撮合狀態查詢最佳化',
    INDEX idx_state_datetime_range (State, WD_DateTime) COMMENT '狀態時間範圍查詢最佳化',
    
    -- 單欄索引 (常用查詢)
    INDEX idx_wd_id (WD_ID) COMMENT '出款單號查詢',
    INDEX idx_dep_id (DEP_ID) COMMENT '入款單號查詢',
    INDEX idx_finish_datetime (Finish_DateTime) COMMENT '完成時間查詢'
    
) ENGINE=InnoDB 
  DEFAULT CHARSET=utf8mb4 
  COLLATE=utf8mb4_unicode_ci 
  COMMENT='撮合系統委託單表'
  AUTO_INCREMENT=1
  ROW_FORMAT=DYNAMIC; 