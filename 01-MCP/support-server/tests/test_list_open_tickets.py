import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from core.server import DynamicMCPServer


class TestListOpenTickets:

    def setup_method(self):
        self.server = DynamicMCPServer(name="Test", tools_dir="src/tools")
        self.server.load_tools()
        self.tools = self.server.get_tools_sync()

    def test_tool_registered(self):
        assert "list_open_tickets" in self.tools

    def test_returns_tickets_list(self):
        result = self.tools["list_open_tickets"].fn()
        data = json.loads(result)
        assert isinstance(data, list)
        assert len(data) >= 3

    def test_ticket_fields(self):
        result = self.tools["list_open_tickets"].fn()
        data = json.loads(result)
        for ticket in data:
            assert "id" in ticket
            assert "subject" in ticket
            assert "priority" in ticket
            assert "service" in ticket
            assert "created_at" in ticket
            assert "assigned_to" in ticket

    def test_filter_by_payments(self):
        result = self.tools["list_open_tickets"].fn(service="payments")
        data = json.loads(result)
        assert len(data) == 2
        for ticket in data:
            assert ticket["service"] == "payments"

    def test_filter_by_nonexistent_service(self):
        result = self.tools["list_open_tickets"].fn(service="nonexistent")
        data = json.loads(result)
        assert isinstance(data, list)
        assert len(data) == 0

    def test_no_filter_returns_all_open(self):
        result = self.tools["list_open_tickets"].fn()
        data = json.loads(result)
        for ticket in data:
            assert ticket["status"] in ("open", "in-progress")
