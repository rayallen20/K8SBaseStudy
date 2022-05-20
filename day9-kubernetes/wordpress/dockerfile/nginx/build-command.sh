#!/bin/bash
TAG=$1
docker build -t harbor.k8s.com/erp/wordpress-nginx:${TAG} .
echo "build image success!"
sleep 1
docker push harbor.k8s.com/erp/wordpress-nginx:${TAG}
echo "push image success!"
