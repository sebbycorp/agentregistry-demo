import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from core.server import DynamicMCPServer


class TestGetTicket:

    def setup_method(self):
        self.server = DynamicMCPServer(name="Test", tools_dir="src/tools")
        self.server.load_tools()
        self.tools = self.server.get_tools_sync()

    def test_tool_registered(self):
        assert "get_ticket" in self.tools

    def test_known_ticket(self):
        result = self.tools["get_ticket"].fn(ticket_id="TICK-1042")
        data = json.loads(result)
        assert data["id"] == "TICK-1042"
        assert "customer" in data
        assert "subject" in data
        assert "status" in data
        assert "priority" in data
        assert "created_at" in data
        assert "description" in data

    def test_payments_ticket_content(self):
        result = self.tools["get_ticket"].fn(ticket_id="TICK-1042")
        data = json.loads(result)
        assert "payment" in data["subject"].lower() or "payment" in data["description"].lower()

    def test_unknown_ticket(self):
        result = self.tools["get_ticket"].fn(ticket_id="TICK-9999")
        data = json.loads(result)
        assert "error" in data
