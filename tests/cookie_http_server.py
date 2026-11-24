#!/usr/bin/env python3
"""A loopback cookie server. /set sends two Set-Cookie headers and /echo
returns the Cookie header it received, reporting its port on stdout."""
import http.server
import socketserver


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/set":
            body = b"cookies set"
            self.send_response(200)
            self.send_header("Set-Cookie", "session=abc123; Path=/")
            self.send_header("Set-Cookie", "theme=dark; Path=/")
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        elif self.path == "/echo":
            text = ("cookie " + (self.headers.get("Cookie") or "")).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(text)))
            self.end_headers()
            self.wfile.write(text)
        else:
            body = b"not found"
            self.send_response(404)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    def log_message(self, *args):
        pass


class Server(socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    with Server(("127.0.0.1", 0), Handler) as server:
        print("port %d" % server.server_address[1], flush=True)
        server.serve_forever()
