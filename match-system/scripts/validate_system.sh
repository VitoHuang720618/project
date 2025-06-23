#!/bin/zsh

# 撮合系統完整驗證腳本
set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "${BLUE}🔍 撮合系統完整驗證開始...${NC}"
echo ""

# 1. 檢查 Docker 服務狀態
echo "${BLUE}1. 檢查 Docker 服務狀態${NC}"
if docker-compose --env-file docker.env ps | grep -q "Up"; then
    echo "${GREEN}✅ Docker 服務正常運行${NC}"
    docker-compose --env-file docker.env ps
else
    echo "${RED}❌ Docker 服務異常${NC}"
    exit 1
fi
echo ""

# 2. 檢查 MySQL 連接
echo "${BLUE}2. 檢查 MySQL 資料庫連接${NC}"
if docker-compose --env-file docker.env exec -T mysql-db mysql -u root -proot1234 -e "SELECT 1;" > /dev/null 2>&1; then
    echo "${GREEN}✅ MySQL 連接正常${NC}"
else
    echo "${RED}❌ MySQL 連接失敗${NC}"
    exit 1
fi

# 3. 檢查資料庫表結構
echo "${BLUE}3. 檢查資料庫表結構${NC}"
TABLE_COUNT=$(docker-compose --env-file docker.env exec -T mysql-db mysql -u root -proot1234 match_system -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'match_system';" -N)
if [ "$TABLE_COUNT" -ge 2 ]; then
    echo "${GREEN}✅ 資料庫表結構正常 (共 $TABLE_COUNT 個表)${NC}"
    docker-compose --env-file docker.env exec -T mysql-db mysql -u root -proot1234 match_system -e "SHOW TABLES;"
else
    echo "${RED}❌ 資料庫表結構異常${NC}"
    exit 1
fi
echo ""

# 4. 檢查測試資料
echo "${BLUE}4. 檢查測試資料${NC}"
DATA_COUNT=$(docker-compose --env-file docker.env exec -T mysql-db mysql -u root -proot1234 match_system -e "SELECT COUNT(*) FROM MatchWagers;" -N)
if [ "$DATA_COUNT" -gt 0 ]; then
    echo "${GREEN}✅ 測試資料正常 (共 $DATA_COUNT 筆記錄)${NC}"
else
    echo "${YELLOW}⚠️  無測試資料${NC}"
fi
echo ""

# 5. 檢查 Adminer 服務
echo "${BLUE}5. 檢查 Adminer 服務${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8081 | grep -q "200"; then
    echo "${GREEN}✅ Adminer 服務正常 (http://localhost:8081)${NC}"
else
    echo "${YELLOW}⚠️  Adminer 服務檢查異常，但可能仍可正常使用${NC}"
fi
echo ""

# 6. 檢查索引狀態
echo "${BLUE}6. 檢查資料庫索引${NC}"
INDEX_COUNT=$(docker-compose --env-file docker.env exec -T mysql-db mysql -u root -proot1234 match_system -e "SELECT COUNT(*) FROM information_schema.statistics WHERE table_name = 'MatchWagers';" -N)
if [ "$INDEX_COUNT" -gt 2 ]; then
    echo "${GREEN}✅ 資料庫索引正常 (共 $INDEX_COUNT 個索引)${NC}"
else
    echo "${YELLOW}⚠️  資料庫索引可能需要優化${NC}"
fi
echo ""

# 7. 系統資訊總結
echo "${BLUE}📊 系統資訊總結${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Adminer:      http://localhost:8081"
echo "🗄️  MySQL 端口:   3306"
echo "👤 資料庫使用者: root"
echo "🔑 資料庫密碼:   root1234"
echo "📊 資料庫名稱:   match_system"
echo "📋 主要資料表:   MatchWagers"
echo "📈 測試資料:     $DATA_COUNT 筆記錄"
echo "🔍 資料庫索引:   $INDEX_COUNT 個索引"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "${GREEN}🎉 撮合系統驗證完成！${NC}"
echo "${BLUE}💡 使用提示:${NC}"
echo "   - 開啟 Adminer:   ./run.sh db"
echo "   - 查看服務狀態:   ./run.sh status"
echo "   - 查看服務日誌:   ./run.sh logs"
echo "   - 執行資料庫遷移: ./run.sh migrate"
echo "" 