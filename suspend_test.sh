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
counter_net=0
counter_device_inaccessible=0
counter_down=0


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
    echo "網路卡資訊: $(ethtool -i enp4s0)"
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
    echo -e "\n${GREEN}=== 開始第 $counter 次測試，網路連線異常累計次數: $counter_net，發現link down累計次數: $counter_down，發現device inaccessible次數：$counter_device_inaccessible ===${NC}"   
    echo -e "${YELLOW}等待 5 秒後進行下一次測試...${NC}"
    echo -e "${YELLOW}系統將在 20 秒後自動喚醒${NC}"
    sleep 5
    # 記錄測試開始
    {
        echo "==================================================="
        echo "測試編號: $counter"
        echo "網路連線異常累計次數: $counter_net"
        echo "dmesg發現link down累計次數: $counter_down"
        echo "dmesg發現device inaccessible累計次數: $counter_device_inaccessible"
        echo "開始時間: $(date)"
        echo "---------------------------------------------------"
    } >> "$LOG_FILE"
    
    # 清除 dmesg
    dmesg -c > /dev/null
    
    # 記錄開始時間
    start_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$start_time] 進入睡眠模式"
    
    # 使用 rtcwake 設定系統在 20 秒後喚醒並進入睡眠
    
    
    rtcwake -m no -s 10
    systemctl suspend

    sleep 1 

    # 記錄喚醒時間
    wake_time=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$wake_time] 系統喚醒"
    

    # 等待網路恢復（5秒）
    echo "等待網路恢復（10秒）..."
    sleep 10
    

    # Dmesg 檢查
    {
        echo "睡眠開始時間: $start_time"
        echo "喚醒時間: $wake_time"
        echo "---------------------------------------------------"
        echo "系統日誌檢查結果："
        
        # 保存並檢查 dmesg 輸出
        dmesg_output=$(dmesg -T)
        
        # 檢查網路介面狀態
        echo "網路介面狀態："
        if echo "$dmesg_output" | grep -i "enp4s0: Link is Up"; then
            echo "enp4s0: Link is Up"
        else
            echo "未偵測到enp4s0: Link is Up"
            counter_down=$((counter_down + 1))
        fi

        # 檢查錯誤訊息
        echo "錯誤訊息檢查："
        if echo "$dmesg_output" | grep -i "device inaccessible"; then
            echo "發現裝置無法存取錯誤！"
            counter_device_inaccessible=$((counter_device_inaccessible + 1))
        fi
        
        echo "---------------------------------------------------"
        echo "完整 dmesg 輸出（從休眠開始）："
        echo "$dmesg_output"
        echo "---------------------------------------------------"
    } >> "$LOG_FILE"

    # Ping 檢查
    {
        echo "網路連線測試結果："
        echo ""
        # 執行 ping 測試並儲存結果
        ping_result=$(ping -c 4 8.8.8.8 2>&1)
        echo "$ping_result"
        
        # 檢查並記錄 ping 測試結果
        if echo "$ping_result" | grep -q "0% packet loss"; then
            echo "測試結果: Pass - 網路連線正常"
        else
            echo "測試結果: Fail - 網路連線異常"
            counter_net=$((counter_net + 1))
        fi
        
        echo "==================================================="
        echo ""
    } >> "$LOG_FILE"

    # 檢查device inaccessible
    if grep -q -i "device inaccessible" <<< "$dmesg_output"; then
        echo -e "${RED}發現錯誤：device inaccessible${NC}"
    else
        echo -e "${GREEN}未發現 device inaccessible${NC}"   
    fi
    
    # 檢查enp4s0: Link狀態
    if grep -q -i "enp4s0: Link is Up" <<< "$dmesg_output"; then
        echo -e "${GREEN}enp4s0:Link is Up${NC}"
    else
        echo -e "${RED}未發現enp4s0:Link is Up${NC}"
    fi

    # 檢查 ping 結果
    if ! echo "$ping_result" | grep -q "0% packet loss"; then
        echo -e "${RED}ping test發現loss！${NC}"
    else
        echo -e "${GREEN}ping test正常${NC}"
    fi


    # 計數器增加
    counter=$((counter + 1))
    
    echo -e "${YELLOW}等待 25 秒後進行下一次測試...${NC}"
    sleep 20
    
    echo "-------------------"
done

echo -e "${GREEN}測試完成！${NC}"
echo -e "${YELLOW}完整日誌保存在: $LOG_FILE${NC}"
