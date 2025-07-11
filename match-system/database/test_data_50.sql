SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET CHARACTER SET utf8mb4;

-- 插入50筆測試資料
INSERT INTO MatchWagers (WD_ID, WD_Amount, WD_Account, WD_Date, WD_DateTime, State, Reserve_UserID, Reserve_DateTime, DEP_ID, DEP_Amount, Finish_DateTime) VALUES
(100001, 1000, 'ACC001', '2024-01-15', '2024-01-15 09:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100002, 1500, 'ACC002', '2024-01-15', '2024-01-15 10:15:00', 'Matching', 2001, '2024-01-15 10:20:00', NULL, NULL, NULL),
(100003, 800, 'ACC003', '2024-01-15', '2024-01-15 11:00:00', 'Success', 2002, '2024-01-15 11:05:00', 300001, 800, '2024-01-15 11:30:00'),
(100004, 2000, 'ACC004', '2024-01-15', '2024-01-15 11:45:00', 'Rejected', NULL, NULL, NULL, NULL, NULL),
(100005, 1200, 'ACC005', '2024-01-15', '2024-01-15 12:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100006, 950, 'ACC006', '2024-01-15', '2024-01-15 13:15:00', 'Success', 2003, '2024-01-15 13:20:00', 300002, 950, '2024-01-15 13:45:00'),
(100007, 1800, 'ACC007', '2024-01-15', '2024-01-15 14:00:00', 'Matching', 2004, '2024-01-15 14:10:00', NULL, NULL, NULL),
(100008, 750, 'ACC008', '2024-01-15', '2024-01-15 14:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100009, 1300, 'ACC009', '2024-01-15', '2024-01-15 15:15:00', 'Cancel', NULL, NULL, NULL, NULL, NULL),
(100010, 1600, 'ACC010', '2024-01-15', '2024-01-15 16:00:00', 'Success', 2005, '2024-01-15 16:05:00', 300003, 1600, '2024-01-15 16:30:00'),

(100011, 900, 'ACC011', '2024-01-16', '2024-01-16 08:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100012, 1100, 'ACC012', '2024-01-16', '2024-01-16 09:15:00', 'Matching', 2006, '2024-01-16 09:20:00', NULL, NULL, NULL),
(100013, 1400, 'ACC013', '2024-01-16', '2024-01-16 10:00:00', 'Success', 2007, '2024-01-16 10:05:00', 300004, 1400, '2024-01-16 10:30:00'),
(100014, 700, 'ACC014', '2024-01-16', '2024-01-16 10:45:00', 'Rejected', NULL, NULL, NULL, NULL, NULL),
(100015, 1700, 'ACC015', '2024-01-16', '2024-01-16 11:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100016, 850, 'ACC016', '2024-01-16', '2024-01-16 12:15:00', 'Success', 2008, '2024-01-16 12:20:00', 300005, 850, '2024-01-16 12:45:00'),
(100017, 1250, 'ACC017', '2024-01-16', '2024-01-16 13:00:00', 'Matching', 2009, '2024-01-16 13:10:00', NULL, NULL, NULL),
(100018, 1900, 'ACC018', '2024-01-16', '2024-01-16 13:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100019, 650, 'ACC019', '2024-01-16', '2024-01-16 14:15:00', 'Cancel', NULL, NULL, NULL, NULL, NULL),
(100020, 1550, 'ACC020', '2024-01-16', '2024-01-16 15:00:00', 'Success', 2010, '2024-01-16 15:05:00', 300006, 1550, '2024-01-16 15:30:00'),

(100021, 1050, 'ACC021', '2024-01-17', '2024-01-17 08:45:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100022, 1350, 'ACC022', '2024-01-17', '2024-01-17 09:30:00', 'Matching', 2011, '2024-01-17 09:35:00', NULL, NULL, NULL),
(100023, 800, 'ACC023', '2024-01-17', '2024-01-17 10:15:00', 'Success', 2012, '2024-01-17 10:20:00', 300007, 800, '2024-01-17 10:45:00'),
(100024, 2200, 'ACC024', '2024-01-17', '2024-01-17 11:00:00', 'Rejected', NULL, NULL, NULL, NULL, NULL),
(100025, 950, 'ACC025', '2024-01-17', '2024-01-17 11:45:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100026, 1450, 'ACC026', '2024-01-17', '2024-01-17 12:30:00', 'Success', 2013, '2024-01-17 12:35:00', 300008, 1450, '2024-01-17 13:00:00'),
(100027, 750, 'ACC027', '2024-01-17', '2024-01-17 13:15:00', 'Matching', 2014, '2024-01-17 13:25:00', NULL, NULL, NULL),
(100028, 1800, 'ACC028', '2024-01-17', '2024-01-17 14:00:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100029, 1150, 'ACC029', '2024-01-17', '2024-01-17 14:45:00', 'Cancel', NULL, NULL, NULL, NULL, NULL),
(100030, 1650, 'ACC030', '2024-01-17', '2024-01-17 15:30:00', 'Success', 2015, '2024-01-17 15:35:00', 300009, 1650, '2024-01-17 16:00:00'),

(100031, 900, 'ACC031', '2024-01-18', '2024-01-18 08:15:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100032, 1300, 'ACC032', '2024-01-18', '2024-01-18 09:00:00', 'Matching', 2016, '2024-01-18 09:10:00', NULL, NULL, NULL),
(100033, 1750, 'ACC033', '2024-01-18', '2024-01-18 09:45:00', 'Success', 2017, '2024-01-18 09:50:00', 300010, 1750, '2024-01-18 10:15:00'),
(100034, 600, 'ACC034', '2024-01-18', '2024-01-18 10:30:00', 'Rejected', NULL, NULL, NULL, NULL, NULL),
(100035, 1500, 'ACC035', '2024-01-18', '2024-01-18 11:15:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100036, 1200, 'ACC036', '2024-01-18', '2024-01-18 12:00:00', 'Success', 2018, '2024-01-18 12:05:00', 300011, 1200, '2024-01-18 12:30:00'),
(100037, 850, 'ACC037', '2024-01-18', '2024-01-18 12:45:00', 'Matching', 2019, '2024-01-18 12:55:00', NULL, NULL, NULL),
(100038, 2000, 'ACC038', '2024-01-18', '2024-01-18 13:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100039, 1100, 'ACC039', '2024-01-18', '2024-01-18 14:15:00', 'Cancel', NULL, NULL, NULL, NULL, NULL),
(100040, 1400, 'ACC040', '2024-01-18', '2024-01-18 15:00:00', 'Success', 2020, '2024-01-18 15:05:00', 300012, 1400, '2024-01-18 15:30:00'),

(100041, 950, 'ACC041', '2024-01-19', '2024-01-19 08:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100042, 1600, 'ACC042', '2024-01-19', '2024-01-19 09:15:00', 'Matching', 2021, '2024-01-19 09:25:00', NULL, NULL, NULL),
(100043, 700, 'ACC043', '2024-01-19', '2024-01-19 10:00:00', 'Success', 2022, '2024-01-19 10:05:00', 300013, 700, '2024-01-19 10:30:00'),
(100044, 1850, 'ACC044', '2024-01-19', '2024-01-19 10:45:00', 'Rejected', NULL, NULL, NULL, NULL, NULL),
(100045, 1250, 'ACC045', '2024-01-19', '2024-01-19 11:30:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100046, 1550, 'ACC046', '2024-01-19', '2024-01-19 12:15:00', 'Success', 2023, '2024-01-19 12:20:00', 300014, 1550, '2024-01-19 12:45:00'),
(100047, 800, 'ACC047', '2024-01-19', '2024-01-19 13:00:00', 'Matching', 2024, '2024-01-19 13:10:00', NULL, NULL, NULL),
(100048, 1700, 'ACC048', '2024-01-19', '2024-01-19 13:45:00', 'Order', NULL, NULL, NULL, NULL, NULL),
(100049, 1000, 'ACC049', '2024-01-19', '2024-01-19 14:30:00', 'Cancel', NULL, NULL, NULL, NULL, NULL),
(100050, 1300, 'ACC050', '2024-01-19', '2024-01-19 15:15:00', 'Success', 2025, '2024-01-19 15:20:00', 300015, 1300, '2024-01-19 15:45:00'); 