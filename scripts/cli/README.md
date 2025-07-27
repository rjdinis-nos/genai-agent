# CLI Tools

This directory contains command-line interface tools for interacting with the GenAI Agent API endpoints.

## Prerequisites

- GenAI Agent server running (locally or remote)
- `curl` command-line tool
- `jq` for JSON parsing (optional, for simple tool)

## Available CLI Tools

### 📥 `download-file.sh`
Comprehensive CLI tool for downloading files using the GenAI Agent /download endpoint.

```bash
./scripts/cli/download-file.sh [OPTIONS] <URL>
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
./scripts/cli/download-file.sh https://example.com/document.pdf

# With custom output filename
./scripts/cli/download-file.sh -o my-file.pdf https://example.com/document.pdf

# With custom server and HTTPS
./scripts/cli/download-file.sh -h api.example.com -p 443 -s https://example.com/document.pdf

# With output directory and verbose mode
./scripts/cli/download-file.sh -d downloads/ -v https://example.com/document.pdf
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
./scripts/cli/download.sh <URL> [output_file]
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
./scripts/cli/download.sh https://example.com/document.pdf

# With custom output filename
./scripts/cli/download.sh https://example.com/document.pdf my-document.pdf

# With custom server
GENAI_HOST=api.example.com GENAI_PORT=8080 ./scripts/cli/download.sh https://example.com/file.pdf
```

### 📄 `summarize-pdf.sh`
Comprehensive CLI tool for PDF summarization with error handling and status feedback.

```bash
./scripts/cli/summarize-pdf.sh <pdf_file_path> [server_url]
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
./scripts/cli/summarize-pdf.sh document.pdf

# With custom server URL
./scripts/cli/summarize-pdf.sh /path/to/report.pdf http://localhost:8000

# Using environment variables
GENAI_SERVER_URL=https://genai-agent.example.com ./scripts/cli/summarize-pdf.sh paper.pdf

# With custom timeout
GENAI_TIMEOUT=120 ./scripts/cli/summarize-pdf.sh large-document.pdf
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
./scripts/cli/summarize.sh <pdf_file_path> [server_url]
```

**Parameters:**
- `pdf_file_path` (required): Path to the PDF file to summarize
- `server_url` (optional): GenAI Agent server URL (default: `http://localhost:8000`)

**Examples:**
```bash
# Basic usage
./scripts/cli/summarize.sh document.pdf

# With custom server
./scripts/cli/summarize.sh report.pdf http://localhost:3000

# Pipe output to file
./scripts/cli/summarize.sh document.pdf > summary.txt
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
./scripts/cli/summarize-pdf.sh my-document.pdf

# Use the simple tool for quick results
./scripts/cli/summarize.sh my-document.pdf
```

### Batch Processing
```bash
# Process multiple PDFs
for pdf in *.pdf; do
    echo "Summarizing: $pdf"
    ./scripts/cli/summarize-pdf.sh "$pdf" > "${pdf%.pdf}-summary.txt"
done
```

### Remote Server Usage
```bash
# Set server URL for all commands
export GENAI_SERVER_URL="https://your-genai-agent.com"

# Now use tools normally
./scripts/cli/summarize-pdf.sh document.pdf
```

### Integration with Other Tools
```bash
# Combine with find to process all PDFs in a directory
find /path/to/pdfs -name "*.pdf" -exec ./scripts/cli/summarize.sh {} \;

# Use with xargs for parallel processing
find . -name "*.pdf" | xargs -I {} -P 4 ./scripts/cli/summarize.sh {}
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
GENAI_TIMEOUT=10 ./scripts/cli/summarize-pdf.sh document.pdf
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
