"""Search_docs tool for MCP server.
"""

from core.server import mcp
from core.utils import get_tool_config


@mcp.tool()
def search_docs(message: str) -> str:
    """Search_docs tool implementation.

    This is a template function. Replace this implementation with your tool logic.

    Args:
        message: Input message (replace with your actual parameters)

    Returns:
        str: Result of the tool operation (replace with your actual return type)
    """
    # Get tool-specific configuration from mcp.yaml
    config = get_tool_config("search_docs")

    # TODO: Replace this basic implementation with your tool logic

    # Example: Basic text processing
    prefix = config.get("prefix", "echo: ")
    return f"{prefix}{message}"
