#!/usr/bin/env python3
"""A loopback counter server for the NSURLCache fixture. Every GET to
/count increments a counter and returns "count N", so a cached response is
recognizable by its repeated number."""
import http.server
import socketserver

counter = 0


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        global counter
        if self.path == "/count":
            counter += 1
            body = ("count %d" % counter).encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
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
