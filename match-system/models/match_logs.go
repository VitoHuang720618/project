package models

import (
	"database/sql"
	"encoding/json"
	"time"
	"match-system/database"
)

type MatchLog struct {
	ID          int       `json:"id"`
	WID         int       `json:"wid"`
	WD_ID       int       `json:"wd_id"`
	State       string    `json:"state"`
	LogData     LogDetail `json:"log_data"`
	CreatedAt   time.Time `json:"created_at"`
}

type LogDetail struct {
	Action    string                 `json:"action"`
	FromState string                 `json:"from_state,omitempty"`
	ToState   string                 `json:"to_state,omitempty"`
	Timestamp time.Time              `json:"timestamp"`
	Details   map[string]interface{} `json:"details,omitempty"`
}

func CreateLog(wid, wdID int, state string, logData LogDetail) error {
	logDataJSON, err := json.Marshal(logData)
	if err != nil {
		return err
	}
	
	query := `INSERT INTO MatchLogs (WID, WD_ID, State, LogData) VALUES (?, ?, ?, ?)`
	_, err = database.GetWriteDB().Exec(query, wid, wdID, state, string(logDataJSON))
	return err
}

func GetLogsByWID(wid int, page, limit int) ([]MatchLog, int, error) {
	offset := (page - 1) * limit
	
	// 計算總數
	var total int
	countQuery := `SELECT COUNT(*) FROM MatchLogs WHERE WID = ?`
	err := database.GetReadDB().QueryRow(countQuery, wid).Scan(&total)
	if err != nil {
		return nil, 0, err
	}
	
	// 查詢數據
	query := `SELECT ID, WID, WD_ID, State, LogData, CreatedAt 
	          FROM MatchLogs 
	          WHERE WID = ? 
	          ORDER BY CreatedAt DESC 
	          LIMIT ? OFFSET ?`
	
	rows, err := database.GetReadDB().Query(query, wid, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	
	var logs []MatchLog
	for rows.Next() {
		var log MatchLog
		var logDataJSON string
		
		err := rows.Scan(&log.ID, &log.WID, &log.WD_ID, &log.State, &logDataJSON, &log.CreatedAt)
		if err != nil {
			return nil, 0, err
		}
		
		// 解析JSON
		if err := json.Unmarshal([]byte(logDataJSON), &log.LogData); err != nil {
			return nil, 0, err
		}
		
		logs = append(logs, log)
	}
	
	return logs, total, rows.Err()
}

func GetAllLogs(page, limit int, state string) ([]MatchLog, int, error) {
	offset := (page - 1) * limit
	
	var total int
	var logs []MatchLog
	var countQuery, dataQuery string
	var countArgs, dataArgs []interface{}
	
	if state != "" {
		countQuery = `SELECT COUNT(*) FROM MatchLogs WHERE State = ?`
		countArgs = []interface{}{state}
		
		dataQuery = `SELECT ID, WID, WD_ID, State, LogData, CreatedAt 
		             FROM MatchLogs 
		             WHERE State = ? 
		             ORDER BY CreatedAt DESC 
		             LIMIT ? OFFSET ?`
		dataArgs = []interface{}{state, limit, offset}
	} else {
		countQuery = `SELECT COUNT(*) FROM MatchLogs`
		countArgs = []interface{}{}
		
		dataQuery = `SELECT ID, WID, WD_ID, State, LogData, CreatedAt 
		             FROM MatchLogs 
		             ORDER BY CreatedAt DESC 
		             LIMIT ? OFFSET ?`
		dataArgs = []interface{}{limit, offset}
	}
	
	// 計算總數
	err := database.GetReadDB().QueryRow(countQuery, countArgs...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}
	
	// 查詢數據
	rows, err := database.GetReadDB().Query(dataQuery, dataArgs...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	
	for rows.Next() {
		var log MatchLog
		var logDataJSON sql.NullString
		
		err := rows.Scan(&log.ID, &log.WID, &log.WD_ID, &log.State, &logDataJSON, &log.CreatedAt)
		if err != nil {
			return nil, 0, err
		}
		
		// 解析JSON
		if logDataJSON.Valid {
			if err := json.Unmarshal([]byte(logDataJSON.String), &log.LogData); err != nil {
				return nil, 0, err
			}
		}
		
		logs = append(logs, log)
	}
	
	return logs, total, rows.Err()
} 