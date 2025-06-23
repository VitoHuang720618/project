package utils

import (
	"errors"
	"regexp"
	"time"
)

func ValidateAmount(amount int) bool {
	validAmounts := []int{1000, 5000, 10000, 20000}
	for _, valid := range validAmounts {
		if amount == valid {
			return true
		}
	}
	return false
}

func ValidateBankAccount(account string) bool {
	if account == "" {
		return false
	}
	matched, _ := regexp.MatchString(`^\d{10,16}$`, account)
	return matched
}

func ValidateDateRange(dateS, dateE string) (string, string, error) {
	if dateS == "" || dateE == "" {
		return "", "", errors.New("日期參數不能為空")
	}
	
	startDate, err := time.Parse("2006-01-02", dateS)
	if err != nil {
		return "", "", errors.New("日期格式錯誤")
	}
	
	endDate, err := time.Parse("2006-01-02", dateE)
	if err != nil {
		return "", "", errors.New("日期格式錯誤")
	}
	
	if endDate.Before(startDate) {
		dateS, dateE = dateE, dateS
		startDate, endDate = endDate, startDate
	}
	
	if endDate.Sub(startDate).Hours() > 24*90 {
		return "", "", errors.New("搜尋日期區間超過三個月")
	}
	
	return dateS, dateE, nil
}

func ValidateState(state string) bool {
	if state == "" {
		return false
	}
	
	validStates := []string{"All", "Order", "Rejected", "Matching", "Success", "Cancel"}
	for _, valid := range validStates {
		if state == valid {
			return true
		}
	}
	return false
}

func IsValidID(id int) bool {
	return id > 0
}

func IsValidString(str string) bool {
	return str != ""
} 