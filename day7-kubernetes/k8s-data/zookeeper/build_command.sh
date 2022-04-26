#!/bin/bash
TAG=$1
docker build -t harbor.k8s.com/erp/zookeeper:${TAG} .
sleep 1
docker push harbor.k8s.com/erp/zookeeper:${TAG}