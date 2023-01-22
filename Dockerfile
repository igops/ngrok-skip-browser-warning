FROM nginx:alpine
LABEL maintainer="igops <hi@igops.me>"

ENV NGROK_HOST ""

COPY nginx.conf /etc/nginx/
COPY replace-host.sh /docker-entrypoint.d/
RUN chmod +x /docker-entrypoint.d/replace-host.sh

CMD ["nginx", "-g", "daemon off;"]
