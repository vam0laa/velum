# A tiny local server for the interface test: error answers with and without a page.
import http.server


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"<title>Check</title><p>are you a person?</p>" if self.path.startswith("/page") else b""
        self.send_response(429 if body else 404)
        self.send_header("Content-Type", "text/html")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", 8766), Handler).serve_forever()
