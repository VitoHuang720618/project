#!/bin/bash
set -e

echo "🚀 啟動撮合系統..."

# 載入環境變數
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ 環境變數載入完成"
else
    echo "❌ .env 檔案不存在，請先執行 make setup"
    exit 1
fi

# 檢查 Docker 是否運行
check_docker() {
    echo "🐳 檢查 Docker 服務..."
    
    if ! docker info > /dev/null 2>&1; then
        echo "❌ Docker 服務未運行，請啟動 Docker"
        exit 1
    fi
    
    echo "✅ Docker 服務正常"
}

# 清理舊容器 (如果存在)
cleanup_old_containers() {
    echo "�� 清理舊容器..."
    
    containers=("match_mysql" "match_api" "match_phpmyadmin" "match_phpmyadmin_master" "match_phpmyadmin_slave")
    for container in "${containers[@]}"; do
        if docker ps -a | grep -q $container; then
            docker stop $container 2>/dev/null || true
            docker rm $container 2>/dev/null || true
        fi
    done
    
    echo "✅ 舊容器清理完成"
}

# 啟動 MySQL 服務
start_mysql() {
    echo "🗄️  啟動 MySQL 服務..."
    
    docker-compose --env-file docker.env up -d mysql-master mysql-slave
    
    echo "⏳ 等待 MySQL Master 啟動..."
    
    # 等待 MySQL Master 健康檢查通過
    for i in {1..60}; do
        if docker-compose --env-file docker.env exec -T mysql-master mysqladmin ping -h localhost -u root -proot1234 > /dev/null 2>&1; then
            echo "✅ MySQL Master 服務啟動成功"
            break
        fi
        
        if [ $i -eq 60 ]; then
            echo "❌ MySQL Master 啟動超時，請檢查日誌"
            docker-compose --env-file docker.env logs mysql-master
            exit 1
        fi
        
        echo "⏳ 等待 MySQL Master 啟動... ($i/60)"
        sleep 2
    done
    
    echo "⏳ 等待 MySQL Slave 啟動..."
    
    # 等待 MySQL Slave 健康檢查通過
    for i in {1..60}; do
        if docker-compose --env-file docker.env exec -T mysql-slave mysqladmin ping -h localhost -u root -proot1234 > /dev/null 2>&1; then
            echo "✅ MySQL Slave 服務啟動成功"
            break
        fi
        
        if [ $i -eq 60 ]; then
            echo "❌ MySQL Slave 啟動超時，請檢查日誌"
            docker-compose --env-file docker.env logs mysql-slave
            exit 1
        fi
        
        echo "⏳ 等待 MySQL Slave 啟動... ($i/60)"
        sleep 2
    done
}

# 啟動 API 服務
start_api() {
    echo "🌐 啟動 API 服務..."
    
    # 建置 API 映像
    docker-compose --env-file docker.env build match-api
    
    # 啟動 API 容器
    docker-compose --env-file docker.env up -d match-api
    
    echo "⏳ 等待 API 服務啟動..."
    
    # 等待 API 健康檢查通過
    for i in {1..30}; do
        if docker-compose --env-file docker.env ps match-api | grep -q "Up"; then
            echo "✅ API 服務啟動成功"
            break
        fi
        
        if [ $i -eq 30 ]; then
            echo "❌ API 啟動超時，請檢查日誌"
            docker-compose --env-file docker.env logs match-api
            exit 1
        fi
        
        echo "⏳ 等待 API 啟動... ($i/30)"
        sleep 2
    done
}

# 啟動 phpMyAdmin 服務
start_phpmyadmin() {
    echo "🌐 啟動 phpMyAdmin 服務..."
    
    docker-compose --env-file docker.env up -d phpmyadmin-master phpmyadmin-slave
    
    echo "⏳ 等待 phpMyAdmin Master 啟動..."
    
    for i in {1..20}; do
        if docker-compose --env-file docker.env ps phpmyadmin-master | grep -q "Up"; then
            echo "✅ phpMyAdmin Master 服務啟動成功"
            break
        fi
        
        if [ $i -eq 20 ]; then
            echo "❌ phpMyAdmin Master 啟動超時，請檢查日誌"
            docker-compose --env-file docker.env logs phpmyadmin-master
            exit 1
        fi
        
        echo "⏳ 等待 phpMyAdmin Master 啟動... ($i/20)"
        sleep 1
    done
    
    echo "⏳ 等待 phpMyAdmin Slave 啟動..."
    
    for i in {1..20}; do
        if docker-compose --env-file docker.env ps phpmyadmin-slave | grep -q "Up"; then
            echo "✅ phpMyAdmin Slave 服務啟動成功"
            break
        fi
        
        if [ $i -eq 20 ]; then
            echo "❌ phpMyAdmin Slave 啟動超時，請檢查日誌"
            docker-compose --env-file docker.env logs phpmyadmin-slave
            exit 1
        fi
        
        echo "⏳ 等待 phpMyAdmin Slave 啟動... ($i/20)"
        sleep 1
    done
}

