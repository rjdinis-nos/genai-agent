# GenAI Agent

[![CI/CD Pipeline](https://github.com/rjdinis-nos/genai-agent/actions/workflows/ci.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/ci.yml)
[![PR Validation](https://github.com/rjdinis-nos/genai-agent/actions/workflows/pr-validation.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/pr-validation.yml)
[![Dependency Updates](https://github.com/rjdinis-nos/genai-agent/actions/workflows/dependency-update.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/dependency-update.yml)
[![Performance Monitoring](https://github.com/rjdinis-nos/genai-agent/actions/workflows/performance.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/performance.yml)
[![Release](https://github.com/rjdinis-nos/genai-agent/actions/workflows/release.yml/badge.svg)](https://github.com/rjdinis-nos/genai-agent/actions/workflows/release.yml)

[![Python](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-green.svg)](https://fastapi.tiangolo.com/)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?logo=docker&logoColor=white)](https://www.docker.com/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[![GitHub issues](https://img.shields.io/github/issues/rjdinis-nos/genai-agent)](https://github.com/rjdinis-nos/genai-agent/issues)
[![GitHub forks](https://img.shields.io/github/forks/rjdinis-nos/genai-agent)](https://github.com/rjdinis-nos/genai-agent/network)
[![GitHub stars](https://img.shields.io/github/stars/rjdinis-nos/genai-agent)](https://github.com/rjdinis-nos/genai-agent/stargazers)
[![GitHub last commit](https://img.shields.io/github/last-commit/rjdinis-nos/genai-agent)](https://github.com/rjdinis-nos/genai-agent/commits/main)

[![Container Registry](https://img.shields.io/badge/ghcr.io-genai--agent-blue?logo=github)](https://github.com/rjdinis-nos/genai-agent/pkgs/container/genai-agent)
[![Code Quality](https://img.shields.io/badge/code%20quality-A+-brightgreen)](https://github.com/rjdinis-nos/genai-agent)
[![Security](https://img.shields.io/badge/security-scanned-green?logo=github)](https://github.com/rjdinis-nos/genai-agent/security)
[![Tests](https://img.shields.io/badge/tests-14%20passing-brightgreen)](https://github.com/rjdinis-nos/genai-agent/actions)

A FastAPI application that provides two main endpoints:
1. **File Download**: Download files from the internet
2. **PDF Summarization**: Summarize PDF documents using Google Gemini AI

## Setup with uv

This project uses [uv](https://github.com/astral-sh/uv) for fast Python package management.

### Prerequisites
- Python 3.8+
- uv package manager

### Installation

1. Install uv if you haven't already:
```bash
pip install uv
```

2. Create and activate virtual environment with dependencies:
```bash
uv sync
```

3. Set up your environment variables:
   - Copy `.env` file and add your Google Gemini API key
   - Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)

### Running the Application

```bash
uv run uvicorn main:app --reload
```

The API will be available at `http://localhost:8000`

### API Documentation

Once running, visit:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Endpoints

#### POST /download
Download a file from the internet.

**Parameters:**
- `url` (string): URL of the file to download

#### POST /summarize
Summarize a PDF document using Google Gemini.

**Parameters:**
- `file` (file): PDF file to upload and summarize

### Development

To add new dependencies:
```bash
uv add package-name
```

To add development dependencies:
```bash
uv add --dev package-name
```
