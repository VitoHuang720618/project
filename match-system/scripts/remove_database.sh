#!/bin/zsh

# 資料庫服務完全移除腳本
set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "${BLUE}🗑️  撮合系統資料庫移除工具${NC}"
echo ""

# 顯示將要移除的內容
echo "${RED}⚠️  警告：此操作將完全移除以下內容：${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐳 Docker 容器:"
echo "   - match_mysql (MySQL 8.0 資料庫)"
echo "   - match_phpmyadmin_master (phpMyAdmin Master 管理工具)
   - match_phpmyadmin_slave (phpMyAdmin Slave 管理工具)"
echo ""
echo "🖼️  Docker 映像:"
echo "   - mysql:8.0"
echo "   - phpmyadmin/phpmyadmin:5.2"
echo ""
echo "💾 資料卷:"
echo "   - match-system_mysql_data (包含所有資料庫資料)"
echo ""
echo "🌐 網路:"
echo "   - match-system_match_network"
echo ""
echo "📊 資料庫內容:"
echo "   - MatchWagers 表及所有記錄"
echo "   - migrations 表及遷移記錄"
echo "   - 所有索引和表結構"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 檢查當前服務狀態
echo "${BLUE}📊 檢查當前服務狀態...${NC}"
if docker-compose --env-file docker.env ps | grep -q "Up"; then
    echo "${YELLOW}⚠️  發現運行中的服務:${NC}"
    docker-compose --env-file docker.env ps
    echo ""
else
    echo "${GREEN}✅ 當前無運行中的服務${NC}"
    echo ""
fi

# 檢查資料卷大小
if docker volume inspect match-system_mysql_data >/dev/null 2>&1; then
    VOLUME_SIZE=$(docker system df -v | grep match-system_mysql_data | awk '{print $3}' || echo "未知")
    echo "${BLUE}💾 資料卷大小: $VOLUME_SIZE${NC}"
    echo ""
fi

# 確認操作
echo "${RED}🚨 這是不可逆的操作！${NC}"
echo "${YELLOW}如果你需要保留資料，請先執行備份：${NC}"
echo "   docker-compose --env-file docker.env exec mysql-master mysqldump -u root -proot1234 match_system > backup.sql"
echo ""

read -p "確定要繼續嗎？輸入 'YES' 確認，其他任意鍵取消: " confirm

if [ "$confirm" != "YES" ]; then
    echo "${YELLOW}❌ 操作已取消${NC}"
    exit 0
fi

echo ""
echo "${BLUE}🚀 開始移除程序...${NC}"

# 1. 停止所有服務
echo "${BLUE}1️⃣  停止所有服務...${NC}"
if docker-compose --env-file docker.env down; then
    echo "${GREEN}✅ 服務已停止${NC}"
else
    echo "${YELLOW}⚠️  服務停止時出現警告，繼續執行...${NC}"
fi
echo ""

# 2. 移除容器
echo "${BLUE}2️⃣  移除容器...${NC}"
containers_removed=0
for container in match_mysql match_phpmyadmin match_phpmyadmin_master match_phpmyadmin_slave; do
    if docker rm -f $container 2>/dev/null; then
        echo "   ✅ 已移除容器: $container"
        containers_removed=$((containers_removed + 1))
    else
        echo "   ℹ️  容器不存在或已移除: $container"
    fi
done
echo "   📊 總計移除 $containers_removed 個容器"
echo ""

# 3. 移除映像
echo "${BLUE}3️⃣  移除映像...${NC}"
images_removed=0
for image in mysql:8.0 phpmyadmin/phpmyadmin:5.2; do
    if docker rmi $image 2>/dev/null; then
        echo "   ✅ 已移除映像: $image"
        images_removed=$((images_removed + 1))
    else
        echo "   ℹ️  映像不存在或被其他容器使用: $image"
    fi
done
echo "   📊 總計移除 $images_removed 個映像"
echo ""

# 4. 移除資料卷
echo "${BLUE}4️⃣  移除資料卷...${NC}"
if docker volume rm match-system_mysql_data 2>/dev/null; then
    echo "   ✅ 已移除資料卷: match-system_mysql_data"
    echo "   ⚠️  所有資料庫資料已永久刪除"
else
    echo "   ℹ️  資料卷不存在或已移除: match-system_mysql_data"
fi
echo ""

# 5. 移除網路
echo "${BLUE}5️⃣  移除網路...${NC}"
if docker network rm match-system_match_network 2>/dev/null; then
    echo "   ✅ 已移除網路: match-system_match_network"
else
    echo "   ℹ️  網路不存在或已移除: match-system_match_network"
fi
echo ""

# 6. 清理系統
echo "${BLUE}6️⃣  清理未使用的 Docker 資源...${NC}"
if docker system prune -f >/dev/null 2>&1; then
    echo "   ✅ 已清理未使用的 Docker 資源"
else
    echo "   ⚠️  清理過程中出現警告"
fi
echo ""

# 7. 驗證清理結果
echo "${BLUE}7️⃣  驗證清理結果...${NC}"
remaining_containers=$(docker ps -a --filter "name=match_" --format "{{.Names}}" | wc -l)
remaining_images=$(docker images --filter "reference=mysql:8.0" --filter "reference=phpmyadmin/phpmyadmin:5.2" --format "{{.Repository}}:{{.Tag}}" | wc -l)
remaining_volumes=$(docker volume ls --filter "name=match-system" --format "{{.Name}}" | wc -l)
remaining_networks=$(docker network ls --filter "name=match-system" --format "{{.Name}}" | wc -l)

echo "   🐳 剩餘相關容器: $remaining_containers"
echo "   🖼️  剩餘相關映像: $remaining_images"  
echo "   💾 剩餘相關卷: $remaining_volumes"
echo "   🌐 剩餘相關網路: $remaining_networks"
echo ""

# 完成總結
echo "${GREEN}🎉 資料庫服務移除完成！${NC}"
echo ""
echo "${BLUE}📋 移除總結:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ MySQL 資料庫服務已移除"
echo "✅ phpMyAdmin 管理工具已移除"
echo "✅ 所有資料庫資料已刪除"
echo "✅ Docker 資源已清理"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "${YELLOW}💡 如需重新部署撮合系統：${NC}"
echo "   1. 執行初始化: ./run.sh setup"
echo "   2. 啟動服務:   ./run.sh start"
echo "   3. 執行遷移:   ./run.sh migrate"
echo "   4. 驗證系統:   ./scripts/validate_system.sh"
echo ""
echo "${BLUE}🔗 相關指令：${NC}"
echo "   - 查看幫助: ./run.sh help"
echo "   - 開啟資料庫: ./run.sh db"
echo "   - 系統狀態: ./run.sh status" 