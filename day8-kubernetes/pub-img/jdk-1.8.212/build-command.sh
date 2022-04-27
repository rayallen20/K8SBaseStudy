#!/bin/bash
docker build -t harbor.k8s.com/pub-images/jdk-base:v8.212 . 
sleep 1
docker push harbor.k8s.com/pub-images/jdk-base:v8.212