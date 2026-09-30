"""Server API tiruan untuk screenshot 4 state UI. Bukan bagian dari lib/.

Jalankan sekali, lalu ganti mode dengan menulis file state (tanpa restart,
tanpa rebuild Flutter):

  python tools/mock_api_server.py 8732
  echo empty > tools/.mock_mode   # 200 OK + []        -> state empty
  echo error > tools/.mock_mode   # socket diputus      -> state error
  echo slow  > tools/.mock_mode   # balas setelah 6 s   -> state loading

Kenapa satu server + file mode: `API_BASE_URL` adalah konstanta compile-time
(`--dart-define`), jadi tiap port beda = satu build web penuh (~2 menit).
Satu port untuk semua state = cukup satu build.

Wajib ada header CORS: aplikasi Flutter web disajikan dari port berbeda, dan
tanpa `Access-Control-Allow-Origin` browser memblokir responsnya sehingga Dio
melihatnya sebagai connectionError, bukan empty. Itu kejadian nyata waktu
percobaan screenshot pertama.
"""
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

MODE_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".mock_mode")


def current_mode() -> str:
    try:
        with open(MODE_FILE) as handle:
            return handle.read().strip() or "empty"
    except FileNotFoundError:
        return "empty"


class Handler(BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "*")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        mode = current_mode()
        if mode == "error":
            self.connection.close()  # -> DioException connectionError
            return
        if mode == "slow":
            time.sleep(6)  # biar spinner state loading sempat terfoto

        body = json.dumps([]).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self._cors()
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8732
    HTTPServer(("127.0.0.1", port), Handler).serve_forever()
