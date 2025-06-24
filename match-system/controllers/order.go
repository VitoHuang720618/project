package controllers

import (
	"encoding/json"
	"log"
	"time"
	"match-system/database"
	"match-system/models"
	"match-system/utils"
	"github.com/gin-gonic/gin"
)

type OrderRequest struct {
	WD_ID      int    `json:"WD_ID" binding:"required"`
	WD_Amount  int16  `json:"WD_Amount" binding:"required"`
	WD_Account string `json:"WD_Account" binding:"required"`
}

// 嚴格類型檢查的結構
type StrictOrderRequest struct {
	WD_ID      json.RawMessage `json:"WD_ID"`
	WD_Amount  json.RawMessage `json:"WD_Amount"`
	WD_Account json.RawMessage `json:"WD_Account"`
}

func CreateOrder(c *gin.Context) {
	startTime := time.Now()
	
	// 如果需要嚴格類型檢查，取消註解以下代碼
	/*
	// 先檢查原始JSON類型
	var strictReq StrictOrderRequest
	if err := c.ShouldBindJSON(&strictReq); err != nil {
		utils.ErrorResponse(c, utils.ErrWDIDInvalid, startTime)
		return
	}
	
	// 檢查WD_ID是否為純數字（不是字串）
	var wdIDTest interface{}
	if err := json.Unmarshal(strictReq.WD_ID, &wdIDTest); err != nil {
		utils.ErrorResponse(c, utils.ErrWDIDInvalid, startTime)
		return
	}
	if _, ok := wdIDTest.(string); ok {
		// 如果是字串類型，拒絕
		utils.ErrorResponse(c, utils.ErrWDIDInvalid, startTime)
		return
	}
	*/
	
	var req OrderRequest
	
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorResponse(c, utils.ErrWDIDInvalid, startTime)
		return
	}
	
	if !utils.IsValidID(req.WD_ID) {
		utils.ErrorResponse(c, utils.ErrWDIDInvalid, startTime)
		return
	}
	
	if req.WD_Amount <= 0 {
		utils.ErrorResponse(c, utils.ErrWDAmountInvalid, startTime)
		return
	}
	
	if !utils.ValidateAmount(int(req.WD_Amount)) {
		utils.ErrorResponse(c, utils.ErrWDAmountRange, startTime)
		return
	}
	
	if !utils.IsValidString(req.WD_Account) {
		utils.ErrorResponse(c, utils.ErrWDAccountInvalid, startTime)
		return
	}
	
	if !utils.ValidateBankAccount(req.WD_Account) {
		utils.ErrorResponse(c, utils.ErrWDAccountFormat, startTime)
		return
	}
	
	wdDate := time.Now().Truncate(24 * time.Hour)
	wdDateTime := time.Now()
	
	// 插入MatchWagers表
	insertQuery := `INSERT INTO MatchWagers (WD_ID, WD_Amount, WD_Account, WD_Date, WD_DateTime, State) 
	                VALUES (?, ?, ?, ?, ?, ?)`
	                
	result, err := database.GetWriteDB().Exec(insertQuery, req.WD_ID, req.WD_Amount, req.WD_Account, wdDate, wdDateTime, "Order")
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	// 獲取插入的ID
	wid, err := result.LastInsertId()
	if err != nil {
		utils.ErrorResponse(c, utils.ErrUpdateFailed, startTime)
		return
	}
	
	logData := models.LogDetail{
		Action:    "create_order",
		Timestamp: time.Now(),
		Details: map[string]interface{}{
			"WD_ID":     req.WD_ID,
			"WD_Amount": req.WD_Amount,
			"WD_Account": req.WD_Account,
		},
	}
	
	if err := models.CreateLog(int(wid), req.WD_ID, "Order", logData); err != nil {
		log.Printf("Failed to create MatchLog for order %d: %v", wid, err)
	}
	
	response := map[string]interface{}{
		"WID":         int(wid),
		"WD_ID":       req.WD_ID,
		"WD_Amount":   req.WD_Amount,
		"WD_Datetime": wdDateTime.Format("2006-01-02 15:04:05"),
		"WD_Account":  req.WD_Account,
	}
	
	utils.SuccessResponse(c, response, startTime)
} 