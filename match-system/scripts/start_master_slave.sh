#!/bin/bash

echo "🚀 啟動 MySQL Master-Slave 架構..."

# 停止舊的容器
echo "停止現有服務..."
docker-compose --env-file docker.env down

# 清理舊的 volume（可選）
read -p "是否要清理舊的資料庫資料？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "清理舊資料..."
    docker volume rm match-system_mysql_master_data 2>/dev/null || true
    docker volume rm match-system_mysql_slave_data 2>/dev/null || true
fi

# 啟動 Master-Slave
echo "啟動 MySQL Master-Slave..."
docker-compose --env-file docker.env up -d mysql-master mysql-slave

# 等待服務啟動
echo "等待 MySQL 服務啟動..."
sleep 30

# 設置複製
echo "設置主從複製..."
./scripts/setup_replication.sh

# 啟動其他服務
echo "啟動應用程式服務..."
docker-compose --env-file docker.env up -d

echo ""
echo "✅ Master-Slave 設置完成！"
echo ""
echo "📋 連線資訊："
echo "  Master: localhost:3306"
echo "  Slave:  localhost:3307"
echo "  phpMyAdmin Master: http://localhost:8081
  phpMyAdmin Slave:  http://localhost:8082"
echo ""
echo "🔍 檢查複製狀態："
echo "  ./scripts/check_replication.sh" 