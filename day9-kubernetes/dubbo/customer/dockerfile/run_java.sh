#!/bin/bash
su - nginx -c "/apps/dubbo/consumer/bin/start.sh"
tail -f /etc/hosts