#!/bin/bash
echo "Starting HMI..."
cd ~/docker
sudo docker compose down --remove-orphans
sudo docker compose up
