#!/bin/sh

sed -i "s/__TARGET_SCHEME__/$TARGET_SCHEME/g" /etc/nginx/nginx.conf
sed -i "s/__TARGET_HOST__/$TARGET_HOST/g" /etc/nginx/nginx.conf
