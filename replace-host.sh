#!/bin/sh

# $TARGET_HOST and $TARGET_SCHEME might be passed in the previous versions, so keeping them as a backward compatibility

if [ -n "$NGROK_HOST" ]; then
  TARGET_SCHEME="$(echo "$NGROK_HOST" | grep :// | sed -e's,^\(\(.*\)://\).*,\2,g')"
  if [ -z "$TARGET_SCHEME" ]; then
    TARGET_SCHEME=https
    NGROK_HOST="https://${NGROK_HOST}"
  fi
  # https://stackoverflow.com/a/11385736/20085654
  TARGET_HOST=$(echo "$NGROK_HOST" | awk -F[/:] '{print $4}')
fi

if [ -z "$TARGET_HOST" ]; then
  echo "Target host cannot be forwarded to. Ensure you have specified a host such as NGROK_HOST=your-ngrok-domain.ngrok.io".
  exit 1
fi

if [ -z "$TARGET_SCHEME" ]; then
  TARGET_SCHEME=https
fi

if [ "$TARGET_SCHEME" != "http" ] && [ "$TARGET_SCHEME" != "https" ]; then
  echo "Unsupported protocol. This is a HTTP proxy, so please use http:// or https://".
  exit 1
fi

sed -i "s/__TARGET_SCHEME__/$TARGET_SCHEME/g" /etc/nginx/nginx.conf
sed -i "s/__TARGET_HOST__/$TARGET_HOST/g" /etc/nginx/nginx.conf
