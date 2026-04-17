#!/bin/bash

echo "Cleaning old processes..."
pkill -f spring-boot
pkill -f node

sleep 2

echo "Starting backend..."
cd ~/student-management-devops
mvn spring-boot:run &

sleep 5

echo "Starting frontend..."
cd ~/student-management-devops/student-frontend-react
npm start
