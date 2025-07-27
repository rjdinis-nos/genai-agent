# CLI Tools

This directory contains command-line interface tools for interacting with the GenAI Agent API endpoints.

## Prerequisites

- GenAI Agent server running (locally or remote)
- `curl` command-line tool
- `jq` for JSON parsing (optional, for simple tool)

## Available CLI Tools

### 🏥 `healthcheck.sh`
Comprehensive CLI tool for performing health checks on the GenAI Agent API.

```bash
./scripts/api/healthcheck.sh [OPTIONS]
```

**Options:**
- `-h, --host HOST`: API host (default: localhost)
- `-p, --port PORT`: API port (default: 8000)
- `-s, --secure`: Use HTTPS instead of HTTP
- `-v, --verbose`: Verbose output
- `-j, --json`: Output raw JSON response
- `-w, --wait SECONDS`: Wait time between retries (default: 5)
- `-r, --retries COUNT`: Number of retries (default: 3)
- `--timeout SECONDS`: Request timeout (default: 10)
- `--help`: Show help message

**Examples:**
```bash
# Basic health check
./scripts/api/healthcheck.sh

# Verbose health check with system details
./scripts/api/healthcheck.sh -v

# Remote HTTPS API health check
./scripts/api/healthcheck.sh -h api.example.com -p 443 -s

# JSON output for automation
./scripts/api/healthcheck.sh -j

# Custom retries and timeout
./scripts/api/healthcheck.sh -r 5 -w 10 --timeout 30
```

**Features:**
- ✅ Comprehensive API health monitoring
- ✅ System resource monitoring (memory, disk usage)
- ✅ Dependency status checking (downloads directory, Gemini API)
- ✅ Endpoint availability verification
- ✅ Retry logic with configurable attempts
- ✅ Colored output with status indicators
- ✅ JSON output for automation/scripting
- ✅ Verbose mode for detailed diagnostics
- ✅ Timeout and connectivity handling

### 🏥 `health.sh`
Simple one-liner CLI tool for quick health checks.

```bash
./scripts/api/health.sh [host] [port]
```

**Parameters:**
- `host` (optional): API host (default: localhost or $GENAI_HOST)
- `port` (optional): API port (default: 8000 or $GENAI_PORT)

**Environment Variables:**
- `GENAI_HOST`: Override default host
- `GENAI_PORT`: Override default port
- `GENAI_PROTOCOL`: Override default protocol (http/https)

**Examples:**
```bash
# Basic health check
./scripts/api/health.sh

# Custom host and port
./scripts/api/health.sh api.example.com 8080

# Using environment variables
GENAI_HOST=api.example.com GENAI_PORT=443 GENAI_PROTOCOL=https ./scripts/api/health.sh
```

### 📥 `download-file.sh`
Comprehensive CLI tool for downloading files using the GenAI Agent /download endpoint.

```bash
./scripts/api/download-file.sh [OPTIONS] <URL>
```

**Parameters:**
- `URL` (required): The URL of the file to download

**Options:**
- `-h, --host HOST`: API host (default: localhost)
- `-p, --port PORT`: API port (default: 8000)
- `-s, --secure`: Use HTTPS instead of HTTP
- `-o, --output FILE`: Output filename (default: extracted from URL)
- `-d, --directory DIR`: Output directory (default: current directory)
- `-v, --verbose`: Verbose output
- `--help`: Show help message

**Examples:**
```bash
# Basic usage
./scripts/api/download-file.sh https://example.com/document.pdf

# With custom output filename
./scripts/api/download-file.sh -o my-file.pdf https://example.com/document.pdf

# With custom server and HTTPS
./scripts/api/download-file.sh -h api.example.com -p 443 -s https://example.com/document.pdf

# With output directory and verbose mode
./scripts/api/download-file.sh -d downloads/ -v https://example.com/document.pdf
```

**Features:**
- ✅ URL validation and format checking
- ✅ Server availability verification
- ✅ Colored output with status indicators
- ✅ Comprehensive error handling
- ✅ Configurable host, port, and protocol
- ✅ Custom output filename and directory
- ✅ File overwrite protection
- ✅ HTTP status code handling
- ✅ Verbose mode for debugging

### 📥 `download.sh`
Simple one-liner CLI tool for quick file downloads.

```bash
./scripts/api/download.sh <URL> [output_file]
```

**Parameters:**
- `URL` (required): The URL of the file to download
- `output_file` (optional): Output filename (default: extracted from URL)

**Environment Variables:**
- `GENAI_HOST`: Override default host (default: localhost)
- `GENAI_PORT`: Override default port (default: 8000)

