package utils

import (
	"time"
	"github.com/gin-gonic/gin"
)

type APIResponse struct {
	Success int         `json:"Success"`
	ErrCode int         `json:"ErrCode"`
	Message string      `json:"Message,omitempty"`
	Data    interface{} `json:"Data,omitempty"`
	RunTime int64       `json:"RunTime,omitempty"`
}

func SuccessResponse(c *gin.Context, data interface{}, startTime time.Time) {
	runtime := time.Since(startTime).Milliseconds()
	
	response := APIResponse{
		Success: 1,
		ErrCode: 0,
		RunTime: runtime,
	}
	
	if data != nil {
		response.Data = data
	}
	
	c.JSON(200, response)
}

func ErrorResponse(c *gin.Context, errorCode int, startTime time.Time) {
	runtime := time.Since(startTime).Milliseconds()
	
	response := APIResponse{
		Success: 0,
		ErrCode: errorCode,
		RunTime: runtime,
	}
	
	if message, exists := ErrorMessages[errorCode]; exists {
		response.Message = message
	}
	
	c.JSON(200, response)
}

func QuickSuccessResponse(data interface{}) APIResponse {
	return APIResponse{
		Success: 1,
		ErrCode: 0,
		Data:    data,
	}
}

func QuickErrorResponse(errCode int, message string) APIResponse {
	if message == "" {
		if msg, exists := ErrorMessages[errCode]; exists {
			message = msg
		}
	}
	return APIResponse{
		Success: 0,
		ErrCode: errCode,
		Message: message,
	}
} 