A simple HTTPS forward proxy for bypassing browser warning of Ngrok. Full support of SSL (free certificates included!), WebSocket, SSE and CORS.

**Prerequisites:**
- Somebody has sent you a link to an Ngrok endpoint, but it returns a warning page instead of the expected content
- You might be a web developer who is trying to use that endpoint in your code and curious how to bypass the warning page without rewriting the logic
- You have a Docker installed on your machine

OK, take me to the good part: [Usage](#usage)

## Preface
From the ngrok [docs](https://ngrok.com/abuse):

> _To block phishing attacks using our platform, ngrok has added an interstitial page for free accounts receiving requests from browsers. When a user visits an endpoint for the first time, ngrok will serve an interstitial page letting the user know that the content is served via ngrok and that they should not enter sensitive information unless they trust the person that sent them the link. Users should only see this page once per endpoint and it can be completely bypassed by adding the `ngrok-skip-browser-warning` header to your request._

It's tedious to add this header while developing a client for the API, which is exposed behind ngrok. In some cases, e.g. using [EventSource](https://developer.mozilla.org/en-US/docs/Web/API/EventSource), affecting the request headers seems to be impossible.

## Solution

Add a **forward proxy** which will add the `ngrok-skip-browser-warning` header to all HTTP requests:

![proxy](https://raw.githubusercontent.com/igops/ngrok-skip-browser-warning/main/img/ngrok-skip-browser-warning-3.png)

## Disclaimer
⚠️ The purpose of this docker image is to ease your development process. Running a proxy locally does not facilitate phishing attacks until you expose your local network to the public. This image is provided "as is", without warranty of any kind, no matter what.

For more features, consider getting the [ngrok subscription](https://ngrok.com/pricing).

## Usage

### Relay over HTTPS (recommended)

Starting from 2023 July 9th, this image includes setup of a valid public CA signed SSL certificate and supports HTTPS (thanks to [localhost.direct](https://get.localhost.direct) project).

Run this **on the machine from where you are calling the ngrok endpoints**:

```shell
$ docker run -d --rm \
  -p 8443:443 \
  -p 8080:80 \
  -e NGROK_HOST=https://your-ngrok-domain.ngrok.io \
  igops/ngrok-skip-browser-warning:latest
```

From now, use `https://ngrok.localhost.direct:8443` as your API webroot.

E.g., you were told to call `GET https://your-ngrok-domain.ngrok.io/api/v1/whatever`. Now you just call `GET https://ngrok.localhost.direct:8443/api/v1/whatever` instead, and get the response **without the warning page!**

`*.localhost.direct` is a wildcard record of the public DNS pointing to `127.0.0.1`. You might want to customize the domain name to bind the proxy to, as well as the SSL certificates (see [ENV Variables](#env-variables) below).

### Relay over HTTP (not recommended)

If for some reason you don't want to use HTTPS relay, you can continue using `http://ngrok.localhost.direct:8080` or `http://localhost:8080` as your API webroot.

You can disable all SSL-related features by passing `PROXY_USE_SSL=false` environment variable:
```shell
$ docker run -d --rm \
  -p 8080:80 \
  -e NGROK_HOST=https://your-ngrok-domain.ngrok.io \
  -e PROXY_USE_SSL=false \
  igops/ngrok-skip-browser-warning:latest
```

### WebSocket and SSE Support

WebSocket and SSE protocols require a special handling of the `Upgrade` and `Connection` headers. This image supports both protocols out of the box.

However, to distinguish WebSocket and SSE requests from regular HTTP requests, I have implemented the conditional routing based on the request domain names:

| Protocol            | Over HTTPS                                | Over HTTP                                |
|---------------------|-------------------------------------------|------------------------------------------|
| REST, GraphQL, etc. | `https://ngrok.localhost.direct:8443`     | `http://ngrok.localhost.direct:8080`     |
| WebSocket           | `wss://ngrok-ws.localhost.direct:8443`    | `ws://ngrok-ws.localhost.direct:8080`    |
| SSE                 | `https://ngrok-sse.localhost.direct:8443` | `http://ngrok-sse.localhost.direct:8080` |

You can customize the domain names on your own (see [ENV Variables](#env-variables)) or even the entire routing model (check out the [Customization](#customization) section).

If you're developing a web client which communicates with the HTTP server via multiple protocols, it's worth introducing some configurable constants, such as:
[![js-client](https://raw.githubusercontent.com/igops/ngrok-skip-browser-warning/main/img/js-client.png)](https://github.com/igops/ngrok-skip-browser-warning/blob/main/examples/js-client.js)
<p align="center"><sub>Click on the image to show the text version</sub></p>


Support of WebSocket and SSE was tested by running the [Echo Server](https://github.com/jmalloc/echo-server) behind a free ngrok tunnel. Consider reporting an issue if you find any problems.

### CORS Support

You can configure the proxy to add the `Access-Control-Allow-Origin` header to all responses by setting the `ADD_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN` environment variable:
```shell
$ docker run -d --rm \
  -p 8443:443 \
  -p 8080:80 \
  -e NGROK_HOST=https://your-ngrok-domain.ngrok.io \
  -e ADD_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN='*' \
  igops/ngrok-skip-browser-warning:latest
```

## Customization

### Setup

This image uses [Nginx](https://www.nginx.com/) as a proxy server, as well as [Jinja](https://jinja.palletsprojects.com/en/3.1.x/) template engine to generate the Nginx config on the fly.

Feel free to replace `/etc/nginx/j2/default.j2.conf` with your own implementation, or use [my config](https://github.com/igops/ngrok-skip-browser-warning/blob/main/nginx/default.j2.conf) as a basis.

For instance, you might create `custom.j2.conf` with a very bare minimum for your experiments:

[![nginx-bare-minimum](https://raw.githubusercontent.com/igops/ngrok-skip-browser-warning/main/img/nginx-bare-minimum.png)](https://github.com/igops/ngrok-skip-browser-warning/blob/main/examples/nginx-bare-minimum.conf)
<p align="center"><sub>Click on the image to show the text version</sub></p>

Mount it as follows:
```shell
$ docker run -d --rm \
  -p 8443:443 \
  -p 8080:80 \
  -e NGROK_HOST=https://your-ngrok-domain.ngrok.io \
  -v $PWD/custom.j2.conf:/etc/nginx/j2/default.j2.conf \
  igops/ngrok-skip-browser-warning:latest
```

### Jinja Template Variables

Jinja template variables refer to the [ENV variables](#env-variables) with the same names in SNAKE_UPPER_CASE.

| Jinja Variable                    | Environment Variable                                   |
|-----------------------------------|--------------------------------------------------------|
| ProxyHostREST                     | `PROXY_HOST_REST`                                      |
| ProxyHostWSSupport                | `PROXY_HOST_WS_SUPPORT`                                |
| ProxyHostSSESupport               | `PROXY_HOST_SSE_SUPPORT`                               |
| ProxyUseSSL                       | `PROXY_USE_SSL`                                        |
| ProxySSLCertName                  | `PROXY_SSL_CERT_NAME`                                  |
| ProxySSLKeyName                   | `PROXY_SSL_KEY_NAME`                                   |
| ProxyForceHTTPS                   | `PROXY_FORCE_HTTPS`                                    |
| TargetScheme                      | Scheme of `NGROK_HOST` (typically equals to `https`)   |
| TargetHost                        | Domain name of `NGROK_HOST`                            | 
| AddHeaderAccessControlAllowOrigin | `ADD_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN`               |


### Custom routes

The simplest way to add a custom endpoint is to bind an additional `*.localhost.direct` subdomain with your own proxying rules:
[![nginx-custom-block](https://raw.githubusercontent.com/igops/ngrok-skip-browser-warning/main/img/nginx-custom-block.png)](https://github.com/igops/ngrok-skip-browser-warning/blob/main/examples/nginx-custom-block.j2.conf)
<p align="center"><sub>Click on the image to show the text version</sub></p>

A custom location block might be as follows:
[![nginx-custom-location](https://raw.githubusercontent.com/igops/ngrok-skip-browser-warning/main/img/nginx-custom-location.png)](https://github.com/igops/ngrok-skip-browser-warning/blob/main/examples/nginx-custom-location.j2.conf)
<p align="center"><sub>Click on the image to show the text version</sub></p>

## ENV Variables
| Variable                                | Default value                | Description                                                                                                                                                                                                |
|-----------------------------------------|------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NGROK_HOST                              | -                            | **Mandatory**. Your ngrok host, e.g. `https://your-ngrok-domain.ngrok.io`.<br/>Specifying a protocol is optional, `https` will be used by default.<br/>Any url parts after a domain name will be trimmed.  |
| PROXY_HOST_REST                         | `ngrok.localhost.direct`     | Optional. A domain name to listen on REST API calls.                                                                                                                                                       |
| PROXY_HOST_WS_SUPPORT                   | `ngrok-ws.localhost.direct`  | Optional. A domain name to listen on WebSocket API calls.                                                                                                                                                  |
| PROXY_HOST_SSE_SUPPORT                  | `ngrok-sse.localhost.direct` | Optional. A domain name to listen on SSE API calls.                                                                                                                                                        |
| PROXY_USE_SSL                           | `true`                       | Optional. Enables relay over HTTPS. You can mount your own certificates to `/etc/nginx/certs`. If the directory is not mounted, `localhost.direct` certificate will be downloaded on container bootstrap.  |
| PROXY_FORCE_HTTPS                       | `false`                      | Optional. Forcibly redirect HTTP calls to HTTPS.                                                                                                                                                           |
| PROXY_SSL_CERT_NAME                     | `localhost.direct.crt`       | Optional. Override the name of the certificate file. Mount the file to `/etc/nginx/certs/my-custom-cert.crt`.                                                                                              |
| PROXY_SSL_KEY_NAME                      | `localhost.direct.key`       | Optional. Override the name of the certificate key. Mount the file to `/etc/nginx/certs/my-custom-cert.key`.                                                                                               |
| ADD_HEADER_ACCESS_CONTROL_ALLOW_ORIGIN  | (empty string)               | Optional. Add custom [Access-Control-Allow-Origin](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Origin) to all responses.                                                |


## Source code
https://github.com/igops/ngrok-skip-browser-warning

Feel free to [contribute](https://github.com/igops/ngrok-skip-browser-warning).

## Credits
[@igops](https://github.com/igops)
[@muratx10](https://github.com/muratx10)
