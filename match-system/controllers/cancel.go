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

type CancelRequest struct {
	WagerID        int `json:"WagerID" binding:"required"`
	Reserve_UserID int `json:"Reserve_UserID" binding:"required"`
}

func CancelMatch(c *gin.Context) {
	startTime := time.Now()
	var req CancelRequest
	
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
	
	var wdID, reserveUserID, wdAmount int
	query := `SELECT WD_ID, Reserve_UserID, WD_Amount FROM MatchWagers WHERE WID = ? AND State = ?`
	          
	err := database.DB.QueryRow(query, req.WagerID, "Matching").Scan(&wdID, &reserveUserID, &wdAmount)
	if err != nil {
		if err == sql.ErrNoRows {
			utils.ErrorResponse(c, utils.ErrCancelNoData, startTime)
		} else {
			utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		}
		return
	}
	
	if reserveUserID != req.Reserve_UserID {
		utils.ErrorResponse(c, utils.ErrCancelUserIDMismatch, startTime)
		return
	}
	
	now := time.Now()
	
	updateQuery := `UPDATE MatchWagers SET State = ?, Finish_DateTime = ? WHERE WID = ?`
	                
	result, err := database.DB.Exec(updateQuery, "Cancel", now, req.WagerID)
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
		FromState: "Matching",
		ToState:   "Cancel",
		Timestamp: time.Now(),
		Details: map[string]interface{}{
			"reserve_user_id": req.Reserve_UserID,
			"cancel_reason":   "user_requested",
		},
	}
	
	if err := models.CreateLog(req.WagerID, wdID, "Cancel", logData); err != nil {
		log.Printf("Failed to create log for order %d: %v", req.WagerID, err)
	}
	
	response := map[string]interface{}{
		"WID":        req.WagerID,
		"WD_ID":      wdID,
		"WD_Amount":  wdAmount,
	}
	
	utils.SuccessResponse(c, response, startTime)
} 