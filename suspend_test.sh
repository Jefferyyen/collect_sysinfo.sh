#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 設定日誌檔案路徑
LOG_FILE="/home/jfy/5gOMstress/suspend_test_$(date +%Y%m%d_%H%M%S).log"

# 檢查是否有 root 權限
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}錯誤：請使用 sudo 執行此腳本${NC}"
    exit 1
fi

# 檢查必要的命令
if ! command -v systemctl &> /dev/null; then
    echo -e "${RED}錯誤：找不到 systemctl 命令${NC}"
    exit 1
fi

if ! command -v ping &> /dev/null; then
    echo -e "${RED}錯誤：找不到 ping 命令${NC}"
    exit 1
fi

if ! command -v rtcwake &> /dev/null; then
    echo -e "${RED}錯誤：找不到 rtcwake 命令${NC}"
    exit 1
fi

# 初始化日誌檔案
{
    echo "==================================================="
    echo "Suspend 測試日誌"
    echo "開始時間: $(date)"
    echo "系統資訊: $(uname -a)"
    echo "==================================================="
    echo ""
} > "$LOG_FILE"

echo -e "${GREEN}開始執行 suspend 測試${NC}"
echo -e "${YELLOW}日誌將保存在: $LOG_FILE${NC}"
echo -e "${YELLOW}按 Ctrl+C 可以安全地結束測試${NC}"

# 計數器
counter=1

# 捕捉 Ctrl+C 信號
trap 'echo -e "\n${YELLOW}收到中斷信號，正在完成最後一次測試...${NC}"; exit_flag=1' SIGINT SIGTERM

exit_flag=0

while [ $exit_flag -eq 0 ]; do
    echo -e "\n${GREEN}=== 開始第 $counter 次測試 ===${NC}"
    
    # 記錄測試開始
    {
        echo "==================================================="
        echo "測試編號: $counter"
        echo "開始時間: $(date)"
        echo "---------------------------------------------------"
    } >> "$LOG_FILE"
    
    # 清除 dmesg
    dmesg -c > /dev/null
    
    # 記錄開始時間
    start_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$start_time] 進入睡眠模式"
    
    # 使用 rtcwake 設定系統在 20 秒後喚醒並進入睡眠
    echo -e "${YELLOW}系統將在 20 秒後自動喚醒${NC}"
    rtcwake -m mem -s 20
    
    # 記錄喚醒時間
    wake_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$wake_time] 系統喚醒"
    
    {
        echo "睡眠開始時間: $start_time"
        echo "喚醒時間: $wake_time"
        echo "---------------------------------------------------"
        echo "系統日誌檢查結果："
        
        # 保存並檢查 dmesg 輸出
        dmesg_output=$(dmesg)
        echo "$dmesg_output" | grep -i "error\|fail\|warn\|critical\|panic"
        
        if [ $? -eq 0 ]; then
            echo "發現錯誤訊息！"
        else
            echo "未發現錯誤訊息"
        fi
        
        echo "---------------------------------------------------"
        echo "完整 dmesg 輸出："
        echo "$dmesg_output"
        echo "---------------------------------------------------"
    } >> "$LOG_FILE"

    # 等待網路恢復（5秒）
    echo "等待網路恢復（5秒）..."
    sleep 5
    
    {
        echo "網路連線測試結果："
        echo ""
        # 直接執行 4 次 ping
        ping -c 4 8.8.8.8 2>&1
        echo "==================================================="
        echo ""
    } >> "$LOG_FILE"
    
    # 顯示測試狀態
    if grep -q -i "error\|fail\|warn\|critical\|panic" <<< "$dmesg_output"; then
        echo -e "${RED}發現錯誤！${NC}"
    else
        echo -e "${GREEN}未發現錯誤${NC}"
    fi
    
    # 計數器增加
    counter=$((counter + 1))
    
    echo -e "${YELLOW}等待 25 秒後進行下一次測試...${NC}"
    sleep 25
    
    echo "-------------------"
done

echo -e "${GREEN}測試完成！${NC}"
echo -e "${YELLOW}完整日誌保存在: $LOG_FILE${NC}"