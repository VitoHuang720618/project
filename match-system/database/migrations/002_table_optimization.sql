-- 撮合系統表後續最佳化腳本
-- 版本: 1.1
-- 用途: 表建立後的效能調優

-- 1. 分析表統計資訊 (確保索引統計正確)
ANALYZE TABLE MatchWagers;

-- 2. 最佳化表結構 (重組表碎片)
OPTIMIZE TABLE MatchWagers;

-- 3. 檢查索引效率 (執行後可查看)
-- SHOW INDEX FROM MatchWagers;
-- SELECT 
--     INDEX_NAME,
--     CARDINALITY,
--     SUB_PART,
--     INDEX_TYPE
-- FROM information_schema.STATISTICS 
-- WHERE TABLE_NAME = 'MatchWagers' 
-- ORDER BY INDEX_NAME;

-- 4. 效能監控查詢範例
-- 查看最常用查詢的執行計劃
-- EXPLAIN SELECT * FROM MatchWagers WHERE State = 'Order' AND WD_Amount = 10000;
-- EXPLAIN SELECT * FROM MatchWagers WHERE Reserve_UserID = 2001 AND State = 'Matching';
-- EXPLAIN SELECT * FROM MatchWagers WHERE State IN ('Matching', 'Success') ORDER BY WD_DateTime DESC LIMIT 10;

-- 5. 表維護建議
-- 每週執行: ANALYZE TABLE MatchWagers;
-- 每月執行: OPTIMIZE TABLE MatchWagers;
-- 監控 slow query log 以識別需要優化的查詢 