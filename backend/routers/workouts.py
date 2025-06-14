from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from models import WorkoutSession, WorkoutSessionCreate, WorkoutExercise, ExerciseSet, MessageResponse
from database import get_supabase_client, get_current_user
from supabase import Client
from datetime import datetime

router = APIRouter()

@router.get("/", response_model=List[WorkoutSession])
async def get_user_workouts(
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get user's workout sessions"""
    try:
        # Get workout sessions with pagination
        offset = (page - 1) * per_page
        response = supabase.table("workout_sessions").select("""
            *,
            exercises:workout_exercises(
                *,
                exercise:exercises(*),
                sets:exercise_sets(*)
            )
        """).eq("user_id", current_user.id).order("created_at", desc=True).range(offset, offset + per_page - 1).execute()
        
        workouts = []
        for workout_data in response.data:
            # Parse nested data
            workout = WorkoutSession(**workout_data)
            workouts.append(workout)
        
        return workouts
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get workouts: {str(e)}"
        )

@router.get("/{workout_id}", response_model=WorkoutSession)
async def get_workout(
    workout_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get a specific workout session"""
    try:
        response = supabase.table("workout_sessions").select("""
            *,
            exercises:workout_exercises(
                *,
                exercise:exercises(*),
                sets:exercise_sets(*)
            )
        """).eq("id", workout_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workout not found or not owned by user"
            )
        
        return WorkoutSession(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get workout: {str(e)}"
        )

@router.post("/", response_model=WorkoutSession)
async def create_workout(
    workout_data: WorkoutSessionCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Create a new workout session"""
    try:
        # Create workout session
        session_data = {
            "name": workout_data.name,
            "start_time": workout_data.start_time,
            "end_time": workout_data.end_time,
            "user_id": current_user.id,
            "is_completed": False
        }
        
        session_response = supabase.table("workout_sessions").insert(session_data).execute()
        
        if not session_response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create workout session"
            )
        
        session_id = session_response.data[0]["id"]
        
        # Create workout exercises and sets
        for exercise_data in workout_data.exercises:
            exercise_dict = {
                "session_id": session_id,
                "exercise_id": exercise_data.exercise_id,
                "order_index": exercise_data.order_index
            }
            
            exercise_response = supabase.table("workout_exercises").insert(exercise_dict).execute()
            
            if exercise_response.data:
                workout_exercise_id = exercise_response.data[0]["id"]
                
                # Create sets
                for i, set_data in enumerate(exercise_data.sets):
                    set_dict = {
                        "workout_exercise_id": workout_exercise_id,
                        "set_order": i + 1,
                        "reps": set_data.reps,
                        "weight": set_data.weight,
                        "is_completed": set_data.is_completed
                    }
                    
                    supabase.table("exercise_sets").insert(set_dict).execute()
        
        # Return the created workout with all related data
        return await get_workout(session_id, current_user, supabase)
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create workout: {str(e)}"
        )

@router.put("/{workout_id}/complete", response_model=MessageResponse)
async def complete_workout(
    workout_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Mark a workout as completed"""
    try:
        # Update workout session
        response = supabase.table("workout_sessions").update({
            "is_completed": True,
            "end_time": datetime.now().isoformat()
        }).eq("id", workout_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workout not found or not owned by user"
            )
        
        return MessageResponse(message="Workout completed successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to complete workout: {str(e)}"
        )

@router.put("/{workout_id}/sets/{set_id}", response_model=MessageResponse)
async def update_exercise_set(
    workout_id: str,
    set_id: str,
    reps: int,
    weight: float,
    is_completed: bool,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Update an exercise set"""
    try:
        # Verify workout ownership
        workout_response = supabase.table("workout_sessions").select("id").eq("id", workout_id).eq("user_id", current_user.id).execute()
        
        if not workout_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workout not found or not owned by user"
            )
        
        # Update set
        set_response = supabase.table("exercise_sets").update({
            "reps": reps,
            "weight": weight,
            "is_completed": is_completed
        }).eq("id", set_id).execute()
        
        if not set_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Exercise set not found"
            )
        
        return MessageResponse(message="Exercise set updated successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update exercise set: {str(e)}"
        )

@router.delete("/{workout_id}", response_model=MessageResponse)
async def delete_workout(
    workout_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Delete a workout session"""
    try:
        # Verify workout ownership and delete
        response = supabase.table("workout_sessions").delete().eq("id", workout_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Workout not found or not owned by user"
            )
        
        return MessageResponse(message="Workout deleted successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete workout: {str(e)}"
        ) 