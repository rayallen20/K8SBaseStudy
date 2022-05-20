#!/bin/bash
TAG=$1
docker build -t harbor.k8s.com/erp/wordpress-php-5.6:${TAG} . --network=host
echo "build image success"
sleep 1
docker push harbor.k8s.com/erp/wordpress-php-5.6:${TAG}
echo "push image success"
