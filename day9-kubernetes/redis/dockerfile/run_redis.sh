#!/bin/bash

/usr/sbin/redis-server /usr/local/redis/redis.conf

tail -f  /etc/hosts
