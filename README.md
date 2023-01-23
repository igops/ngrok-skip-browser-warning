## Preface
From the ngrok [docs](https://ngrok.com/abuse):

> _To block phishing attacks using our platform, ngrok has added an interstitial page for free accounts receiving requests from browsers. When a user visits an endpoint for the first time, ngrok will serve an interstitial page letting the user know that the content is served via ngrok and that they should not enter sensitive information unless they trust the person that sent them the link. Users should only see this page once per endpoint and it can be completely bypassed by adding the `ngrok-skip-browser-warning` header to your request._

![proxy](https://raw.githubusercontent.com/igops/ngrok-skip-browser-warning/main/proxy-1.png)

It's tedious to add this header while developing a client for the API, which is exposed behind ngrok. In some cases, e.g. using [EventSource](https://developer.mozilla.org/en-US/docs/Web/API/EventSource), affecting the request headers seems to be impossible.

## Usage
To automate skipping a warning page, use this simple HTTP proxy:
```shell
$ docker run -d --rm -p 8080:80 -e NGROK_HOST=https://your-ngrok-domain.ngrok.io igops/ngrok-skip-browser-warning:latest
```

From now, use `http://localhost:8080` as your API webroot:

![proxy](https://raw.githubusercontent.com/igops/ngrok-skip-browser-warning/main/proxy-2.png)

## Disclaimer
⚠️ The purpose of this docker image is to ease your development process. Running a proxy locally does not facilitate phishing attacks until you expose your local network to the public. This image is provided "as is", without warranty of any kind, no matter what.

For more features, consider getting the [ngrok subscription](https://ngrok.com/pricing).

## Customization
Feel free to replace `/etc/nginx/nginx.conf` with your own implementation, or use [this template](https://github.com/igops/ngrok-skip-browser-warning/blob/main/nginx.conf) in your managed nginx.

A bare minimum nginx.conf for your experiments:
```nginx
events {
    worker_connections 1024;
}
http {
    server {
        listen 80;
        location / {
            # regular forwarding headers
            proxy_set_header X-Forwarded-For $proxy_protocol_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host __TARGET_HOST__;
            
            # this line does the actual trick 😃
            proxy_set_header ngrok-skip-browser-warning 1;

            # add more features you need
            # proxy_set_header ...
            
            # forward!
            proxy_pass https://__TARGET_HOST__;
        }
    }
}
```

Build a new image to test your conf:
```Dockerfile
FROM igops/ngrok-skip-browser-warning:latest
COPY my.conf /etc/nginx/nginx.conf
```

Run your variant:
```shell
$ docker run -d --rm -p 8080:80 -e NGROK_HOST=https://your-ngrok-domain.ngrok.io $(docker build -q /path/to/your/Dockerfile)
```

Feel free to [contribute](https://github.com/igops/ngrok-skip-browser-warning).

## ENV variables
| Variable                      | Description                                                                                                                                                                                               |
|-------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NGROK_HOST                    | **Mandatory**. Your ngrok host, e.g. `https://your-ngrok-domain.ngrok.io`.<br/>Specifying a protocol is optional, `https` will be used by default.<br/>Any url parts after a domain name will be trimmed. |

## Source code
https://github.com/igops/ngrok-skip-browser-warning

## Credits
[@igops](https://github.com/igops)
[@muratx10](https://github.com/muratx10)
