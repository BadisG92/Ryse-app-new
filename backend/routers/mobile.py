from fastapi import APIRouter, HTTPException, Depends, status, Query, Header
from typing import List, Optional
from datetime import datetime, date, timedelta
from models import (
    ExerciseLite, WorkoutSummary, NutritionSummary, MobileSync, 
    BatchRequest, BatchResponse, OfflineAction, PaginatedResponse
)
from database import get_supabase_client, get_current_user
from supabase import Client

router = APIRouter()

@router.get("/dashboard")
async def get_mobile_dashboard(
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get mobile dashboard with today's summary"""
    try:
        today = date.today()
        
        # Get today's workouts
        workouts_response = supabase.table("workout_sessions").select("""
            id, name, start_time, end_time, is_completed
        """).eq("user_id", current_user.id).gte("start_time", today.isoformat()).execute()
        
        # Get today's nutrition
        nutrition_response = supabase.table("meals").select("""
            *,
            items:meal_food_items(calories)
        """).eq("user_id", current_user.id).eq("date", today.isoformat()).execute()
        
        # Calculate nutrition totals
        total_calories = sum(
            sum(item.get("calories", 0) for item in meal.get("items", []))
            for meal in nutrition_response.data
        )
        
        return {
            "date": today.isoformat(),
            "workouts": {
                "completed": len([w for w in workouts_response.data if w.get("is_completed")]),
                "total": len(workouts_response.data),
                "active_workout": next((w for w in workouts_response.data if not w.get("is_completed")), None)
            },
            "nutrition": {
                "calories": round(total_calories),
                "meals_logged": len(nutrition_response.data)
            },
            "quick_actions": [
                {"type": "start_workout", "label": "Start Workout"},
                {"type": "log_meal", "label": "Log Meal"},
                {"type": "start_hiit", "label": "Quick HIIT"},
                {"type": "start_cardio", "label": "Start Run"}
            ]
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get dashboard: {str(e)}"
        )

@router.get("/exercises/lite", response_model=List[ExerciseLite])
async def get_exercises_lite(
    muscle_group: Optional[str] = Query(None),
    limit: int = Query(50, le=100),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get lightweight exercise list for mobile"""
    try:
        query = supabase.table("exercises").select("id, name, muscle_group, equipment")
        
        if muscle_group:
            query = query.eq("muscle_group", muscle_group)
        
        response = query.limit(limit).execute()
        
        return [ExerciseLite(**exercise) for exercise in response.data]
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get exercises: {str(e)}"
        )

@router.get("/workouts/recent", response_model=List[WorkoutSummary])
async def get_recent_workouts(
    days: int = Query(7, ge=1, le=30),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get recent workout summaries for mobile"""
    try:
        since_date = (datetime.now() - timedelta(days=days)).isoformat()
        
        response = supabase.table("workout_sessions").select("""
            id, name, start_time, end_time, is_completed,
            exercises:workout_exercises(count)
        """).eq("user_id", current_user.id).gte("start_time", since_date).order("start_time", desc=True).execute()
        
        workouts = []
        for workout in response.data:
            duration_minutes = None
            if workout.get("end_time") and workout.get("start_time"):
                start = datetime.fromisoformat(workout["start_time"].replace("Z", "+00:00"))
                end = datetime.fromisoformat(workout["end_time"].replace("Z", "+00:00"))
                duration_minutes = int((end - start).total_seconds() / 60)
            
            workouts.append(WorkoutSummary(
                id=workout["id"],
                name=workout["name"],
                start_time=workout["start_time"],
                duration_minutes=duration_minutes,
                exercises_count=len(workout.get("exercises", [])),
                is_completed=workout.get("is_completed", False)
            ))
        
        return workouts
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get recent workouts: {str(e)}"
        )

@router.post("/batch", response_model=BatchResponse)
async def batch_operations(
    batch_request: BatchRequest,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Process batch operations for mobile efficiency"""
    try:
        results = []
        errors = []
        
        for operation in batch_request.operations:
            try:
                op_type = operation.get("type")
                table = operation.get("table")
                data = operation.get("data", {})
                
                if op_type == "insert":
                    data["user_id"] = current_user.id
                    result = supabase.table(table).insert(data).execute()
                    results.append({"operation": operation, "result": result.data})
                
                elif op_type == "update":
                    record_id = operation.get("id")
                    result = supabase.table(table).update(data).eq("id", record_id).eq("user_id", current_user.id).execute()
                    results.append({"operation": operation, "result": result.data})
                
            except Exception as op_error:
                errors.append({"operation": operation, "error": str(op_error)})
        
        return BatchResponse(
            results=results,
            errors=errors,
            sync_timestamp=datetime.now(),
            success_count=len(results),
            error_count=len(errors)
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Batch operation failed: {str(e)}"
        )

@router.get("/sync", response_model=MobileSync)
async def get_sync_data(
    last_sync: Optional[datetime] = Query(None),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get synchronization data for offline mobile app"""
    try:
        sync_time = datetime.now()
        
        # Get exercises (lightweight)
        exercises_response = supabase.table("exercises").select("id, name, muscle_group, equipment").execute()
        exercises = [ExerciseLite(**ex) for ex in exercises_response.data]
        
        # Get recent workouts
        workouts_response = supabase.table("workout_sessions").select("""
            id, name, start_time, end_time, is_completed
        """).eq("user_id", current_user.id).order("start_time", desc=True).limit(20).execute()
        
        workouts = []
        for workout in workouts_response.data:
            duration_minutes = None
            if workout.get("end_time") and workout.get("start_time"):
                start = datetime.fromisoformat(workout["start_time"].replace("Z", "+00:00"))
                end = datetime.fromisoformat(workout["end_time"].replace("Z", "+00:00"))
                duration_minutes = int((end - start).total_seconds() / 60)
            
            workouts.append(WorkoutSummary(
                id=workout["id"],
                name=workout["name"],
                start_time=workout["start_time"],
                duration_minutes=duration_minutes,
                exercises_count=0,  # Simplified for sync
                is_completed=workout.get("is_completed", False)
            ))
        
        # Get today's nutrition summary
        today = date.today()
        nutrition_response = supabase.table("meals").select("""
            *,
            items:meal_food_items(calories)
        """).eq("user_id", current_user.id).eq("date", today.isoformat()).execute()
        
        total_calories = sum(
            sum(item.get("calories", 0) for item in meal.get("items", []))
            for meal in nutrition_response.data
        )
        
        nutrition = NutritionSummary(
            date=today,
            total_calories=total_calories,
            total_protein=0,  # Simplified for sync
            total_carbs=0,
            total_fat=0,
            meals_count=len(nutrition_response.data)
        )
        
        return MobileSync(
            last_sync=sync_time,
            exercises=exercises,
            workouts=workouts,
            nutrition=nutrition,
            pending_uploads=0
        )
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Sync failed: {str(e)}"
        )

@router.post("/offline-actions", response_model=dict)
async def sync_offline_actions(
    actions: List[OfflineAction],
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Sync offline actions when mobile app comes back online"""
    try:
        processed = 0
        errors = []
        
        for action in actions:
            try:
                if action.action_type == "create":
                    data = action.data
                    data["user_id"] = current_user.id
                    supabase.table(action.resource_type).insert(data).execute()
                    processed += 1
                
                elif action.action_type == "update":
                    supabase.table(action.resource_type).update(action.data).eq("id", action.data.get("id")).eq("user_id", current_user.id).execute()
                    processed += 1
                
                elif action.action_type == "delete":
                    supabase.table(action.resource_type).delete().eq("id", action.data.get("id")).eq("user_id", current_user.id).execute()
                    processed += 1
                    
            except Exception as action_error:
                errors.append({"action_id": action.id, "error": str(action_error)})
        
        return {
            "processed": processed,
            "errors": errors,
            "sync_timestamp": datetime.now().isoformat()
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Offline sync failed: {str(e)}"
        ) 