**Examples:**
```bash
# Basic usage
./scripts/api/download.sh https://example.com/document.pdf

# With custom output filename
./scripts/api/download.sh https://example.com/document.pdf my-document.pdf

# With custom server
GENAI_HOST=api.example.com GENAI_PORT=8080 ./scripts/api/download.sh https://example.com/file.pdf
```

### 📄 `summarize-pdf.sh`
Comprehensive CLI tool for PDF summarization with error handling and status feedback.

```bash
./scripts/api/summarize-pdf.sh <pdf_file_path> [server_url]
```

**Parameters:**
- `pdf_file_path` (required): Path to the PDF file to summarize
- `server_url` (optional): GenAI Agent server URL (default: `http://localhost:8000`)

**Environment Variables:**
- `GENAI_SERVER_URL`: Override default server URL
- `GENAI_TIMEOUT`: Request timeout in seconds (default: 60)

**Examples:**
```bash
# Basic usage
./scripts/api/summarize-pdf.sh document.pdf

# With custom server URL
./scripts/api/summarize-pdf.sh /path/to/report.pdf http://localhost:8000

# Using environment variables
GENAI_SERVER_URL=https://genai-agent.example.com ./scripts/api/summarize-pdf.sh paper.pdf

# With custom timeout
GENAI_TIMEOUT=120 ./scripts/api/summarize-pdf.sh large-document.pdf
```

**Features:**
- ✅ File validation and PDF format checking
- ✅ Server availability verification
- ✅ Colored output with status indicators
- ✅ Comprehensive error handling
- ✅ Configurable timeout settings
- ✅ Help documentation (`-h` or `--help`)
- ✅ HTTP status code handling
- ✅ Progress feedback

**Output:**
- Status messages to stderr (colored)
- Summary content to stdout (for piping)

### 📄 `summarize.sh`
Simple one-liner for quick PDF summarization.

```bash
./scripts/api/summarize.sh <pdf_file_path> [server_url]
```

**Parameters:**
- `pdf_file_path` (required): Path to the PDF file to summarize
- `server_url` (optional): GenAI Agent server URL (default: `http://localhost:8000`)

**Examples:**
```bash
# Basic usage
./scripts/api/summarize.sh document.pdf

# With custom server
./scripts/api/summarize.sh report.pdf http://localhost:3000

# Pipe output to file
./scripts/api/summarize.sh document.pdf > summary.txt
```

**Features:**
- ✅ Minimal dependencies (curl, jq)
- ✅ JSON response parsing
- ✅ Quick and simple usage
- ✅ Pipe-friendly output

## Usage Patterns

### Basic PDF Summarization
```bash
# Use the comprehensive tool for better error handling
./scripts/api/summarize-pdf.sh my-document.pdf

# Use the simple tool for quick results
./scripts/api/summarize.sh my-document.pdf
```

### Batch Processing
```bash
# Process multiple PDFs
for pdf in *.pdf; do
    echo "Summarizing: $pdf"
    ./scripts/api/summarize-pdf.sh "$pdf" > "${pdf%.pdf}-summary.txt"
done
```

### Remote Server Usage
```bash
# Set server URL for all commands
export GENAI_SERVER_URL="https://your-genai-agent.com"

# Now use tools normally
./scripts/api/summarize-pdf.sh document.pdf
```

### Integration with Other Tools
```bash
# Combine with find to process all PDFs in a directory
find /path/to/pdfs -name "*.pdf" -exec ./scripts/api/summarize.sh {} \;

# Use with xargs for parallel processing
find . -name "*.pdf" | xargs -I {} -P 4 ./scripts/api/summarize.sh {}
```

## Error Handling

The comprehensive tool (`summarize-pdf.sh`) provides detailed error messages for:
- File not found or not readable
- Invalid PDF format
- Server not accessible
- API errors (400, 422, 500)
- Network timeouts

The simple tool (`summarize.sh`) provides basic error handling with minimal output.

## Server Requirements

Make sure the GenAI Agent server is running before using these tools:

```bash
# Start server locally
cd /path/to/genai-agent
uv run uvicorn backend.main:app --reload

# Or using Docker
./scripts/docker/run.sh
```

## Troubleshooting

### Server Connection Issues
```bash
# Check if server is accessible
curl -s http://localhost:8000/docs

# Test with verbose output
GENAI_TIMEOUT=10 ./scripts/api/summarize-pdf.sh document.pdf
```

### File Issues
```bash
# Check file type
file document.pdf

# Check file permissions
ls -la document.pdf
```

### Dependencies
```bash
# Check required tools
which curl jq file

# Install missing dependencies (Ubuntu/Debian)
sudo apt-get install curl jq file
```
