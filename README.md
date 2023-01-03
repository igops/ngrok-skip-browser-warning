From the ngrok [docs](https://ngrok.com/abuse):

> _To block phishing attacks using our platform, ngrok has added an interstitial page for free accounts receiving requests from browsers. When a user visits an endpoint for the first time, ngrok will serve an interstitial page letting the user know that the content is served via ngrok and that they should not enter sensitive information unless they trust the person that sent them the link. Users should only see this page once per endpoint and it can be completely bypassed by adding the `ngrok-skip-browser-warning` header to your request._

It's tedious to add this header while developing a client for the API, which is exposed behind ngrok. In some cases, e.g. using [EventSource](https://developer.mozilla.org/en-US/docs/Web/API/EventSource), affecting the request headers seems to be impossible.

To overcome this, use this simple HTTP proxy:
```shell
$ docker run -d --rm -p 8080:80 -e TARGET_HOST=your-domain.ngrok.io igops/ngrok-skip-browser-warning:latest
```

Then, use `http://localhost:8080` as your API webroot.

![proxy](https://github.com/igops/ngrok-skip-browser-warning/blob/main/proxy.jpeg)

Feel free to replace `/etc/nginx/nginx.conf` with your own implementation, or use this template in your managed nginx:
```nginx
events {
    worker_connections 1024;
}
http {
    server {
        listen 80;

        location / {
            proxy_set_header X-Forwarded-For $proxy_protocol_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host __TARGET_HOST__;

            # this line does the actual trick
            proxy_set_header ngrok-skip-browser-warning 1;

            # SSE support
            # https://stackoverflow.com/a/13673298/20085654
            proxy_set_header Connection '';
            proxy_http_version 1.1;
            chunked_transfer_encoding off;
            proxy_buffering off;
            proxy_cache off;

            # using "proxy_pass $variable" allows to avoid start-up crash if host is not reachable
            # https://stackoverflow.com/a/32846603/20085654
            resolver 8.8.8.8 valid=30s;
            set $upstream __TARGET_SCHEME__://__TARGET_HOST__;
            proxy_pass $upstream;
        }
    }
}
```

ENV variables:
| Variable                     | Description                                                                 |
| -----------------------------| --------------------------------------------------------------------------- |
| TARGET_HOST                  |  your ngrok domain, e.g. `your-domain.ngrok.io`, default is `undefined`     |
| TARGET_SCHEME                |  `http` or `https` for ngrok scheme, default is `https`                     |

[Source code](https://github.com/igops/ngrok-skip-browser-warning)