#!/usr/bin/env python3
"""A loopback POST echo server for the NSURLSession fixtures. It answers a
POST with "<method> <body> <X-Test header>" and reports its port on stdout."""
import http.server
import socketserver


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length)
        text = ("%s %s %s" % (
            self.command,
            body.decode("utf-8", "replace"),
            self.headers.get("X-Test", ""),
        )).encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(text)))
        self.end_headers()
        self.wfile.write(text)

    def log_message(self, *args):
        pass


class Server(socketserver.TCPServer):
    allow_reuse_address = True


if __name__ == "__main__":
    with Server(("127.0.0.1", 0), Handler) as server:
        print("port %d" % server.server_address[1], flush=True)
        server.serve_forever()
