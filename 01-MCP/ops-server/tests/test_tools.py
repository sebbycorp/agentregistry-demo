import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from core.server import DynamicMCPServer


class TestToolLoading:

    def test_server_initialization(self):
        server = DynamicMCPServer(name="Test Server", tools_dir="src/tools")
        assert server is not None
        assert server.name == "Test Server"

    def test_tool_discovery(self):
        server = DynamicMCPServer(name="Test Server", tools_dir="src/tools")
        server.load_tools()
        assert len(server.loaded_tools) == 3

    def test_all_tools_registered(self):
        server = DynamicMCPServer(name="Test Server", tools_dir="src/tools")
        server.load_tools()
        assert "get_service_health" in server.loaded_tools
        assert "list_deployments" in server.loaded_tools
        assert "get_logs" in server.loaded_tools

    def test_tool_functions_callable(self):
        server = DynamicMCPServer(name="Test Server", tools_dir="src/tools")
        server.load_tools()
        tools = server.get_tools_sync()
        for tool_name, tool in tools.items():
            assert hasattr(tool, "fn"), f"Tool {tool_name} has no fn attribute"
            assert callable(tool.fn), f"Tool {tool_name} is not callable"
