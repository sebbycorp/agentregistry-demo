import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from core.server import DynamicMCPServer


class TestListDeployments:

    def setup_method(self):
        self.server = DynamicMCPServer(name="Test", tools_dir="src/tools")
        self.server.load_tools()
        self.tools = self.server.get_tools_sync()

    def test_tool_registered(self):
        assert "list_deployments" in self.tools

    def test_returns_deployments_list(self):
        result = self.tools["list_deployments"].fn(namespace="default")
        data = json.loads(result)
        assert isinstance(data, list)
        assert len(data) >= 3

    def test_deployment_fields(self):
        result = self.tools["list_deployments"].fn(namespace="default")
        data = json.loads(result)
        for dep in data:
            assert "name" in dep
            assert "version" in dep
            assert "timestamp" in dep
            assert "status" in dep
            assert "replicas" in dep
            assert "namespace" in dep

    def test_payments_deployment_is_rolling(self):
        result = self.tools["list_deployments"].fn(namespace="default")
        data = json.loads(result)
        payments_deps = [d for d in data if d["name"] == "payments"]
        assert len(payments_deps) == 1
        assert payments_deps[0]["status"] == "rolling"

    def test_filter_by_namespace(self):
        result = self.tools["list_deployments"].fn(namespace="monitoring")
        data = json.loads(result)
        for dep in data:
            assert dep["namespace"] == "monitoring"
