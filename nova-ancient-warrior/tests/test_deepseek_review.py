import json
import os
import subprocess
import sys
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

PROJECT = Path(__file__).resolve().parents[1]
CLIENT = PROJECT / "tools" / "deepseek_review.py"

class ReviewHandler(BaseHTTPRequestHandler):
    requests = []
    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        payload = json.loads(self.rfile.read(length).decode("utf-8"))
        ReviewHandler.requests.append(payload)
        response = json.dumps({"choices": [{"message": {"content": "## Critical\nNone.\n\n## Overall assessment\nMock review passed."}}]}).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response)))
        self.end_headers()
        self.wfile.write(response)
    def log_message(self, *_args):
        pass

class DeepSeekReviewClientTests(unittest.TestCase):
    def test_client_supports_local_endpoint_without_key(self):
        server = HTTPServer(("127.0.0.1", 0), ReviewHandler)
        thread = threading.Thread(target=server.serve_forever, daemon=True)
        thread.start()
        try:
            with tempfile.TemporaryDirectory() as temp:
                temp_path = Path(temp)
                patch = temp_path / "change.patch"
                output = temp_path / "review.md"
                patch.write_text("diff --git a/scripts/player.gd b/scripts/player.gd\n+var health = 100\n", encoding="utf-8")
                env = os.environ.copy()
                env["DEEPSEEK_BASE_URL"] = "http://127.0.0.1:{}/v1".format(server.server_port)
                env.pop("DEEPSEEK_API_KEY", None)
                env["DEEPSEEK_MODEL"] = "deepseek-r1-local"
                result = subprocess.run([sys.executable, str(CLIENT), "--diff-file", str(patch), "--output", str(output)], cwd=str(PROJECT), env=env, capture_output=True, text=True, timeout=20)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertTrue(output.is_file())
                self.assertIn("Mock review passed.", output.read_text(encoding="utf-8"))
                self.assertEqual(ReviewHandler.requests[-1]["model"], "deepseek-r1-local")
        finally:
            server.shutdown()
            server.server_close()
            thread.join(timeout=2)

    def test_client_rejects_remote_or_hosted_endpoints(self):
        with tempfile.TemporaryDirectory() as temp:
            patch = Path(temp) / "change.patch"
            patch.write_text("+a change\n", encoding="utf-8")
            env = os.environ.copy()
            env["DEEPSEEK_BASE_URL"] = "https://api.deepseek.com"
            env.pop("DEEPSEEK_API_KEY", None)
            result = subprocess.run([sys.executable, str(CLIENT), "--diff-file", str(patch)], cwd=str(PROJECT), env=env, capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 2)
            self.assertIn("local HTTP inference server", result.stderr)

if __name__ == "__main__":
    unittest.main()
