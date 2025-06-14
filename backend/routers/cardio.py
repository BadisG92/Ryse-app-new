from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from models import CardioSession, CardioSessionCreate, LocationPoint, LocationPointCreate, MessageResponse
from database import get_supabase_client, get_current_user
from supabase import Client
from datetime import datetime

router = APIRouter()

@router.get("/sessions", response_model=List[CardioSession])
async def get_user_cardio_sessions(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get user's cardio sessions"""
    try:
        offset = (page - 1) * per_page
        response = supabase.table("cardio_sessions").select("*").eq("user_id", current_user.id).order("created_at", desc=True).range(offset, offset + per_page - 1).execute()
        
        sessions = [CardioSession(**session) for session in response.data]
        return sessions
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get cardio sessions: {str(e)}"
        )

@router.get("/sessions/{session_id}", response_model=CardioSession)
async def get_cardio_session(
    session_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get a specific cardio session"""
    try:
        response = supabase.table("cardio_sessions").select("*").eq("id", session_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cardio session not found or not owned by user"
            )
        
        return CardioSession(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get cardio session: {str(e)}"
        )

@router.post("/sessions", response_model=CardioSession)
async def start_cardio_session(
    session_data: CardioSessionCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Start a new cardio session"""
    try:
        session_dict = session_data.dict()
        session_dict["user_id"] = current_user.id
        
        response = supabase.table("cardio_sessions").insert(session_dict).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to start cardio session"
            )
        
        return CardioSession(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to start cardio session: {str(e)}"
        )

@router.put("/sessions/{session_id}", response_model=CardioSession)
async def update_cardio_session(
    session_id: str,
    duration_seconds: Optional[int] = None,
    distance_km: Optional[float] = None,
    average_speed_kmh: Optional[float] = None,
    current_speed_kmh: Optional[float] = None,
    steps: Optional[int] = None,
    calories: Optional[int] = None,
    is_running: Optional[bool] = None,
    is_paused: Optional[bool] = None,
    notes: Optional[str] = None,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Update cardio session data"""
    try:
        # Build update data
        update_data = {}
        if duration_seconds is not None:
            update_data["duration_seconds"] = duration_seconds
        if distance_km is not None:
            update_data["distance_km"] = distance_km
        if average_speed_kmh is not None:
            update_data["average_speed_kmh"] = average_speed_kmh
        if current_speed_kmh is not None:
            update_data["current_speed_kmh"] = current_speed_kmh
        if steps is not None:
            update_data["steps"] = steps
        if calories is not None:
            update_data["calories"] = calories
        if is_running is not None:
            update_data["is_running"] = is_running
        if is_paused is not None:
            update_data["is_paused"] = is_paused
        if notes is not None:
            update_data["notes"] = notes
        
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No valid fields provided for update"
            )
        
        response = supabase.table("cardio_sessions").update(update_data).eq("id", session_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cardio session not found or not owned by user"
            )
        
        return CardioSession(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update cardio session: {str(e)}"
        )

@router.put("/sessions/{session_id}/complete", response_model=MessageResponse)
async def complete_cardio_session(
    session_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Complete a cardio session"""
    try:
        response = supabase.table("cardio_sessions").update({
            "end_time": datetime.now().isoformat(),
            "is_running": False,
            "is_paused": False
        }).eq("id", session_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cardio session not found or not owned by user"
            )
        
        return MessageResponse(message="Cardio session completed successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete cardio session: {str(e)}"
        )

# Location tracking
@router.post("/sessions/{session_id}/locations", response_model=LocationPoint)
async def add_location_point(
    session_id: str,
    location_data: LocationPointCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Add a location point to a cardio session"""
    try:
        # Verify session ownership
        session_response = supabase.table("cardio_sessions").select("id").eq("id", session_id).eq("user_id", current_user.id).execute()
        
        if not session_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cardio session not found or not owned by user"
            )
        
        # Add location point
        location_dict = location_data.dict()
        location_dict["cardio_session_id"] = session_id
        
        response = supabase.table("location_points").insert(location_dict).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add location point"
            )
        
        return LocationPoint(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add location point: {str(e)}"
        )

@router.get("/sessions/{session_id}/locations", response_model=List[LocationPoint])
async def get_session_locations(
    session_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get location points for a cardio session"""
    try:
        # Verify session ownership
        session_response = supabase.table("cardio_sessions").select("id").eq("id", session_id).eq("user_id", current_user.id).execute()
        
        if not session_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cardio session not found or not owned by user"
            )
        
        # Get location points
        response = supabase.table("location_points").select("*").eq("cardio_session_id", session_id).order("recorded_at").execute()
        
        locations = [LocationPoint(**location) for location in response.data]
        return locations
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get location points: {str(e)}"
        ) 