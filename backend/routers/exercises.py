from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from models import Exercise, ExerciseCreate, MessageResponse, ListResponse
from database import get_supabase_client, get_current_user
from supabase import Client

router = APIRouter()

@router.get("/", response_model=List[Exercise])
async def get_exercises(
    muscle_group: Optional[str] = Query(None, description="Filter by muscle group"),
    equipment: Optional[str] = Query(None, description="Filter by equipment"),
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get all exercises with optional filtering"""
    try:
        # Build query
        query = supabase.table("exercises").select("*")
        
        # Apply filters
        if muscle_group:
            query = query.eq("muscle_group", muscle_group)
        if equipment:
            query = query.eq("equipment", equipment)
        
        # Apply pagination
        offset = (page - 1) * per_page
        query = query.range(offset, offset + per_page - 1)
        
        response = query.execute()
        
        exercises = [Exercise(**exercise) for exercise in response.data]
        return exercises
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get exercises: {str(e)}"
        )

@router.get("/muscle-groups", response_model=List[str])
async def get_muscle_groups(
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get all available muscle groups"""
    try:
        response = supabase.table("exercises").select("muscle_group").execute()
        
        muscle_groups = list(set([exercise["muscle_group"] for exercise in response.data]))
        return sorted(muscle_groups)
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get muscle groups: {str(e)}"
        )

@router.get("/equipment", response_model=List[str])
async def get_equipment_types(
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get all available equipment types"""
    try:
        response = supabase.table("exercises").select("equipment").execute()
        
        equipment_types = list(set([exercise["equipment"] for exercise in response.data if exercise["equipment"]]))
        return sorted(equipment_types)
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get equipment types: {str(e)}"
        )

@router.get("/{exercise_id}", response_model=Exercise)
async def get_exercise(
    exercise_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get a specific exercise by ID"""
    try:
        response = supabase.table("exercises").select("*").eq("id", exercise_id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exercise not found"
            )
        
        return Exercise(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get exercise: {str(e)}"
        )

@router.post("/", response_model=Exercise)
async def create_custom_exercise(
    exercise_data: ExerciseCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Create a custom exercise"""
    try:
        # Prepare exercise data
        exercise_dict = exercise_data.dict()
        exercise_dict["created_by"] = current_user.id
        exercise_dict["is_custom"] = True
        
        # Insert exercise
        response = supabase.table("exercises").insert(exercise_dict).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create exercise"
            )
        
        return Exercise(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create exercise: {str(e)}"
        )

@router.put("/{exercise_id}", response_model=Exercise)
async def update_custom_exercise(
    exercise_id: str,
    exercise_data: ExerciseCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Update a custom exercise (only owner can update)"""
    try:
        # Check if exercise exists and belongs to user
        check_response = supabase.table("exercises").select("*").eq("id", exercise_id).eq("created_by", current_user.id).execute()
        
        if not check_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exercise not found or not owned by user"
            )
        
        # Update exercise
        update_data = exercise_data.dict()
        response = supabase.table("exercises").update(update_data).eq("id", exercise_id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to update exercise"
            )
        
        return Exercise(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update exercise: {str(e)}"
        )

@router.delete("/{exercise_id}", response_model=MessageResponse)
async def delete_custom_exercise(
    exercise_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Delete a custom exercise (only owner can delete)"""
    try:
        # Check if exercise exists and belongs to user
        check_response = supabase.table("exercises").select("*").eq("id", exercise_id).eq("created_by", current_user.id).execute()
        
        if not check_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exercise not found or not owned by user"
            )
        
        # Delete exercise
        response = supabase.table("exercises").delete().eq("id", exercise_id).execute()
        
        return MessageResponse(message="Exercise deleted successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete exercise: {str(e)}"
        )

@router.get("/user/custom", response_model=List[Exercise])
async def get_user_custom_exercises(
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get current user's custom exercises"""
    try:
        response = supabase.table("exercises").select("*").eq("created_by", current_user.id).eq("is_custom", True).execute()
        
        exercises = [Exercise(**exercise) for exercise in response.data]
        return exercises
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get user custom exercises: {str(e)}"
        ) 