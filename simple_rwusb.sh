#!/bin/bash

MOUNT_POINT="/media/mf/UBUNTU 24_0"
TEST_FILE="$MOUNT_POINT/testfile"
FILE_SIZE_MB=100

while true; do
  echo "寫入測試...${FILE_SIZE_MB}MB"
  dd if=/dev/zero of="$TEST_FILE" bs=1M count=$FILE_SIZE_MB conv=fdatasync

  echo "清除快取..."
  sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"

  echo "讀取測試...${FILE_SIZE_MB}MB"
  dd if="$TEST_FILE" of=/dev/null bs=1M count=$FILE_SIZE_MB

  echo "sleep 1 秒"
  sleep 1
done
