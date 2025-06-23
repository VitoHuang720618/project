package utils

import (
	"strconv"
	"github.com/gin-gonic/gin"
)

type PaginationParams struct {
	Page   int `json:"page"`
	Limit  int `json:"limit"`
	Offset int `json:"offset"`
}

type PaginationResult struct {
	Data  interface{} `json:"data"`
	Total int64       `json:"total"`
	Page  int         `json:"page"`
	Limit int         `json:"limit"`
	Pages int         `json:"pages"`
}

type PaginationRequest struct {
	Page  int `json:"page"`
	Limit int `json:"limit"`
}

func GetPaginationParams(c *gin.Context) PaginationParams {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	
	offset := (page - 1) * limit
	
	return PaginationParams{
		Page:   page,
		Limit:  limit,
		Offset: offset,
	}
}

func GetPaginationFromJSON(req PaginationRequest) PaginationParams {
	page := req.Page
	limit := req.Limit
	
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}
	
	offset := (page - 1) * limit
	
	return PaginationParams{
		Page:   page,
		Limit:  limit,
		Offset: offset,
	}
}

func CreatePaginationResult(data interface{}, total int64, params PaginationParams) PaginationResult {
	pages := int((total + int64(params.Limit) - 1) / int64(params.Limit))
	
	return PaginationResult{
		Data:  data,
		Total: total,
		Page:  params.Page,
		Limit: params.Limit,
		Pages: pages,
	}
} 