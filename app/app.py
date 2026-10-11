
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import os


def get_message() -> str:
    return "Hello from my DevOps application!"


def health_check() -> bool:
    return True


class AppHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/":
            status = 200
            body = get_message()
        elif self.path == "/health":
            healthy = health_check()
            status = 200 if healthy else 503
            body = "ok" if healthy else "unhealthy"
        else:
            status = 404
            body = "not found"

        payload = body.encode("utf-8")

        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def main() -> None:
    port = int(os.environ.get("PORT", "8000"))

    server = ThreadingHTTPServer(
        ("0.0.0.0", port),
        AppHandler,
    )

    print(f"Listening on 0.0.0.0:{port}", flush=True)

    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()

