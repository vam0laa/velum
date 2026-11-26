# A tiny local server for the interface test: error answers with and without a page.
import http.server


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        # a script that opens a window without any click, and a file that can run programs
        extra = {"/pop": ("text/html", b"<title>pop</title><script>setTimeout(() => window.open('/page'), 200)</script>", {}),
                 "/tool.sh": ("application/octet-stream", b"#!/bin/sh\n" + b"x" * 300000, {"Content-Disposition": "attachment; filename=tool.sh"})}.get(self.path)
        if extra:
            kind, data, headers = extra
            self.send_response(200)
            self.send_header("Content-Type", kind)
            self.send_header("Content-Length", str(len(data)))
            for name, value in headers.items():
                self.send_header(name, value)
            self.end_headers()
            self.wfile.write(data)
            return
        body = b"<title>Check</title><p>are you a person?</p>" if self.path.startswith("/page") else b""
        self.send_response(429 if body else 404)
        self.send_header("Content-Type", "text/html")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


http.server.ThreadingHTTPServer(("127.0.0.1", 8766), Handler).serve_forever()
