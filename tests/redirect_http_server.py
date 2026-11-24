#!/usr/bin/env python3
"""A loopback server for URLSession redirect handling. /start, /hop and
/redirect-307 redirect to /final; /post answers a POST with a 303; /loop
redirects to itself."""
import http.server
import socketserver


class Handler(http.server.BaseHTTPRequestHandler):
    def _send(self, status, body, location=None):
        self.send_response(status)
        if location:
            self.send_header("Location", location)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _absolute_final(self):
        port = self.server.server_address[1]
        return "http://127.0.0.1:%d/final" % port

    def do_GET(self):
        if self.path == "/start":
            self._send(302, b"moved", "/final")
        elif self.path == "/hop":
            self._send(301, b"moved", "/start")
        elif self.path == "/final":
            self._send(200, b"redirected body")
        elif self.path == "/loop":
            self._send(302, b"moved", "/loop")
        elif self.path == "/redirect-307":
            self._send(307, b"moved", self._absolute_final())
        else:
            self._send(404, b"not found")

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        self.rfile.read(length)
        if self.path == "/post":
            self._send(303, b"moved", "/final")
        elif self.path == "/redirect-307":
            self._send(307, b"moved", self._absolute_final())
        elif self.path == "/final":
            self._send(200, b"final post")
        else:
            self._send(404, b"not found")

    def log_message(self, *args):
        pass


class Server(socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    with Server(("127.0.0.1", 0), Handler) as server:
        print("port %d" % server.server_address[1], flush=True)
        server.serve_forever()
