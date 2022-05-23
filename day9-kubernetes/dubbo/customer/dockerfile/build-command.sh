#!/bin/bash
TAG=$1
docker build -t harbor.k8s.com/erp/dubbo-demo-consumer:${TAG} . --network=host
sleep 3
docker push harbor.k8s.com/erp/dubbo-demo-consumer:${TAG}