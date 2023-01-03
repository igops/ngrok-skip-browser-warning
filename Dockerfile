FROM nginx

LABEL maintainer="igops <hi@igops.me>"

ENV TARGET_HOST undefined
ENV TARGET_SCHEME https

COPY nginx.conf /etc/nginx/
COPY replace-host.sh /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/replace-host.sh

CMD ["nginx", "-g", "daemon off;"]