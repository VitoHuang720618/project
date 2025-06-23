package models

import "time"

type MatchWagers struct {
	WID              int        `json:"WID"`               // 委託單ID
	WD_ID            int        `json:"WD_ID"`             // 出款單號
	WD_Amount        int16      `json:"WD_Amount"`         // 出款單金額
	WD_Account       string     `json:"WD_Account"`        // 出款單帳戶
	WD_Date          time.Time  `json:"WD_Date"`           // 出款單日期
	WD_DateTime      time.Time  `json:"WD_DateTime"`       // 出款單新增時間
	State            string     `json:"State"`             // 狀態
	Reserve_UserID   *int       `json:"Reserve_UserID"`    // 預約入款會員ID
	Reserve_DateTime *time.Time `json:"Reserve_DateTime"`  // 會員預約時間
	DEP_ID           *int       `json:"DEP_ID"`            // 入款單號
	DEP_Amount       *int16     `json:"DEP_Amount"`        // 入款單金額
	Finish_DateTime  *time.Time `json:"Finish_DateTime"`   // 完成時間
} 