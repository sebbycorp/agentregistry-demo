import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from core.server import DynamicMCPServer


class TestSearchDocs:

    def setup_method(self):
        self.server = DynamicMCPServer(name="Test", tools_dir="src/tools")
        self.server.load_tools()
        self.tools = self.server.get_tools_sync()

    def test_tool_registered(self):
        assert "search_docs" in self.tools

    def test_returns_results_list(self):
        result = self.tools["search_docs"].fn(query="payment timeout")
        data = json.loads(result)
        assert isinstance(data, list)
        assert len(data) >= 1

    def test_result_fields(self):
        result = self.tools["search_docs"].fn(query="payment")
        data = json.loads(result)
        for article in data:
            assert "title" in article
            assert "snippet" in article
            assert "relevance_score" in article
            assert "article_id" in article

    def test_payment_query_returns_payment_article(self):
        result = self.tools["search_docs"].fn(query="payment timeout")
        data = json.loads(result)
        titles = [a["title"] for a in data]
        assert any("payment" in t.lower() for t in titles)

    def test_no_results_for_unrelated_query(self):
        result = self.tools["search_docs"].fn(query="xyzzy nonsense")
        data = json.loads(result)
        assert isinstance(data, list)
