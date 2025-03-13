#!/usr/bin/env bash

# dump system info to the systeminfo.txt
# if want to do append，change ">" into ">>"
# chmod +x collect_sysinfo.sh
# execute ./collect_sysinfo.sh


{
  echo "===== BIOS version ====="
  sudo dmidecode -s bios-version
  echo

  echo "===== df -h ====="
  df -h
  echo

  echo "===== lsblk -f ====="
  lsblk -f
  echo

  echo "===== lspci ====="
  lspci
  echo

  echo "===== lsusb ====="
  lsusb
  echo

  echo "===== lscpu ====="
  lscpu
  echo

  echo "===== lshw -short ====="
  sudo lshw -short
  echo

  echo "===== uname -r ====="
  uname -r
  echo

  echo "===== uname -a ====="
  uname -a
  echo

  echo "===== ubuntu-report show | grep DCD ====="
  ubuntu-report show | grep DCD
  echo

  echo "===== lsb_release -a ====="
  lsb_release -a
  echo
} > systeminfo.txt

echo "All info saved in systeminfo.txt"
