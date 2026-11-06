import http.server
import socketserver
import os
import sys

DOCS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "docs")

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DOCS_DIR, **kwargs)

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        super().end_headers()

def run_server():
    ports_to_try = [int(os.environ.get("PORT", 8085)), 8080, 8088, 3000]
    httpd = None
    selected_port = None

    for port in ports_to_try:
        try:
            httpd = socketserver.TCPServer(("127.0.0.1", port), CustomHandler)
            selected_port = port
            break
        except OSError:
            continue

    if not httpd:
        print("Не удалось занять свободный порт.")
        sys.exit(1)

    with httpd:
        print(f"Локальный предпросмотр запущен: http://127.0.0.1:{selected_port}/")
        print("Нажмите Ctrl+C для завершения.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nСервер остановлен.")

if __name__ == '__main__':
    run_server()
