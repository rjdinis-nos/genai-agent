FROM mcr.microsoft.com/devcontainers/python:3.11-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install uv (fast Python package manager)
RUN pip install uv

# Set working directory
WORKDIR /workspaces/genai-baseline-agent

# Copy project files
COPY pyproject.toml ./
COPY uv.lock ./

# Install Python dependencies
RUN uv sync

# Create .env template
RUN echo "GEMINI_API_KEY=your_gemini_api_key_here" > .env.template

# Set Python path
ENV PYTHONPATH=/workspaces/genai-baseline-agent

# Expose port for FastAPI
EXPOSE 8000

# Keep container running
CMD ["sleep", "infinity"]
