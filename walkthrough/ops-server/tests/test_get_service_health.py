import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from core.server import DynamicMCPServer


class TestGetServiceHealth:

    def setup_method(self):
        self.server = DynamicMCPServer(name="Test", tools_dir="src/tools")
        self.server.load_tools()
        self.tools = self.server.get_tools_sync()

    def test_tool_registered(self):
        assert "get_service_health" in self.tools

    def test_healthy_service(self):
        result = self.tools["get_service_health"].fn(service_name="auth")
        data = json.loads(result)
        assert data["service"] == "auth"
        assert data["status"] == "healthy"
        assert "uptime" in data
        assert "latency_ms" in data
        assert "error_rate" in data
        assert "checked_at" in data

    def test_degraded_service(self):
        result = self.tools["get_service_health"].fn(service_name="payments")
        data = json.loads(result)
        assert data["service"] == "payments"
        assert data["status"] == "degraded"
        assert data["error_rate"] == 12.5

    def test_unknown_service(self):
        result = self.tools["get_service_health"].fn(service_name="nonexistent")
        data = json.loads(result)
        assert data["status"] == "unknown"
        assert data["service"] == "nonexistent"
