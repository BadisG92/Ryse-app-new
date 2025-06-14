from fastapi import APIRouter, HTTPException, Depends, status
from models import UserProfile, UserUpdate, MessageResponse
from database import get_supabase_client, get_current_user
from supabase import Client

router = APIRouter()

@router.get("/profile", response_model=UserProfile)
async def get_user_profile(
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get current user's profile"""
    try:
        response = supabase.table("users").select("*").eq("id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found"
            )
        
        return UserProfile(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user profile: {str(e)}"
        )

@router.put("/profile", response_model=UserProfile)
async def update_user_profile(
    user_update: UserUpdate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Update current user's profile"""
    try:
        # Filter out None values
        update_data = {k: v for k, v in user_update.dict().items() if v is not None}
        
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No valid fields provided for update"
            )
        
        # Update user profile
        response = supabase.table("users").update(update_data).eq("id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found"
            )
        
        return UserProfile(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update user profile: {str(e)}"
        )

@router.delete("/profile", response_model=MessageResponse)
async def delete_user_account(
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Delete current user's account"""
    try:
        # Delete user profile from database
        profile_response = supabase.table("users").delete().eq("id", current_user.id).execute()
        
        # Note: Supabase Auth user deletion requires admin privileges
        # In production, you might want to mark the user as deleted instead
        # or use Supabase Admin API
        
        return MessageResponse(message="User account deleted successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete user account: {str(e)}"
        )

@router.post("/onboarding/complete", response_model=MessageResponse)
async def complete_onboarding(
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Mark user onboarding as complete"""
    try:
        response = supabase.table("users").update({"is_onboarded": True}).eq("id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User profile not found"
            )
        
        return MessageResponse(message="Onboarding completed successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete onboarding: {str(e)}"
        ) 