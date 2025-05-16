#!/usr/bin/env bash
# download_loop.sh  ── 每小時下載一次，完成後刪檔並計數

URL="https://releases.ubuntu.com/noble/ubuntu-24.04.2-wsl-amd64.wsl"   # ← 換成你的連結
DL_DIR="$HOME/Dowloads"                 # ← 存檔夾
LOG="$HOME/ReadWriteFromInternet_$(date +%Y%m%d_%H%M%S).log"            # ← 日誌檔
counter=0                                # 0. 初始計數



while true; do
    #### 1. 顯示本輪次序 ########################################
    echo "$(date '+%F %T') 第 $((counter+1)) 次下載" | tee -a "$LOG"

    #### 2. 到連結下載 ##########################################
    wget -P "$DL_DIR" "$URL" | tee -a "$LOG"
    echo "$(date '+%F %T') 下載完成：$URL" | tee -a "$LOG"
    ls $HOME/Dowloads | tee -a "$LOG"

    #### 3. counter ++ #########################################
    counter=$((counter+1))

    #### 4. sleep 3600 #########################################
    echo "$(date '+%F %T') 休息 3600 秒…" | tee -a "$LOG"
    sleep 36

    #### 5. 刪掉下載檔案 ########################################
    echo "$(date '+%F %T') 清理 $HOME/Downloads" | tee -a "$LOG"
    rm -f /$HOME/Dowloads/ubuntu-24.04.2-wsl-amd64.wsl
    ls $HOME/Dowloads | tee -a "$LOG" 
done
