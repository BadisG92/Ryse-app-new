"""
Authentication module for Ryze App APIs
Handles JWT token validation and user authentication
"""

from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Dict, Optional
import jwt
import logging
from .database import get_supabase_client

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Security scheme
security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict:
    """
    Validate JWT token and return current user information
    """
    try:
        # Get the token from the Authorization header
        token = credentials.credentials
        
        # Get Supabase client
        supabase = get_supabase_client()
        
        # Verify the token with Supabase
        try:
            # Use Supabase's built-in token verification
            user_response = supabase.auth.get_user(token)
            
            if user_response.user:
                return {
                    'id': user_response.user.id,
                    'email': user_response.user.email,
                    'user_metadata': user_response.user.user_metadata or {}
                }
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid authentication token",
                    headers={"WWW-Authenticate": "Bearer"},
                )
                
        except Exception as auth_error:
            logger.error(f"Token verification failed: {str(auth_error)}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or expired token",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
    except Exception as e:
        logger.error(f"Authentication error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication failed",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_optional_user(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> Optional[Dict]:
    """
    Get current user if authenticated, otherwise return None
    Useful for endpoints that work with or without authentication
    """
    if not credentials:
        return None
        
    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None

def require_admin(current_user: Dict = Depends(get_current_user)) -> Dict:
    """
    Require admin privileges for the current user
    """
    user_metadata = current_user.get('user_metadata', {})
    is_admin = user_metadata.get('is_admin', False)
    
    if not is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required"
        )
    
    return current_user

def create_api_key_user(api_key: str) -> Dict:
    """
    Create a user context for API key authentication
    Used for testing and service-to-service communication
    """
    # TODO: Implement API key validation
    # For now, return a test user
    return {
        'id': '00000000-0000-0000-0000-000000000000',
        'email': 'api@ryzeapp.com',
        'user_metadata': {'api_key': True}
    } 