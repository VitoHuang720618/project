package controllers

import (
	"strconv"
	"time"
	"github.com/gin-gonic/gin"
	"match-system/database"
	"match-system/models"
	"match-system/utils"
)

func GetLogsByWager(c *gin.Context) {
	startTime := time.Now()
	
	widStr := c.Param("wid")
	wid, err := strconv.Atoi(widStr)
	if err != nil {
		utils.ErrorResponse(c, 1001, startTime)
		return
	}
	
	pagination := utils.GetPaginationParams(c)
	logs, total, err := models.GetLogsByWID(wid, pagination.Page, pagination.Limit)
	if err != nil {
		utils.ErrorResponse(c, 1005, startTime)
		return
	}
	
	result := utils.CreatePaginationResult(logs, int64(total), pagination)
	utils.SuccessResponse(c, result, startTime)
}

func GetAllLogs(c *gin.Context) {
	startTime := time.Now()
	
	pagination := utils.GetPaginationParams(c)
	state := c.Query("state")
	
	logs, total, err := models.GetAllLogs(pagination.Page, pagination.Limit, state)
	if err != nil {
		utils.ErrorResponse(c, 1005, startTime)
		return
	}
	
	result := utils.CreatePaginationResult(logs, int64(total), pagination)
	utils.SuccessResponse(c, result, startTime)
}

func GetLogsByState(c *gin.Context) {
	startTime := time.Now()
	
	state := c.Param("state")
	pagination := utils.GetPaginationParams(c)
	
	logs, total, err := models.GetAllLogs(pagination.Page, pagination.Limit, state)
	if err != nil {
		utils.ErrorResponse(c, 1005, startTime)
		return
	}
	
	result := utils.CreatePaginationResult(logs, int64(total), pagination)
	utils.SuccessResponse(c, result, startTime)
}

// DatabaseStatus 檢查 Master 和 Slave 資料庫狀態
func DatabaseStatus(c *gin.Context) {
	startTime := time.Now()
	
	status := gin.H{
		"master": gin.H{},
		"slave":  gin.H{},
	}
	
	// 檢查 Master 資料庫
	if err := database.GetWriteDB().Ping(); err != nil {
		status["master"] = gin.H{
			"status": "error",
			"error":  err.Error(),
		}
	} else {
		// 測試寫入操作
		var count int
		err := database.GetWriteDB().QueryRow("SELECT COUNT(*) FROM MatchWagers").Scan(&count)
		if err != nil {
			status["master"] = gin.H{
				"status": "error",
				"error":  err.Error(),
			}
		} else {
			status["master"] = gin.H{
				"status": "ok",
				"count":  count,
				"role":   "write",
			}
		}
	}
	
	// 檢查 Slave 資料庫
	if err := database.GetReadDB().Ping(); err != nil {
		status["slave"] = gin.H{
			"status": "error",
			"error":  err.Error(),
		}
	} else {
		// 測試讀取操作
		var count int
		err := database.GetReadDB().QueryRow("SELECT COUNT(*) FROM MatchWagers").Scan(&count)
		if err != nil {
			status["slave"] = gin.H{
				"status": "error",
				"error":  err.Error(),
			}
		} else {
			status["slave"] = gin.H{
				"status": "ok",
				"count":  count,
				"role":   "read",
			}
		}
	}
	
	utils.SuccessResponse(c, status, startTime)
} 