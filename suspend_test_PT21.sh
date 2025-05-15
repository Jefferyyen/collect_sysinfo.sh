#!/bin/bash

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 設定日誌檔案路徑
SCRIPT_DIR="$(dirname "$0")"
LOG_FILE="$SCRIPT_DIR/suspend_test_$(date +%Y%m%d_%H%M%S).log"

# 初始化計數器
counter=1
counter_entry=0
counter_exit=0


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

# 捕捉 Ctrl+C 信號
trap 'echo -e "\n${YELLOW}收到中斷信號，正在完成最後一次測試...${NC}"; exit_flag=1' SIGINT SIGTERM
exit_flag=0

while [ $exit_flag -eq 0 ]; do
    echo -e "\n${GREEN}=== 開始第 $counter 次測試" 
    #未偵測到suspend entry次數：$counter_entry，未偵測到suspend exit次數: $counter_exit"   
    echo -e "${YELLOW}等待 5 秒後進行下一次測試...${NC}"
    echo -e "${YELLOW}系統將在 20 秒後自動喚醒${NC}"
    sleep 5
    # 記錄測試開始
    {
        echo "==================================================="
        echo "測試編號: $counter"
        #echo "dmesg未偵測到suspend entry次數: $counter_entry"
        #echo "dmesg未偵測到suspend exit次數: $counter_exit"
        echo "開始時間: $(date)"
        echo "---------------------------------------------------"
    } >> "$LOG_FILE"
    
    # 清除 dmesg
    dmesg -c > /dev/null
    
    # 記錄開始時間
    start_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$start_time] 進入睡眠模式"
    
    # 使用 rtcwake 設定系統在 30 秒後喚醒並進入睡眠
    
    
    rtcwake -m no -s 900
    systemctl suspend

    sleep 2
    cp $LOG_FILE /media/ubuntu/D

    # 記錄喚醒時間
    wake_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$wake_time] 系統喚醒"
    
    

    # Dmesg 檢查
    {
        echo "睡眠開始時間: $start_time"
        echo "喚醒時間: $wake_time"
        echo "---------------------------------------------------"
        echo "系統日誌檢查結果："
        
        # 保存並檢查 dmesg 輸出
        dmesg_output=$(dmesg -T)
        lsblk -f
        # 檢查suspend entry
        echo "suspend entry狀態："
        if echo "$dmesg_output" | grep -i "suspend entry"; then
            echo "suspend entry+1"
        else
            echo "未偵測到suspend entry"
            counter_entry=$((counter_entry + 1))
        fi
        
        # 檢查suspend exit
        echo "suspend exit狀態："
        if echo "$dmesg_output" | grep -i "suspend exit"; then
            echo "suspend exit+1"
        else
            echo "未偵測到suspend exit"
            counter_exit=$((counter_exit + 1))
        fi


        echo "---------------------------------------------------"
        echo "完整 dmesg 輸出（從休眠開始）："
        echo "$dmesg_output"
        echo "---------------------------------------------------"
    } >> "$LOG_FILE"




    # 計數器增加
    counter=$((counter + 1))
    
    echo -e "${YELLOW}等待 25 秒後進行下一次測試...${NC}"
    sleep 30
    
    echo "-------------------"
done

echo -e "${GREEN}測試完成！${NC}"
echo -e "${YELLOW}完整日誌保存在: $LOG_FILE${NC}"
