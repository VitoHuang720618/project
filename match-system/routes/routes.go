package routes

import (
	"match-system/controllers"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(r *gin.Engine) {
	api := r.Group("/api")
	{
		api.POST("/order", controllers.CreateOrder)
		api.POST("/reserve", controllers.CreateReserve)
		api.POST("/success", controllers.MatchSuccess)
		api.POST("/cancel", controllers.CancelMatch)
		api.POST("/rejected", controllers.RejectMatch)
		api.POST("/getwagerslist", controllers.GetWagersList)
		api.POST("/getrejectedlist", controllers.GetRejectedList)
		api.POST("/getmatchinglist", controllers.GetMatchingList)
		
		api.GET("/logs", controllers.GetAllLogs)
		api.GET("/logs/wager/:wid", controllers.GetLogsByWager)
		api.GET("/logs/state/:state", controllers.GetLogsByState)
	}
} 