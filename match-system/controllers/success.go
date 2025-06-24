package controllers

import (
	"database/sql"
	"fmt"
	"log"
	"time"
	"match-system/database"
	"match-system/models"
	"match-system/utils"
	"github.com/gin-gonic/gin"
)

type SuccessRequest struct {
	WagerID        int   `json:"WagerID" binding:"required"`
	Reserve_UserID int   `json:"Reserve_UserID" binding:"required"`
	DEP_ID         int   `json:"DEP_ID" binding:"required"`
	DEP_Amount     int16 `json:"DEP_Amount" binding:"required"`
}

func MatchSuccess(c *gin.Context) {
	startTime := time.Now()
	var req SuccessRequest
	
	// 檢查輸入參數是否合法(英數字，特殊符號，空白)
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, utils.ErrWagerIDInvalid, startTime)
		return
	}
	
	// ErrCode = 10021 WagerID 參數錯誤 (空白，形態不符合)
	if !utils.IsValidID(req.WagerID) {
		utils.ErrorResponse(c, utils.ErrWagerIDInvalid, startTime)
		return
	}
	
	// ErrCode = 10022 Reserve_UserID 參數錯誤 (空白，形態不符合)
	if !utils.IsValidID(req.Reserve_UserID) {
		utils.ErrorResponse(c, utils.ErrSuccessUserIDInvalid, startTime)
		return
	}
	
	// ErrCode = 10023 DEP_ID 參數錯誤 (空白，形態不符合)
	if !utils.IsValidID(req.DEP_ID) {
		utils.ErrorResponse(c, utils.ErrDEPIDInvalid, startTime)
		return
	}
	
	// ErrCode = 10024 DEP_Amount 參數錯誤(空白，形態不符合)
	if req.DEP_Amount <= 0 {
		utils.ErrorResponse(c, utils.ErrDEPAmountInvalid, startTime)
		return
	}
	
	// ErrCode = 10029 檢查 DEP_Amount 是否符合 1000, 5000, 10000, 20000的金額
	if !utils.ValidateAmount(int(req.DEP_Amount)) {
		utils.ErrorResponse(c, utils.ErrDEPAmountRange, startTime)
		return
	}
	
	// 查詢是否有這筆撮合中交易單
	// SELECT Reserve_UserID, WD_Amount FROM MatchWagers WHERE WID = WagerID AND State = "Matching"
	var reserveUserID sql.NullInt64
	var wdAmount int16
	query := `SELECT Reserve_UserID, WD_Amount FROM MatchWagers WHERE WID = ? AND State = ?`
	          
	err := database.GetReadDB().QueryRow(query, req.WagerID, "Matching").Scan(&reserveUserID, &wdAmount)
	if err != nil {
		if err == sql.ErrNoRows {
			// ErrCode = 10025 查無此筆資料
			utils.ErrorResponse(c, utils.ErrNoMatchingData, startTime)
		} else {
			utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		}
		return
	}
	
	// ErrCode = 10026 輸入 Reserve_UserID != 資料Reserve_UserID
	if !reserveUserID.Valid || int(reserveUserID.Int64) != req.Reserve_UserID {
		utils.ErrorResponse(c, utils.ErrUserIDMismatch, startTime)
		return
	}
	
	// ErrCode = 10027 輸入 DEP_Amount != 資料 WD_Amount
	if wdAmount != req.DEP_Amount {
		utils.ErrorResponse(c, utils.ErrAmountMismatch, startTime)
		return
	}
	
	// $DateTime = date("Y-m-d H:i:s");
	now := time.Now()
	
	// 查詢成功 MatchWagers 修改一筆資料
	// UPDATE MatchWagers SET DEP_ID = $DEP_ID, DEP_Amount = $DEP_Amount, State = "Success", Finish_DateTime = $DateTime WHERE WID = WagerID AND State = "Matching"
	updateQuery := `UPDATE MatchWagers 
	                SET DEP_ID = ?, DEP_Amount = ?, State = ?, Finish_DateTime = ? 
	                WHERE WID = ? AND State = ?`
	                
	result, err := database.GetWriteDB().Exec(updateQuery, req.DEP_ID, req.DEP_Amount, "Success", now, req.WagerID, "Matching")
	if err != nil {
		// ErrCode = 10028 修改錯誤
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	if rowsAffected == 0 {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	// 取得已經撮合成功完整的資料提供
	// SELECT WID, WD_ID, WD_Amount, WD_Account, Reserve_UserID, DEP_ID, DEP_Amount, Finish_DateTime FROM MatchWagers WHERE WID = WagerID AND State = "Success"
	var updatedOrder models.MatchWagers
	var depID, depAmount sql.NullInt64
	var finishDateTime sql.NullTime
	
	selectQuery := `SELECT WID, WD_ID, WD_Amount, WD_Account, Reserve_UserID, DEP_ID, DEP_Amount, Finish_DateTime 
	                FROM MatchWagers 
	                WHERE WID = ? AND State = ?`
	                
	err = database.GetReadDB().QueryRow(selectQuery, req.WagerID, "Success").Scan(
		&updatedOrder.WID, &updatedOrder.WD_ID, &updatedOrder.WD_Amount, &updatedOrder.WD_Account, 
		&reserveUserID, &depID, &depAmount, &finishDateTime)
	if err != nil {
		log.Printf("Failed to fetch updated order %d: %v", req.WagerID, err)
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	// 轉換數據
	if reserveUserID.Valid {
		val := int(reserveUserID.Int64)
		updatedOrder.Reserve_UserID = &val
	}
	if depID.Valid {
		val := int(depID.Int64)
		updatedOrder.DEP_ID = &val
	}
	if depAmount.Valid {
		val := int16(depAmount.Int64)
		updatedOrder.DEP_Amount = &val
	}
	if finishDateTime.Valid {
		updatedOrder.Finish_DateTime = &finishDateTime.Time
	}
	
	// 創建MatchLog記錄
	logData := models.LogDetail{
		Action:    "state_change",
		FromState: "Matching",
		ToState:   "Success",
		Timestamp: time.Now(),
		Details: map[string]interface{}{
			"dep_id":          req.DEP_ID,
			"dep_amount":      req.DEP_Amount,
			"reserve_user_id": req.Reserve_UserID,
		},
	}
	
	if err := models.CreateLog(updatedOrder.WID, updatedOrder.WD_ID, "Success", logData); err != nil {
		log.Printf("Failed to create log for order %d: %v", updatedOrder.WID, err)
	}
	
	finishTime := ""
	if updatedOrder.Finish_DateTime != nil {
		finishTime = updatedOrder.Finish_DateTime.Format("2006-01-02 15:04:05")
	}
	
	response := map[string]interface{}{
		"WID":             updatedOrder.WID,
		"WD_ID":           updatedOrder.WD_ID,
		"WD_Amount":       updatedOrder.WD_Amount,
		"WD_Account":      updatedOrder.WD_Account,
		"Reserve_UserID":  fmt.Sprintf("%d", *updatedOrder.Reserve_UserID),
		"DEP_ID":          fmt.Sprintf("%d", *updatedOrder.DEP_ID),
		"DEP_Amount":      fmt.Sprintf("%d", *updatedOrder.DEP_Amount),
		"Finish_DateTime": finishTime,
	}
	
	utils.SuccessResponse(c, response, startTime)
} 