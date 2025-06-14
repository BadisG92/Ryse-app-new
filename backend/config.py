import os
from typing import List
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Settings:
    # Supabase Configuration
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")
    
    # FastAPI Configuration
    API_TITLE: str = "Ryze API"
    API_DESCRIPTION: str = "API backend for Ryze fitness and nutrition app"
    API_VERSION: str = "1.0.0"
    
    # CORS Configuration
    CORS_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:8080",
        "http://127.0.0.1:8080",
    ]
    
    # Development settings
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    
    def __init__(self):
        # Add custom CORS origins if specified
        custom_origins = os.getenv("CORS_ORIGINS", "")
        if custom_origins:
            self.CORS_ORIGINS.extend(custom_origins.split(","))

# Create global settings instance
settings = Settings()

# Validate critical settings
if not settings.SUPABASE_URL or not settings.SUPABASE_KEY:
    raise ValueError("SUPABASE_URL and SUPABASE_KEY environment variables are required") 