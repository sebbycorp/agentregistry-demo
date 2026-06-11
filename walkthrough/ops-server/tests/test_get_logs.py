import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from core.server import DynamicMCPServer


class TestGetLogs:

    def setup_method(self):
        self.server = DynamicMCPServer(name="Test", tools_dir="src/tools")
        self.server.load_tools()
        self.tools = self.server.get_tools_sync()

    def test_tool_registered(self):
        assert "get_logs" in self.tools

    def test_returns_log_entries(self):
        result = self.tools["get_logs"].fn(service_name="payments")
        data = json.loads(result)
        assert isinstance(data, list)
        assert len(data) >= 5

    def test_log_entry_fields(self):
        result = self.tools["get_logs"].fn(service_name="payments")
        data = json.loads(result)
        for entry in data:
            assert "timestamp" in entry
            assert "severity" in entry
            assert "message" in entry
            assert entry["severity"] in ("info", "warn", "error")

    def test_payments_has_errors(self):
        result = self.tools["get_logs"].fn(service_name="payments")
        data = json.loads(result)
        error_logs = [e for e in data if e["severity"] == "error"]
        assert len(error_logs) >= 1

    def test_filter_by_severity(self):
        result = self.tools["get_logs"].fn(service_name="payments", severity="error")
        data = json.loads(result)
        for entry in data:
            assert entry["severity"] == "error"

    def test_healthy_service_no_errors(self):
        result = self.tools["get_logs"].fn(service_name="auth")
        data = json.loads(result)
        error_logs = [e for e in data if e["severity"] == "error"]
        assert len(error_logs) == 0

    def test_unknown_service(self):
        result = self.tools["get_logs"].fn(service_name="nonexistent")
        data = json.loads(result)
        assert isinstance(data, list)
        assert len(data) == 0
