#!/bin/bash

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

if [ -z "$PROXY_HOST_REST" ]; then
  PROXY_HOST_REST="ngrok.localhost.direct"
fi

if [ -z "$PROXY_HOST_WS_SUPPORT" ]; then
  PROXY_HOST_WS_SUPPORT="ngrok-ws.localhost.direct"
fi

if [ -z "$PROXY_HOST_SSE_SUPPORT" ]; then
  PROXY_HOST_SSE_SUPPORT="ngrok-sse.localhost.direct"
fi

if [ -z "$PROXY_USE_SSL" ]; then
  PROXY_USE_SSL="true"
fi
PROXY_USE_SSL=${PROXY_USE_SSL,,}

if [ -z "$PROXY_FORCE_HTTPS" ]; then
  PROXY_FORCE_HTTPS="false"
fi
PROXY_FORCE_HTTPS=${PROXY_FORCE_HTTPS,,}

if [ -z "$PROXY_SSL_CERT_NAME" ]; then
  PROXY_SSL_CERT_NAME="localhost.direct.crt"
fi

if [ -z "$PROXY_SSL_KEY_NAME" ]; then
  PROXY_SSL_KEY_NAME="localhost.direct.key"
fi

if [ -z "$ADD_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN" ]; then
  ADD_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN=""
fi

if [ "$PROXY_USE_SSL" = "true" ]; then
  CERTS_DIR=/etc/nginx/certs
  mkdir -p /etc/nginx/certs

  if [ -z "$(ls -A $CERTS_DIR)" ]; then
    echo "Downloading localhost.direct certificates..."
    curl -o certs.zip -LOs https://aka.re/localhost
    unzip -P localhost certs.zip
    rm certs.zip
    mv localhost.direct.* $CERTS_DIR
  else
    echo "Using existing SSL certificates..."
  fi
fi

jinja \
  -D ProxyHostREST "$PROXY_HOST_REST" \
  -D ProxyHostWSSupport "$PROXY_HOST_WS_SUPPORT" \
  -D ProxyHostSSESupport "$PROXY_HOST_SSE_SUPPORT" \
  -D ProxyUseSSL "$PROXY_USE_SSL" \
  -D ProxySSLCertName "$PROXY_SSL_CERT_NAME" \
  -D ProxySSLKeyName "$PROXY_SSL_KEY_NAME" \
  -D ProxyForceHTTPS "$PROXY_FORCE_HTTPS" \
  -D TargetScheme "$TARGET_SCHEME" \
  -D TargetHost "$TARGET_HOST" \
  -D AddHeaderAccessControlAllowOrigin "$ADD_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN" \
  -o /etc/nginx/conf.d/default.conf \
  /etc/nginx/j2/default.j2.conf
