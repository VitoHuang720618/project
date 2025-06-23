package controllers

import (
	"log"
	"time"
	"match-system/database"
	"match-system/models"
	"match-system/utils"
	"github.com/gin-gonic/gin"
)

type ReserveRequest struct {
	Reserve_UserID int `json:"Reserve_UserID" binding:"required"`
	Reserve_Amount int `json:"Reserve_Amount" binding:"required"`
}

func CreateReserve(c *gin.Context) {
	startTime := time.Now()
	var req ReserveRequest
	
	// 檢查輸入參數是否合法(英數字，特殊符號，空白)
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, utils.ErrReserveUserIDInvalid, startTime)
		return
	}
	
	// EorCode = 10011 Reserve_UserID 參數錯誤 (空白，形態不符合)
	if !utils.IsValidID(req.Reserve_UserID) {
		utils.ErrorResponse(c, utils.ErrReserveUserIDInvalid, startTime)
		return
	}
	
	// EorCode = 10012 Reserve_Amount 參數錯誤(空白，形態不符合)
	if req.Reserve_Amount <= 0 {
		utils.ErrorResponse(c, utils.ErrReserveAmountInvalid, startTime)
		return
	}
	
	// EorCode = 10013 Reserve_Amount 金額不符合規定
	// 檢查 Reserve_Amount 是否符合 1000, 5000, 10000, 20000的金額
	if !utils.ValidateAmount(req.Reserve_Amount) {
		utils.ErrorResponse(c, utils.ErrReserveAmountRange, startTime)
		return
	}
	
	// $DateTime = date("Y-m-d H:i:s"); - 唯一時間值
	// $LiveTime = date("Y-m-d H:i:s", strtotime("-15 minutes"));
	dateTime := time.Now()  // 唯一的$DateTime，UPDATE和SELECT都用這個
	liveTime := dateTime.Add(-15 * time.Minute)
	
	log.Printf("Reserve條件檢查: Amount=%d, LiveTime=%s, DateTime=%s", 
		req.Reserve_Amount, liveTime.Format("2006-01-02 15:04:05"), dateTime.Format("2006-01-02 15:04:05"))
	
	// 先檢查是否有符合條件的Order
	var count int
	countQuery := `SELECT COUNT(*) FROM MatchWagers WHERE State = ? AND WD_Amount = ? AND WD_DateTime >= ?`
	err := database.DB.QueryRow(countQuery, "Order", req.Reserve_Amount, liveTime).Scan(&count)
	if err != nil {
		log.Printf("檢查Order數量失敗: %v", err)
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	log.Printf("符合條件的Order數量: %d", count)
	
	if count == 0 {
		log.Printf("無匹配出款單: State=Order, WD_Amount=%d, WD_DateTime>=%s", req.Reserve_Amount, liveTime.Format("2006-01-02 15:04:05"))
		utils.ErrorResponse(c, utils.ErrNoMatchingOrder, startTime)
		return
	}
	
	// MatchWagers 修改一筆資料
	// UPDATE MatchWagers SET Reserve_UserID = $Reserve_UserID, 
	// State = "Matching", Reserve_DateTime = $DateTime 
	// WHERE State = "Order" AND WD_Amount = $Reserve_Amount AND WD_DateTime >= $LiveTime;
	updateQuery := `UPDATE MatchWagers SET Reserve_UserID = ?, State = ?, Reserve_DateTime = ? 
	                WHERE State = ? AND WD_Amount = ? AND WD_DateTime >= ? 
	                LIMIT 1`
	
	result, err := database.DB.Exec(updateQuery, req.Reserve_UserID, "Matching", dateTime, "Order", req.Reserve_Amount, liveTime)
	if err != nil {
		log.Printf("UPDATE執行錯誤: %v", err)
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("獲取RowsAffected失敗: %v", err)
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	// 修改失敗回傳錯誤 EorCode = 10014 無匹配出款單
	if rowsAffected == 0 {
		log.Printf("UPDATE失敗，無匹配出款單: RowsAffected=%d", rowsAffected)
		utils.ErrorResponse(c, utils.ErrNoMatchingOrder, startTime)
		return
	}
	
	log.Printf("成功更新 %d 筆記錄", rowsAffected)
	
	// 取得已經預約的資料提供
	// SELECT WID, WD_ID, WD_Amount, WD_Account FROM MatchWagers 
	// WHERE Reserve_UserID = $Reserve_UserID AND State = "Matching" AND Reserve_DateTime = $DateTime
	// 因為時間精度問題，使用範圍查詢 (±1秒)
	var selectedData models.MatchWagers
	timeWindow := time.Second
	selectQuery := `SELECT WID, WD_ID, WD_Amount, WD_Account FROM MatchWagers 
	                WHERE Reserve_UserID = ? AND State = ? 
	                AND Reserve_DateTime BETWEEN ? AND ?
	                ORDER BY Reserve_DateTime DESC LIMIT 1`
	
	err = database.DB.QueryRow(selectQuery, req.Reserve_UserID, "Matching", 
		dateTime.Add(-timeWindow), dateTime.Add(timeWindow)).Scan(
		&selectedData.WID, &selectedData.WD_ID, &selectedData.WD_Amount, &selectedData.WD_Account)
	if err != nil {
		log.Printf("SELECT查詢失敗 Reserve_UserID %d: %v", req.Reserve_UserID, err)
		utils.ErrorResponse(c, utils.ErrNoMatchingOrder, startTime)
		return
	}
	
	log.Printf("SELECT查詢結果: WID=%d, WD_ID=%d, WD_Amount=%d, WD_Account=%s", 
		selectedData.WID, selectedData.WD_ID, selectedData.WD_Amount, selectedData.WD_Account)
	
	// 創建MatchLog記錄
	logData := models.LogDetail{
		Action:    "state_change",
		FromState: "Order",
		ToState:   "Matching",
		Timestamp: time.Now(),
		Details: map[string]interface{}{
			"WID":             selectedData.WID,
			"WD_ID":           selectedData.WD_ID,
			"WD_Amount":       selectedData.WD_Amount,
			"WD_Account":      selectedData.WD_Account,
			"reserve_user_id": req.Reserve_UserID,
			"reserve_amount":  req.Reserve_Amount,
		},
	}
	
	if err := models.CreateLog(selectedData.WID, selectedData.WD_ID, "Matching", logData); err != nil {
		log.Printf("創建Log失敗 order %d: %v", selectedData.WID, err)
	}
	
	response := map[string]interface{}{
		"WID":        selectedData.WID,
		"WD_ID":      selectedData.WD_ID,
		"WD_Amount":  selectedData.WD_Amount,
		"WD_Account": selectedData.WD_Account,
	}
	
	utils.SuccessResponse(c, response, startTime)
} 