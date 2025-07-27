"""Basic benchmark tests for GenAI Agent FastAPI application."""

import pytest
import time


def test_simple_benchmark(benchmark):
    """Simple benchmark test that doesn't require external dependencies."""
    
    def simple_operation():
        # Simple computation for benchmarking
        result = sum(range(1000))
        return result
    
    result = benchmark(simple_operation)
    assert result == 499500  # Expected sum of range(1000)


def test_string_benchmark(benchmark):
    """Benchmark string operations."""
    
    def string_operation():
        # String manipulation for benchmarking
        text = "hello world " * 100
        result = text.upper().replace(" ", "_")
        return len(result)
    
    result = benchmark(string_operation)
    assert result > 0


def test_list_benchmark(benchmark):
    """Benchmark list operations."""
    
    def list_operation():
        # List operations for benchmarking
        data = list(range(1000))
        filtered = [x for x in data if x % 2 == 0]
        return len(filtered)
    
    result = benchmark(list_operation)
    assert result == 500  # Half of 1000 numbers are even
