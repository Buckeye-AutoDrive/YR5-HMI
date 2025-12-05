#!/bin/bash

echo "=== HMI Startup Script ==="

if [ ! -d "/home/hmi/YR5-HMI/.git" ]; then
    echo "ERROR: YR5-HMI is not a git repo on host!"
    echo "Clone it on host:  git clone https://github.com/Buckeye-AutoDrive/YR5-HMI.git"
    exit 1
fi

cd /home/hmi/YR5-HMI

# OPTIONAL automatic pull — but comment it out
#echo "Checking internet..."
#if ping -c 1 github.com > /dev/null 2>&1 ; then
#    echo "Internet OK → git pull"
#    git pull --rebase --autostash
#else
#    echo "No internet → using local repo"
#fi

echo "Building HMI from local code..."
cmake -B build -S .
cmake --build build -j$(nproc)

echo "Running HMI..."
./build/appHMI_Mk1
