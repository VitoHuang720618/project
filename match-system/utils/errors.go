package utils

const (
	// Order API 錯誤碼 (10001-10005)
	ErrWDIDInvalid      = 10001
	ErrWDAmountInvalid  = 10002
	ErrWDAccountInvalid = 10003
	ErrWDAccountFormat  = 10004
	ErrWDAmountRange    = 10005

	// Reserve API 錯誤碼 (10011-10014)
	ErrReserveUserIDInvalid = 10011
	ErrReserveAmountInvalid = 10012
	ErrReserveAmountRange   = 10013
	ErrNoMatchingOrder      = 10014

	// Success API 錯誤碼 (10021-10029)
	ErrWagerIDInvalid       = 10021
	ErrSuccessUserIDInvalid = 10022
	ErrDEPIDInvalid         = 10023
	ErrDEPAmountInvalid     = 10024
	ErrNoMatchingData       = 10025
	ErrUserIDMismatch       = 10026
	ErrAmountMismatch       = 10027
	ErrUpdateFailed         = 10028
	ErrDEPAmountRange       = 10029

	// Cancel/Rejected API 錯誤碼 (10031-10034)
	ErrCancelWagerIDInvalid = 10031
	ErrCancelUserIDInvalid  = 10032
	ErrCancelNoData         = 10033
	ErrCancelUserIDMismatch = 10034

	// GetWagersList API 錯誤碼 (10041-10043)
	ErrDateInvalid     = 10041
	ErrDateRangeExceed = 10042
	ErrStateInvalid    = 10043
)

var ErrorMessages = map[int]string{
	ErrWDIDInvalid:          "WD_ID 參數錯誤",
	ErrWDAmountInvalid:      "WD_Amount 參數錯誤",
	ErrWDAccountInvalid:     "WD_Account 參數錯誤",
	ErrWDAccountFormat:      "WD_Account 參數不合法",
	ErrWDAmountRange:        "WD_Amount 金額不符合規定",
	ErrReserveUserIDInvalid: "Reserve_UserID 參數錯誤",
	ErrReserveAmountInvalid: "Reserve_Amount 參數錯誤",
	ErrReserveAmountRange:   "Reserve_Amount 金額不符合規定",
	ErrNoMatchingOrder:      "無匹配出款單",
	ErrWagerIDInvalid:       "WagerID 參數錯誤",
	ErrSuccessUserIDInvalid: "Reserve_UserID 參數錯誤",
	ErrDEPIDInvalid:         "DEP_ID 參數錯誤",
	ErrDEPAmountInvalid:     "DEP_Amount 參數錯誤",
	ErrNoMatchingData:       "查無此筆資料",
	ErrUserIDMismatch:       "輸入 Reserve_UserID 與資料 Reserve_UserID 不符",
	ErrAmountMismatch:       "輸入 DEP_Amount 與資料 WD_Amount 不符",
	ErrUpdateFailed:         "修改錯誤",
	ErrDEPAmountRange:       "DEP_Amount 金額不符合規定",
	ErrCancelWagerIDInvalid: "WagerID 參數錯誤",
	ErrCancelUserIDInvalid:  "Reserve_UserID 參數錯誤",
	ErrCancelNoData:         "查無此筆資料",
	ErrCancelUserIDMismatch: "輸入 Reserve_UserID 與資料 Reserve_UserID 不符",
	ErrDateInvalid:          "日期參數錯誤",
	ErrDateRangeExceed:      "搜尋日期區間超過三個月",
	ErrStateInvalid:         "委託單狀態參數錯誤",
} 