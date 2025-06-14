from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPAuthorizationCredentials
from models import UserCreate, UserLogin, UserProfile, AuthResponse, MessageResponse
from database import get_supabase_client, get_current_user, security
from supabase import Client

router = APIRouter()

@router.post("/register", response_model=AuthResponse)
async def register(user_data: UserCreate, supabase: Client = Depends(get_supabase_client)):
    """Register a new user"""
    try:
        # Create user with Supabase Auth
        auth_response = supabase.auth.sign_up({
            "email": user_data.email,
            "password": user_data.password
        })
        
        if not auth_response.user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create user account"
            )
        
        # Create user profile in our users table
        user_profile = {
            "id": auth_response.user.id,
            "email": user_data.email,
            "name": user_data.name,
            "is_onboarded": False
        }
        
        # Insert into users table
        profile_response = supabase.table("users").insert(user_profile).execute()
        
        if not profile_response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create user profile"
            )
        
        return AuthResponse(
            access_token=auth_response.session.access_token,
            user=UserProfile(**profile_response.data[0])
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Registration failed: {str(e)}"
        )

@router.post("/login", response_model=AuthResponse)
async def login(user_data: UserLogin, supabase: Client = Depends(get_supabase_client)):
    """Login user"""
    try:
        # Authenticate with Supabase
        auth_response = supabase.auth.sign_in_with_password({
            "email": user_data.email,
            "password": user_data.password
        })
        
        if not auth_response.user or not auth_response.session:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        
        # Get user profile
        profile_response = supabase.table("users").select("*").eq("id", auth_response.user.id).execute()
        
        if not profile_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found"
            )
        
        return AuthResponse(
            access_token=auth_response.session.access_token,
            user=UserProfile(**profile_response.data[0])
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Login failed: {str(e)}"
        )

@router.post("/logout", response_model=MessageResponse)
async def logout(credentials: HTTPAuthorizationCredentials = Depends(security), supabase: Client = Depends(get_supabase_client)):
    """Logout user"""
    try:
        # Sign out from Supabase
        supabase.auth.sign_out()
        return MessageResponse(message="Successfully logged out")
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Logout failed: {str(e)}"
        )

@router.get("/me", response_model=UserProfile)
async def get_current_user_profile(current_user = Depends(get_current_user), supabase: Client = Depends(get_supabase_client)):
    """Get current user profile"""
    try:
        # Get user profile from database
        profile_response = supabase.table("users").select("*").eq("id", current_user.id).execute()
        
        if not profile_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found"
            )
        
        return UserProfile(**profile_response.data[0])
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user profile: {str(e)}"
        )

@router.post("/refresh", response_model=AuthResponse)
async def refresh_token(credentials: HTTPAuthorizationCredentials = Depends(security), supabase: Client = Depends(get_supabase_client)):
    """Refresh access token"""
    try:
        # Refresh token with Supabase
        auth_response = supabase.auth.refresh_session()
        
        if not auth_response.session:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Failed to refresh token"
            )
        
        # Get user profile
        profile_response = supabase.table("users").select("*").eq("id", auth_response.user.id).execute()
        
        return AuthResponse(
            access_token=auth_response.session.access_token,
            user=UserProfile(**profile_response.data[0])
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token refresh failed: {str(e)}"
        ) 