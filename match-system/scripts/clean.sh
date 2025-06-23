#!/bin/bash

echo "🧹 撮合系統清理開始..."

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 停止並移除容器
cleanup_containers() {
    echo -e "${BLUE}🐳 清理 Docker 容器...${NC}"
    
    # 停止 docker-compose 服務
    if [ -f docker-compose.yml ]; then
        echo "📊 停止 Docker Compose 服務..."
        docker-compose down 2>/dev/null || true
    fi
    
    # 停止並移除相關容器
    containers=("match_mysql" "match_api")
    for container in "${containers[@]}"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            echo "🗑️  移除容器: $container"
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
        fi
    done
    
    echo -e "${GREEN}✅ 容器清理完成${NC}"
}

# 清理 Docker 映像
cleanup_images() {
    echo -e "${BLUE}🖼️  清理 Docker 映像...${NC}"
    
    # 移除專案相關映像
    project_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -E "(match-system|match_)" || true)
    
    if [ -n "$project_images" ]; then
        echo "$project_images" | while read -r image; do
            echo "🗑️  移除映像: $image"
            docker rmi "$image" 2>/dev/null || true
        done
    fi
    
    # 清理未使用的映像
    echo "🧹 清理未使用的映像..."
    docker image prune -f 2>/dev/null || true
    
    echo -e "${GREEN}✅ 映像清理完成${NC}"
}

# 清理 Docker 卷
cleanup_volumes() {
    echo -e "${BLUE}💾 清理 Docker 卷...${NC}"
    echo -e "${RED}⚠️  這將刪除所有資料庫資料！${NC}"
    
    # 移除專案相關卷
    project_volumes=$(docker volume ls --format "{{.Name}}" | grep -E "(match|mysql)" || true)
    
    if [ -n "$project_volumes" ]; then
        echo "$project_volumes" | while read -r volume; do
            echo "🗑️  移除卷: $volume"
            docker volume rm "$volume" 2>/dev/null || true
        done
    fi
    
    echo -e "${GREEN}✅ 卷清理完成${NC}"
}

# 清理專案檔案
cleanup_project_files() {
    echo -e "${BLUE}📁 清理專案檔案...${NC}"
    
    # 清理日誌檔案
    if [ -d logs ]; then
        echo "🗑️  清理日誌檔案..."
        rm -rf logs/*
    fi
    
    # 清理臨時檔案
    echo "🗑️  清理臨時檔案..."
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*.log" -delete 2>/dev/null || true
    
    echo -e "${GREEN}✅ 專案檔案清理完成${NC}"
}

# 主要執行流程
main() {
    echo "🚀 開始清理..."
    echo ""
    
    cleanup_containers
    cleanup_images
    cleanup_volumes
    cleanup_project_files
    
    echo ""
    echo -e "${GREEN}🎉 清理完成！${NC}"
    echo ""
    echo "🚀 重新啟動系統:"
    echo "  make setup && make start"
    echo ""
}

# 檢查 Docker 是否可用
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安裝或不可用${NC}"
    exit 1
fi

# 執行清理
main "$@" 