#!/usr/bin/env python3
"""Loopback HTTPS server for the NSURLSession TLS fixture.

Usage: tls_http_server.py <root> <certificate> <key>
Prints "port N" once listening, then serves the directory over TLS.
"""
import functools
import http.server
import ssl
import sys

root, certificate, key = sys.argv[1:4]
handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=root)
server = http.server.HTTPServer(("127.0.0.1", 0), handler)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.load_cert_chain(certificate, key)
server.socket = context.wrap_socket(server.socket, server_side=True)
print("port %d" % server.server_port, flush=True)
server.serve_forever()
