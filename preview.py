import http.server
import socketserver
import os
import sys

PORT = int(os.environ.get("PORT", 8080))
DOCS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "docs")

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DOCS_DIR, **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

if __name__ == '__main__':
    with socketserver.TCPServer(("127.0.0.1", PORT), CustomHandler) as httpd:
        print(f"Локальный предпросмотр запущен: http://127.0.0.1:{PORT}/")
        print("Нажмите Ctrl+C для остановки сервера.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nСервер остановлен.")
