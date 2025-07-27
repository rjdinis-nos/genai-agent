from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
import requests
import os
from pathlib import Path
import tempfile
from typing import Optional
from PyPDF2 import PdfReader
import google.generativeai as genai
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI(
    title="GenAI Agent API",
    description="FastAPI application for file downloads and PDF summarization using Google Gemini AI",
    version="1.0.0"
)

download_dir = Path("downloads")
download_dir.mkdir(exist_ok=True)

@app.get("/health")
async def health_check():
    """
    Health check endpoint to verify API status and dependencies.
    
    Returns:
        Health status information including API status, dependencies, and system info
    """
    import time
    import sys
    import psutil
    from datetime import datetime
    
    try:
        # Check if downloads directory is accessible
        downloads_accessible = download_dir.exists() and download_dir.is_dir()
        
        # Check Google Gemini API configuration
        gemini_configured = bool(os.getenv("GOOGLE_API_KEY"))
        
        # Get system information
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        health_data = {
            "status": "healthy",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "version": "1.0.0",
            "uptime": time.time(),
            "system": {
                "python_version": sys.version.split()[0],
                "memory_usage": {
                    "total": memory.total,
                    "available": memory.available,
                    "percent": memory.percent
                },
                "disk_usage": {
                    "total": disk.total,
                    "free": disk.free,
                    "percent": (disk.used / disk.total) * 100
                }
            },
            "dependencies": {
                "downloads_directory": downloads_accessible,
                "google_gemini_api": gemini_configured
            },
            "endpoints": {
                "download": "/download",
                "summarize": "/summarize",
                "health": "/health",
                "docs": "/docs"
            }
        }
        
        return health_data
        
    except Exception as e:
        return {
            "status": "unhealthy",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "error": str(e)
        }

@app.get("/")
async def root():
    """
    Root endpoint with API information.
    
    Returns:
        Basic API information and available endpoints
    """
    return {
        "message": "Welcome to GenAI Agent API",
        "description": "FastAPI application for file downloads and PDF summarization",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health - Health check endpoint",
            "download": "/download - Download files from URLs",
            "summarize": "/summarize - Summarize PDF documents",
            "docs": "/docs - API documentation"
        }
    }

@app.post("/download")
async def download_file(url: str):
    """
    Download a file from the internet and save it locally.
    
    Args:
        url: URL of the file to download
        
    Returns:
        Path to the downloaded file
    """
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        # Get filename from URL or Content-Disposition header
        filename = url.split('/')[-1]
        if 'content-disposition' in response.headers:
            cd = response.headers['content-disposition']
            filename = cd.split('filename=')[-1].strip('"')
        
        file_path = download_dir / filename
        
        with open(file_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return {"message": f"File downloaded successfully", "file_path": str(file_path)}
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/summarize")
async def summarize_pdf(file: UploadFile = File(...)):
    """
    Summarize a PDF document.
    
    Args:
        file: PDF file to summarize
        
    Returns:
        Summary of the PDF content
    """
    try:
        # Save the uploaded file temporarily
        with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_file:
            content = await file.read()
            temp_file.write(content)
            temp_file.flush()
            
            # Read PDF content
            pdf_reader = PdfReader(temp_file.name)
            text = ""
            for page in pdf_reader.pages:
                text += page.extract_text()
            
            # Configure Google Gemini
            genai.configure(api_key=os.getenv('GEMINI_API_KEY'))
            model = genai.GenerativeModel('gemini-pro')
            
            # Create summarization prompt
            prompt = f"Please provide a comprehensive summary of the following text:\n\n{text[:8000]}"  # Limit text length for API
            
            # Generate summary using Gemini
            response = model.generate_content(prompt)
            summary = response.text
            
            # Clean up temporary file
            os.unlink(temp_file.name)
            
            return {"summary": summary}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
