import pytest
import os
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock, mock_open
from fastapi.testclient import TestClient
import io

# Import the app
from backend.main import app

# Create test client
client = TestClient(app)

class TestDownloadEndpoint:
    """Test cases for the /download endpoint"""
    
    @patch('backend.main.requests.get')
    def test_download_file_success(self, mock_get):
        """Test successful file download"""
        # Mock response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {}
        mock_response.iter_content.return_value = [b'test content']
        mock_response.raise_for_status.return_value = None
        mock_get.return_value = mock_response
        
        # Test URL
        test_url = "https://example.com/test.txt"
        
        with patch('builtins.open', mock_open()) as mock_file:
            response = client.post("/download", params={"url": test_url})
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "file_path" in data
        assert "test.txt" in data["file_path"]
        
        # Verify requests.get was called with correct URL
        mock_get.assert_called_once_with(test_url, stream=True)
    
    @patch('backend.main.requests.get')
    def test_download_file_with_content_disposition(self, mock_get):
        """Test file download with Content-Disposition header"""
        # Mock response with Content-Disposition header
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.headers = {'content-disposition': 'attachment; filename="custom_name.pdf"'}
        mock_response.iter_content.return_value = [b'pdf content']
        mock_response.raise_for_status.return_value = None
        mock_get.return_value = mock_response
        
        test_url = "https://example.com/document"
        
        with patch('builtins.open', mock_open()) as mock_file:
            response = client.post("/download", params={"url": test_url})
        
        assert response.status_code == 200
        data = response.json()
        assert "custom_name.pdf" in data["file_path"]
    
    @patch('backend.main.requests.get')
    def test_download_file_request_error(self, mock_get):
        """Test download failure due to request error"""
        # Mock request exception
        mock_get.side_effect = Exception("Network error")
        
        test_url = "https://invalid-url.com/file.txt"
        
        response = client.post("/download", params={"url": test_url})
        
        assert response.status_code == 400
        assert "Network error" in response.json()["detail"]
    
    @patch('backend.main.requests.get')
    def test_download_file_http_error(self, mock_get):
        """Test download failure due to HTTP error"""
        # Mock HTTP error
        mock_response = MagicMock()
        mock_response.raise_for_status.side_effect = Exception("404 Not Found")
        mock_get.return_value = mock_response
        
        test_url = "https://example.com/nonexistent.txt"
        
        response = client.post("/download", params={"url": test_url})
        
        assert response.status_code == 400
        assert "404 Not Found" in response.json()["detail"]


