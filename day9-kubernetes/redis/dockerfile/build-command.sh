#!/bin/bash
TAG=$1
docker build -t harbor.k8s.com/erp/redis:${TAG} . --network=host
docker push harbor.k8s.com/erp/redis:${TAG}