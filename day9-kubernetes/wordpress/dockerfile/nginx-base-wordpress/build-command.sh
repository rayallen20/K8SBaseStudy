#!/bin/bash
docker build -t harbor.k8s.com/pub-images/nginx-base-wordpress:v1.14.2  . --network=host
sleep 1
docker push  harbor.k8s.com/pub-images/nginx-base-wordpress:v1.14.2
