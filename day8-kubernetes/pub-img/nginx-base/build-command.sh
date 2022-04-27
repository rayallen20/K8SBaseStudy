#!/bin/bash
docker build -t harbor.k8s.com/pub-images/nginx-base:v1.18.0 . --network=host
sleep 1
docker push harbor.k8s.com/pub-images/nginx-base:v1.18.0