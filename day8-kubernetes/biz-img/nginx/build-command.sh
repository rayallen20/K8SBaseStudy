#!/bin/bash
TAG=$1
docker build -t harbor.k8s.com/erp/nginx-webapp:${TAG} . 
echo "build image complete.Start push image to harbor now."
sleep 1
docker push harbor.k8s.com/erp/nginx-webapp:${TAG}
echo "Push image successfully."