class TestSummarizeEndpoint:
    """Test cases for the /summarize endpoint"""
    
    def create_test_pdf_content(self):
        """Create mock PDF content for testing"""
        return b"%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"
    
    @patch('backend.main.genai.GenerativeModel')
    @patch('backend.main.genai.configure')
    @patch('backend.main.PdfReader')
    @patch('backend.main.os.getenv')
    def test_summarize_pdf_success(self, mock_getenv, mock_pdf_reader, mock_configure, mock_model_class):
        """Test successful PDF summarization"""
        # Mock environment variable
        mock_getenv.return_value = "fake_api_key"
        
        # Mock PDF reader
        mock_page = MagicMock()
        mock_page.extract_text.return_value = "This is test PDF content."
        mock_reader = MagicMock()
        mock_reader.pages = [mock_page]
        mock_pdf_reader.return_value = mock_reader
        
        # Mock Gemini model
        mock_response = MagicMock()
        mock_response.text = "This is a summary of the PDF content."
        mock_model = MagicMock()
        mock_model.generate_content.return_value = mock_response
        mock_model_class.return_value = mock_model
        
        # Create test file
        pdf_content = self.create_test_pdf_content()
        
        with patch('tempfile.NamedTemporaryFile') as mock_temp:
            mock_temp_file = MagicMock()
            mock_temp_file.name = "/tmp/test.pdf"
            mock_temp_file.__enter__.return_value = mock_temp_file
            mock_temp.return_value = mock_temp_file
            
            with patch('backend.main.os.unlink'):
                response = client.post(
                    "/summarize",
                    files={"file": ("test.pdf", pdf_content, "application/pdf")}
                )
        
        assert response.status_code == 200
        data = response.json()
        assert "summary" in data
        assert data["summary"] == "This is a summary of the PDF content."
        
        # Verify Gemini was configured and called
        mock_configure.assert_called_once_with(api_key="fake_api_key")
        mock_model_class.assert_called_once_with('gemini-pro')
        mock_model.generate_content.assert_called_once()
    
    @patch('backend.main.os.getenv')
    def test_summarize_pdf_missing_api_key(self, mock_getenv):
        """Test PDF summarization with missing API key"""
        # Mock missing API key
        mock_getenv.return_value = None
        
        pdf_content = self.create_test_pdf_content()
        
        response = client.post(
            "/summarize",
            files={"file": ("test.pdf", pdf_content, "application/pdf")}
        )
        
        assert response.status_code == 400
    
    @patch('backend.main.PdfReader')
    @patch('backend.main.os.getenv')
    def test_summarize_pdf_reader_error(self, mock_getenv, mock_pdf_reader):
        """Test PDF summarization with PDF reading error"""
        # Mock environment variable
        mock_getenv.return_value = "fake_api_key"
        
        # Mock PDF reader error
        mock_pdf_reader.side_effect = Exception("Invalid PDF format")
        
        pdf_content = self.create_test_pdf_content()
        
        with patch('tempfile.NamedTemporaryFile') as mock_temp:
            mock_temp_file = MagicMock()
            mock_temp_file.name = "/tmp/test.pdf"
            mock_temp_file.__enter__.return_value = mock_temp_file
            mock_temp.return_value = mock_temp_file
            
            response = client.post(
                "/summarize",
                files={"file": ("test.pdf", pdf_content, "application/pdf")}
            )
        
        assert response.status_code == 400
        assert "Invalid PDF format" in response.json()["detail"]
    
    @patch('backend.main.genai.GenerativeModel')
    @patch('backend.main.genai.configure')
    @patch('backend.main.PdfReader')
    @patch('backend.main.os.getenv')
    def test_summarize_pdf_gemini_error(self, mock_getenv, mock_pdf_reader, mock_configure, mock_model_class):
        """Test PDF summarization with Gemini API error"""
        # Mock environment variable
        mock_getenv.return_value = "fake_api_key"
        
        # Mock PDF reader
        mock_page = MagicMock()
        mock_page.extract_text.return_value = "Test content"
        mock_reader = MagicMock()
        mock_reader.pages = [mock_page]
        mock_pdf_reader.return_value = mock_reader
        
        # Mock Gemini error
        mock_model = MagicMock()
        mock_model.generate_content.side_effect = Exception("Gemini API error")
        mock_model_class.return_value = mock_model
        
        pdf_content = self.create_test_pdf_content()
        
        with patch('tempfile.NamedTemporaryFile') as mock_temp:
            mock_temp_file = MagicMock()
            mock_temp_file.name = "/tmp/test.pdf"
            mock_temp_file.__enter__.return_value = mock_temp_file
            mock_temp.return_value = mock_temp_file
            
            with patch('backend.main.os.unlink'):
                response = client.post(
                    "/summarize",
                    files={"file": ("test.pdf", pdf_content, "application/pdf")}
                )
        
        assert response.status_code == 400
        assert "Gemini API error" in response.json()["detail"]
    
    def test_summarize_no_file(self):
        """Test summarization endpoint without file"""
        response = client.post("/summarize")
        
        assert response.status_code == 422  # Unprocessable Entity
    
    def test_summarize_empty_file(self):
        """Test summarization with empty file"""
        response = client.post(
            "/summarize",
            files={"file": ("empty.pdf", b"", "application/pdf")}
        )
        
        assert response.status_code == 400


class TestAppConfiguration:
    """Test app configuration and setup"""
    
    def test_app_title(self):
        """Test that the app has the correct title"""
        assert app.title == "GenAI Agent API"
    
    def test_downloads_directory_creation(self):
        """Test that downloads directory is created"""
        from backend.main import download_dir
        assert download_dir.name == "downloads"


# Integration tests
class TestIntegration:
    """Integration tests for the application"""
    
    def test_health_check(self):
        """Test basic app health"""
        # Test that the app starts without errors
        assert app is not None
    
    @patch.dict(os.environ, {'GEMINI_API_KEY': 'test_key'})
    def test_environment_setup(self):
        """Test environment variable loading"""
        from dotenv import load_dotenv
        load_dotenv()
        assert os.getenv('GEMINI_API_KEY') == 'test_key'


if __name__ == "__main__":
    pytest.main([__file__])
