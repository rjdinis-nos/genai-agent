"""
Basic benchmark tests for GenAI Agent FastAPI application.
"""

import pytest
import time
from fastapi.testclient import TestClient
import sys
import os

# Add the backend directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from main import app

client = TestClient(app)


def test_health_endpoint_benchmark(benchmark):
    """Benchmark the health endpoint response time."""
    
    def health_check():
        response = client.get("/")
        return response
    
    result = benchmark(health_check)
    assert result.status_code == 200


def test_download_endpoint_benchmark(benchmark):
    """Benchmark the download endpoint error handling (no actual download)."""
    
    def download_test():
        # Test error handling without actual download for benchmarking
        test_url = "invalid-url"
        response = client.post("/download", json={"url": test_url})
        return response
    
    result = benchmark(download_test)
    # Should return an error for invalid URL, but benchmark the response time
    assert result.status_code in [400, 422]  # Expected error codes


def test_summarize_endpoint_benchmark(benchmark):
    """Benchmark the summarize endpoint error handling (no actual PDF)."""
    
    def summarize_test():
        # Test error handling without actual PDF processing
        response = client.post("/summarize", files={"file": ("test.txt", b"not a pdf", "text/plain")})
        return response
    
    result = benchmark(summarize_test)
    # Should return an error for non-PDF file, but benchmark the response time
    assert result.status_code in [400, 422]  # Expected error codes
