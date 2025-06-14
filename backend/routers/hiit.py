from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from models import HiitWorkout, HiitWorkoutCreate, HiitSession, HiitSessionCreate, MessageResponse, HiitPhase
from database import get_supabase_client, get_current_user
from supabase import Client
from datetime import datetime

router = APIRouter()

# HIIT Workouts
@router.get("/workouts", response_model=List[HiitWorkout])
async def get_hiit_workouts(
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get all HIIT workouts (predefined + custom)"""
    try:
        response = supabase.table("hiit_workouts").select("*").execute()
        workouts = [HiitWorkout(**workout) for workout in response.data]
        return workouts
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get HIIT workouts: {str(e)}"
        )

@router.get("/workouts/{workout_id}", response_model=HiitWorkout)
async def get_hiit_workout(
    workout_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get a specific HIIT workout"""
    try:
        response = supabase.table("hiit_workouts").select("*").eq("id", workout_id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="HIIT workout not found"
            )
        
        return HiitWorkout(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get HIIT workout: {str(e)}"
        )

@router.post("/workouts", response_model=HiitWorkout)
async def create_custom_hiit_workout(
    workout_data: HiitWorkoutCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Create a custom HIIT workout"""
    try:
        workout_dict = workout_data.dict()
        workout_dict["created_by"] = current_user.id
        workout_dict["is_custom"] = True
        
        response = supabase.table("hiit_workouts").insert(workout_dict).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create HIIT workout"
            )
        
        return HiitWorkout(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create HIIT workout: {str(e)}"
        )

# HIIT Sessions
@router.get("/sessions", response_model=List[HiitSession])
async def get_user_hiit_sessions(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get user's HIIT sessions"""
    try:
        offset = (page - 1) * per_page
        response = supabase.table("hiit_sessions").select("""
            *,
            workout:hiit_workouts(*)
        """).eq("user_id", current_user.id).order("created_at", desc=True).range(offset, offset + per_page - 1).execute()
        
        sessions = [HiitSession(**session) for session in response.data]
        return sessions
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get HIIT sessions: {str(e)}"
        )

@router.post("/sessions", response_model=HiitSession)
async def start_hiit_session(
    session_data: HiitSessionCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Start a new HIIT session"""
    try:
        session_dict = session_data.dict()
        session_dict["user_id"] = current_user.id
        session_dict["is_completed"] = False
        
        response = supabase.table("hiit_sessions").insert(session_dict).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to start HIIT session"
            )
        
        return HiitSession(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to start HIIT session: {str(e)}"
        )

@router.put("/sessions/{session_id}/phase", response_model=MessageResponse)
async def update_hiit_session_phase(
    session_id: str,
    phase: HiitPhase,
    current_round: int,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Update HIIT session phase and round"""
    try:
        response = supabase.table("hiit_sessions").update({
            "current_phase": phase.value,
            "current_round": current_round
        }).eq("id", session_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="HIIT session not found or not owned by user"
            )
        
        return MessageResponse(message="HIIT session phase updated successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update HIIT session: {str(e)}"
        )

@router.put("/sessions/{session_id}/complete", response_model=MessageResponse)
async def complete_hiit_session(
    session_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Complete a HIIT session"""
    try:
        response = supabase.table("hiit_sessions").update({
            "is_completed": True,
            "end_time": datetime.now().isoformat(),
            "current_phase": HiitPhase.FINISHED.value
        }).eq("id", session_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="HIIT session not found or not owned by user"
            )
        
        return MessageResponse(message="HIIT session completed successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete HIIT session: {str(e)}"
        ) 