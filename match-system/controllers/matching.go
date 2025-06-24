package controllers

import (
	"database/sql"
	"time"
	"match-system/database"
	"match-system/models"
	"match-system/utils"
	"github.com/gin-gonic/gin"
)

type WagersListRequest struct {
	Date_S string `json:"Date_S" binding:"required"`
	Date_E string `json:"Date_E" binding:"required"`
	State  string `json:"State" binding:"required"`
	utils.PaginationRequest
}

type MatchingListRequest struct {
	utils.PaginationRequest
}

func GetMatchingList(c *gin.Context) {
	startTime := time.Now()
	var req MatchingListRequest
	
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, utils.ErrDateInvalid, startTime)
		return
	}
	
	pagination := utils.GetPaginationFromJSON(req.PaginationRequest)
	
	countQuery := `SELECT COUNT(*) FROM MatchWagers WHERE State = ?`
	var total int
	err := database.GetReadDB().QueryRow(countQuery, "Matching").Scan(&total)
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	dataQuery := `SELECT WID, WD_ID, WD_Amount, WD_Account, Reserve_UserID, Reserve_DateTime 
	              FROM MatchWagers 
	              WHERE State = ? 
	              ORDER BY WD_DateTime DESC 
	              LIMIT ? OFFSET ?`
	              
	rows, err := database.GetReadDB().Query(dataQuery, "Matching", pagination.Limit, pagination.Offset)
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	defer rows.Close()
	
	var result []map[string]interface{}
	for rows.Next() {
		var order models.MatchWagers
		var reserveUserID sql.NullInt64
		var reserveDateTime sql.NullTime
		
		err := rows.Scan(&order.WID, &order.WD_ID, &order.WD_Amount, &order.WD_Account, 
			&reserveUserID, &reserveDateTime)
		if err != nil {
			utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
			return
		}
		
		reserveDateTimeStr := ""
		if reserveDateTime.Valid {
			reserveDateTimeStr = reserveDateTime.Time.Format("2006-01-02 15:04:05")
		}
		
		var reserveUserIDPtr *int
		if reserveUserID.Valid {
			val := int(reserveUserID.Int64)
			reserveUserIDPtr = &val
		}
		
		item := map[string]interface{}{
			"WID":               order.WID,
			"WD_ID":             order.WD_ID,
			"WD_Amount":         order.WD_Amount,
			"WD_Account":        order.WD_Account,
			"Reserve_UserID":    reserveUserIDPtr,
			"Reserve_DateTime":  reserveDateTimeStr,
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

func GetWagersList(c *gin.Context) {
	startTime := time.Now()
	var req WagersListRequest
	
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, utils.ErrDateInvalid, startTime)
		return
	}
	
	if !utils.IsValidString(req.Date_S) || !utils.IsValidString(req.Date_E) {
		utils.ErrorResponse(c, utils.ErrDateInvalid, startTime)
		return
	}
	
	dateS, dateE, err := utils.ValidateDateRange(req.Date_S, req.Date_E)
	if err != nil {
		if err.Error() == "搜尋日期區間超過三個月" {
			utils.ErrorResponse(c, utils.ErrDateRangeExceed, startTime)
			return
		}
		utils.ErrorResponse(c, utils.ErrDateInvalid, startTime)
		return
	}
	
	if !utils.ValidateState(req.State) {
		utils.ErrorResponse(c, utils.ErrStateInvalid, startTime)
		return
	}
	
	pagination := utils.GetPaginationFromJSON(req.PaginationRequest)
	
	var countQuery, dataQuery string
	var countArgs, dataArgs []interface{}
	
	if req.State == "All" {
		countQuery = `SELECT COUNT(*) FROM MatchWagers WHERE WD_Date >= ? AND WD_Date <= ?`
		countArgs = []interface{}{dateS, dateE}
		
		dataQuery = `SELECT WID, WD_ID, WD_Amount, WD_Account, WD_DateTime, State, 
		                    Reserve_UserID, Reserve_DateTime, DEP_ID, DEP_Amount, Finish_DateTime 
		             FROM MatchWagers 
		             WHERE WD_Date >= ? AND WD_Date <= ? 
		             ORDER BY WID ASC 
		             LIMIT ? OFFSET ?`
		dataArgs = []interface{}{dateS, dateE, pagination.Limit, pagination.Offset}
	} else {
		countQuery = `SELECT COUNT(*) FROM MatchWagers WHERE WD_Date >= ? AND WD_Date <= ? AND State = ?`
		countArgs = []interface{}{dateS, dateE, req.State}
		
		dataQuery = `SELECT WID, WD_ID, WD_Amount, WD_Account, WD_DateTime, State, 
		                    Reserve_UserID, Reserve_DateTime, DEP_ID, DEP_Amount, Finish_DateTime 
		             FROM MatchWagers 
		             WHERE WD_Date >= ? AND WD_Date <= ? AND State = ? 
		             ORDER BY WID ASC 
		             LIMIT ? OFFSET ?`
		dataArgs = []interface{}{dateS, dateE, req.State, pagination.Limit, pagination.Offset}
	}
	
	var total int
	err = database.GetReadDB().QueryRow(countQuery, countArgs...).Scan(&total)
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	rows, err := database.GetReadDB().Query(dataQuery, dataArgs...)
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	defer rows.Close()
	
	var result []map[string]interface{}
	for rows.Next() {
		var order models.MatchWagers
		var reserveUserID, depID, depAmount sql.NullInt64
		var reserveDateTime, finishDateTime sql.NullTime
		
		err := rows.Scan(&order.WID, &order.WD_ID, &order.WD_Amount, &order.WD_Account, 
			&order.WD_DateTime, &order.State, &reserveUserID, &reserveDateTime, 
			&depID, &depAmount, &finishDateTime)
		if err != nil {
			utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
			return
		}
		
		reserveDateTimeStr := ""
		if reserveDateTime.Valid {
			reserveDateTimeStr = reserveDateTime.Time.Format("2006-01-02 15:04:05")
		}
		
		finishDateTimeStr := ""
		if finishDateTime.Valid {
			finishDateTimeStr = finishDateTime.Time.Format("2006-01-02 15:04:05")
		}
		
		var reserveUserIDPtr *int
		if reserveUserID.Valid {
			val := int(reserveUserID.Int64)
			reserveUserIDPtr = &val
		}
		
		var depIDPtr *int
		if depID.Valid {
			val := int(depID.Int64)
			depIDPtr = &val
		}
		
		var depAmountPtr *int16
		if depAmount.Valid {
			val := int16(depAmount.Int64)
			depAmountPtr = &val
		}
		
		item := map[string]interface{}{
			"WID":               order.WID,
			"WD_ID":             order.WD_ID,
			"WD_Amount":         order.WD_Amount,
			"WD_Account":        order.WD_Account,
			"WD_Datetime":       order.WD_DateTime.Format("2006-01-02 15:04:05"),
			"State":             order.State,
			"Reserve_UserID":    reserveUserIDPtr,
			"Reserve_DateTime":  reserveDateTimeStr,
			"DEP_ID":            depIDPtr,
			"DEP_Amount":        depAmountPtr,
			"Finish_DateTime":   finishDateTimeStr,
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