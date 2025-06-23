package controllers

import (
	"strconv"
	"time"
	"github.com/gin-gonic/gin"
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