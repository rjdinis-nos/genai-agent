# FastAPI File Downloader & PDF Summarizer

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
