-- 測試資料種子檔案
-- 插入測試用的撮合委託單資料

INSERT INTO MatchWagers (WD_ID, WD_Amount, WD_Account, WD_Date, WD_DateTime, State) VALUES
(1001, 5000, 'ACC001', '2024-01-15', '2024-01-15 10:30:00', 'Order'),
(1002, 3000, 'ACC002', '2024-01-15', '2024-01-15 11:15:00', 'Order'),
(1003, 7500, 'ACC003', '2024-01-15', '2024-01-15 12:00:00', 'Matching'),
(1004, 2000, 'ACC004', '2024-01-15', '2024-01-15 13:45:00', 'Success'),
(1005, 4200, 'ACC005', '2024-01-15', '2024-01-15 14:20:00', 'Rejected'),
(1006, 6800, 'ACC006', '2024-01-15', '2024-01-15 15:10:00', 'Order'),
(1007, 1500, 'ACC007', '2024-01-15', '2024-01-15 16:05:00', 'Matching'),
(1008, 8900, 'ACC008', '2024-01-15', '2024-01-15 17:30:00', 'Cancel'),
(1009, 3300, 'ACC009', '2024-01-15', '2024-01-15 18:15:00', 'Order'),
(1010, 5500, 'ACC010', '2024-01-15', '2024-01-15 19:00:00', 'Success');

-- 更新部分記錄為已撮合狀態，包含預約和完成資訊
UPDATE MatchWagers SET 
    Reserve_UserID = 2001,
    Reserve_DateTime = '2024-01-15 13:00:00',
    DEP_ID = 2001,
    DEP_Amount = 7500,
    Finish_DateTime = '2024-01-15 14:00:00'
WHERE WID = 3;

UPDATE MatchWagers SET 
    Reserve_UserID = 2002,
    Reserve_DateTime = '2024-01-15 13:30:00',
    DEP_ID = 2002,
    DEP_Amount = 2000,
    Finish_DateTime = '2024-01-15 14:30:00'
WHERE WID = 4;

UPDATE MatchWagers SET 
    Reserve_UserID = 2003,
    Reserve_DateTime = '2024-01-15 18:45:00',
    DEP_ID = 2003,
    DEP_Amount = 5500,
    Finish_DateTime = '2024-01-15 19:30:00'
WHERE WID = 10;

-- 插入更多不同日期的測試資料
INSERT INTO MatchWagers (WD_ID, WD_Amount, WD_Account, WD_Date, WD_DateTime, State) VALUES
(2001, 12000, 'ACC011', '2024-01-16', '2024-01-16 09:00:00', 'Order'),
(2002, 8500, 'ACC012', '2024-01-16', '2024-01-16 10:30:00', 'Matching'),
(2003, 4700, 'ACC013', '2024-01-16', '2024-01-16 11:45:00', 'Rejected'),
(2004, 9200, 'ACC014', '2024-01-16', '2024-01-16 14:20:00', 'Success'),
(2005, 3800, 'ACC015', '2024-01-16', '2024-01-16 16:10:00', 'Cancel'); 