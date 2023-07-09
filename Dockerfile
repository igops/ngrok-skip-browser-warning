FROM nginx:alpine
LABEL maintainer="igops <hi@igops.me>"

RUN apk add --no-cache bash unzip py-pip && \
    pip install jinja-cli

ENV NGROK_HOST ""

ENV PROXY_HOST_REST "ngrok.localhost.direct"
ENV PROXY_HOST_WS_SUPPORT "ngrok-ws.localhost.direct"
ENV PROXY_HOST_SSE_SUPPORT "ngrok-sse.localhost.direct"
ENV PROXY_USE_SSL "true"
ENV PROXY_FORCE_HTTPS "false"
ENV PROXY_SSL_CERT_NAME "localhost.direct.crt"
ENV PROXY_SSL_KEY_NAME "localhost.direct.key"

ENV ADD_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN ""

RUN mkdir -p /etc/nginx/j2
COPY nginx/default.j2.conf /etc/nginx/j2

COPY entrypoint.sh /docker-entrypoint.d
RUN chmod +x /docker-entrypoint.d/entrypoint.sh

CMD ["nginx", "-g", "daemon off;"]
