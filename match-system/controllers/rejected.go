package controllers

import (
	"database/sql"
	"log"
	"time"
	"match-system/database"
	"match-system/models"
	"match-system/utils"
	"github.com/gin-gonic/gin"
)

type RejectedRequest struct {
	WagerID        int `json:"WagerID" binding:"required"`
	Reserve_UserID int `json:"Reserve_UserID" binding:"required"`
}

type RejectedListRequest struct {
	utils.PaginationRequest
}

func GetRejectedList(c *gin.Context) {
	startTime := time.Now()
	var req RejectedListRequest
	
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, utils.ErrCancelWagerIDInvalid, startTime)
		return
	}
	
	pagination := utils.GetPaginationFromJSON(req.PaginationRequest)
	
	now := time.Now()
	liveTime := now.Add(-15 * time.Minute)
	
	countQuery := `SELECT COUNT(*) FROM MatchWagers WHERE State = ? AND WD_DateTime < ?`
	var total int
	err := database.DB.QueryRow(countQuery, "Order", liveTime).Scan(&total)
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	dataQuery := `SELECT WID, WD_ID, WD_Amount, WD_Account, WD_DateTime 
	              FROM MatchWagers 
	              WHERE State = ? AND WD_DateTime < ? 
	              ORDER BY WD_DateTime DESC 
	              LIMIT ? OFFSET ?`
	              
	rows, err := database.DB.Query(dataQuery, "Order", liveTime, pagination.Limit, pagination.Offset)
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	defer rows.Close()
	
	var result []map[string]interface{}
	for rows.Next() {
		var order models.MatchWagers
		
		err := rows.Scan(&order.WID, &order.WD_ID, &order.WD_Amount, &order.WD_Account, &order.WD_DateTime)
		if err != nil {
			utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
			return
		}
		
		item := map[string]interface{}{
			"WID":         order.WID,
			"WD_ID":       order.WD_ID,
			"WD_Amount":   order.WD_Amount,
			"WD_Account":  order.WD_Account,
			"WD_Datetime": order.WD_DateTime.Format("2006-01-02 15:04:05"),
		}
		result = append(result, item)
	}
	
	if err := rows.Err(); err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	paginationResult := utils.CreatePaginationResult(result, int64(total), pagination)
	utils.SuccessResponse(c, paginationResult, startTime)
}

func RejectMatch(c *gin.Context) {
	startTime := time.Now()
	var req RejectedRequest
	
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, utils.ErrCancelWagerIDInvalid, startTime)
		return
	}
	
	if !utils.IsValidID(req.WagerID) {
		utils.ErrorResponse(c, utils.ErrCancelWagerIDInvalid, startTime)
		return
	}
	
	if !utils.IsValidID(req.Reserve_UserID) {
		utils.ErrorResponse(c, utils.ErrCancelUserIDInvalid, startTime)
		return
	}
	
	// 查詢Order狀態的記錄，確認是否存在且超時
	var wdAmount int
	now := time.Now()
	liveTime := now.Add(-15 * time.Minute)
	
	query := `SELECT WD_Amount FROM MatchWagers WHERE WID = ? AND State = ? AND WD_DateTime < ?`
	
	log.Printf("Rejected查詢: WID=%d, State=Order, LiveTime=%s", req.WagerID, liveTime.Format("2006-01-02 15:04:05"))
	          
	err := database.DB.QueryRow(query, req.WagerID, "Order", liveTime).Scan(&wdAmount)
	if err != nil {
		if err == sql.ErrNoRows {
			utils.ErrorResponse(c, utils.ErrCancelNoData, startTime)
		} else {
			utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		}
		return
	}
	
	updateQuery := `UPDATE MatchWagers SET State = ?, Finish_DateTime = ? WHERE WID = ? AND State = ? AND WD_DateTime < ?`
	                
	result, err := database.DB.Exec(updateQuery, "Rejected", now, req.WagerID, "Order", liveTime)
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	if rowsAffected == 0 {
		utils.ErrorResponse(c, utils.ErrCancelNoData, startTime)
		return
	}
	
	logData := models.LogDetail{
		Action:    "state_change",
		FromState: "Order",
		ToState:   "Rejected",
		Timestamp: time.Now(),
		Details: map[string]interface{}{
			"reserve_user_id": req.Reserve_UserID,
			"reject_reason":   "timeout_15_minutes",
		},
	}
	
	if err := models.CreateLog(req.WagerID, 0, "Rejected", logData); err != nil {
		log.Printf("Failed to create log for order %d: %v", req.WagerID, err)
	}
	
	response := map[string]interface{}{
		"WID":       req.WagerID,
		"WD_Amount": wdAmount,
	}
	
	utils.SuccessResponse(c, response, startTime)
} 