# 執行健康檢查
run_health_check() {
    echo "🔍 執行健康檢查..."
    
    # 檢查 MySQL Master 服務
    echo "🗄️  檢查 MySQL Master 服務..."
    if docker-compose --env-file docker.env exec -T mysql-master mysqladmin ping -h localhost -u root -proot1234 > /dev/null 2>&1; then
        echo "✅ MySQL Master 服務健康檢查通過"
    else
        echo "❌ MySQL Master 服務健康檢查失敗"
        exit 1
    fi
    
    # 檢查 MySQL Slave 服務
    echo "🗄️  檢查 MySQL Slave 服務..."
    if docker-compose --env-file docker.env exec -T mysql-slave mysqladmin ping -h localhost -u root -proot1234 > /dev/null 2>&1; then
        echo "✅ MySQL Slave 服務健康檢查通過"
    else
        echo "❌ MySQL Slave 服務健康檢查失敗"
        exit 1
    fi
    
    # 檢查 API 服務
    echo "📡 檢查 API 服務..."
    if docker-compose --env-file docker.env ps match-api | grep -q "Up"; then
        echo "✅ API 服務運行中"
    else
        echo "❌ API 服務未運行"
        exit 1
    fi
    
    # 檢查 phpMyAdmin 服務
    echo "🌐 檢查 phpMyAdmin Master 服務..."
    if docker-compose --env-file docker.env ps phpmyadmin-master | grep -q "Up"; then
        echo "✅ phpMyAdmin Master 服務運行中"
    else
        echo "❌ phpMyAdmin Master 服務未運行"
        exit 1
    fi
    
    echo "🌐 檢查 phpMyAdmin Slave 服務..."
    if docker-compose --env-file docker.env ps phpmyadmin-slave | grep -q "Up"; then
        echo "✅ phpMyAdmin Slave 服務運行中"
    else
        echo "❌ phpMyAdmin Slave 服務未運行"
        exit 1
    fi
}

# 顯示服務資訊
show_service_info() {
    echo ""
    echo "🎉 撮合系統啟動完成！"
    echo ""
    echo "📊 服務資訊:"
    echo "  API 服務:          http://localhost:8080"
    echo "  MySQL Master:      localhost:3306"
    echo "  MySQL Slave:       localhost:3307"
    echo "  phpMyAdmin Master: http://localhost:8081"
    echo "  phpMyAdmin Slave:  http://localhost:8082"
    echo "  資料庫名稱:        match_system"
    echo ""
    echo "📝 下一步操作:"
    echo "  ./run.sh migrate  - 執行資料庫遷移"
    echo "  ./run.sh status   - 查看服務狀態"
    echo "  ./run.sh logs     - 查看服務日誌"
    echo "  ./run.sh test     - 執行完整測試"
    echo "  ./run.sh stop     - 停止所有服務"
    echo ""
}

# 自動執行資料庫遷移
auto_migrate() {
    echo "🗄️  執行資料庫遷移..."
    
    # 執行遷移
    if go run cmd/migrate/main.go; then
        echo "✅ 資料庫遷移完成"
    else
        echo "❌ 資料庫遷移失敗"
        echo "💡 可以稍後手動執行: ./run.sh migrate"
    fi
}

# 主要執行流程
main() {
    check_docker
    cleanup_old_containers
    start_mysql
    start_api
    start_phpmyadmin
    run_health_check
    auto_migrate
    show_service_info
}

# 捕捉錯誤並顯示日誌
trap 'echo "❌ 啟動過程中發生錯誤"; echo "📄 檢查日誌: ./run.sh logs"; exit 1' ERR

# 執行主要流程
main "$@" 