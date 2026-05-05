import json

from core.server import mcp

KB_ARTICLES = [
    {
        "article_id": "KB-2041",
        "title": "Payment Processing Timeouts — Troubleshooting Guide",
        "snippet": "If customers report failed payments or timeout errors, check the payment gateway connection status and retry queue depth. Common causes include upstream gateway outages and deployment-related connection pool resets.",
        "tags": ["payments", "timeout", "gateway", "connection", "error", "transaction"],
    },
    {
        "article_id": "KB-1893",
        "title": "Auth Token Refresh Guide",
        "snippet": "When users experience unexpected logouts or 401 errors, verify the token refresh flow. Ensure the OAuth provider sync is active and certificate rotation has completed successfully.",
        "tags": ["auth", "token", "refresh", "oauth", "login", "401", "session"],
    },
    {
        "article_id": "KB-1756",
        "title": "Order API Rate Limits and Throttling",
        "snippet": "The orders API enforces a rate limit of 1000 requests per minute per API key. If clients receive 429 responses, advise them to implement exponential backoff and check their current usage against their plan limits.",
        "tags": ["orders", "rate limit", "api", "throttling", "429"],
    },
    {
        "article_id": "KB-2105",
        "title": "Inventory Sync Delays and Webhook Failures",
        "snippet": "Stock levels may lag behind real-time if the batch import job encounters errors or webhook delivery fails. Check the sync status endpoint and verify webhook subscriber health.",
        "tags": ["inventory", "sync", "webhook", "stock", "delay"],
    },
    {
        "article_id": "KB-1622",
        "title": "Notification Delivery Troubleshooting",
        "snippet": "If customers report missing emails or push notifications, verify the notification queue depth and check SMS/email provider status. Template rendering errors can also cause silent delivery failures.",
        "tags": ["notifications", "email", "sms", "push", "delivery", "missing"],
    },
]


def _score_article(article: dict, query: str) -> float:
    query_terms = query.lower().split()
    searchable = (article["title"] + " " + article["snippet"] + " " + " ".join(article["tags"])).lower()
    matches = sum(1 for term in query_terms if term in searchable)
    if not query_terms:
        return 0.0
    return round(matches / len(query_terms), 2)


@mcp.tool()
def search_docs(query: str) -> str:
    """Search the knowledge base for articles matching a query.

    Args:
        query: Search query string (e.g. "payment timeout", "auth token", "rate limit").

    Returns:
        JSON array of matching articles with title, snippet, relevance_score, and article_id.
    """
    scored = []
    for article in KB_ARTICLES:
        score = _score_article(article, query)
        if score > 0:
            scored.append({
                "article_id": article["article_id"],
                "title": article["title"],
                "snippet": article["snippet"],
                "relevance_score": score,
            })
    scored.sort(key=lambda x: x["relevance_score"], reverse=True)
    return json.dumps(scored[:3], indent=2)
