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

app = FastAPI(title="File Downloader & PDF Summarizer API")

download_dir = Path("downloads")
download_dir.mkdir(exist_ok=True)

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
