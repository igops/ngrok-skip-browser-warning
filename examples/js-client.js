const API_HTTP_BASE_URL     = 'https://ngrok.localhost.direct:8443'
const API_WS_BASE_URL       = 'wss://ngrok-ws.localhost.direct:8443';
const API_SSE_BASE_URL      = 'https://ngrok-sse.localhost.direct:8443';

// REST
await fetch(`${API_HTTP_BASE_URL}/some-endpoint` );
await fetch(`${API_HTTP_BASE_URL}/another-endpoint`);

// WebSocket
const ws = new WebSocket (`${API_WS_BASE_URL}/some-ws-endpoint`);

// SSE
const evtSource = new EventSource(`${API_SSE_BASE_URL}/some-ws-endpoint`);