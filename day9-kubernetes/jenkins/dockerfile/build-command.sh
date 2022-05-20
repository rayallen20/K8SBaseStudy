#!/bin/bash
docker build -t harbor.k8s.com/erp/jenkins:v2.190.1 . --network=host
echo "build image success!"
sleep 1
docker push harbor.k8s.com/erp/jenkins:v2.190.1
echo "push image success!"