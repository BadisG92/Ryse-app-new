from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, date, timedelta
from decimal import Decimal
import uuid

from .auth import get_current_user
from .database import get_supabase_client

router = APIRouter(prefix="/api/exercise", tags=["exercise"])

# ============================================================================
# PYDANTIC MODELS
# ============================================================================

class ExerciseBase(BaseModel):
    name_en: str
    name_fr: str
    muscle_group: str
    equipment: Optional[str] = ""
    description: Optional[str] = ""

class ExerciseCreate(ExerciseBase):
    pass

class Exercise(ExerciseBase):
    id: str
    is_custom: bool = False
    user_id: Optional[str] = None
    created_at: datetime

class ExerciseSet(BaseModel):
    id: str
    workout_exercise_id: str
    reps: int
    weight: Decimal
    is_completed: bool = False
    set_order: int
    created_at: datetime

class ExerciseSetCreate(BaseModel):
    reps: int
    weight: Decimal
    set_order: int = 1

class ExerciseSetUpdate(BaseModel):
    reps: Optional[int] = None
    weight: Optional[Decimal] = None
    is_completed: Optional[bool] = None

class WorkoutExercise(BaseModel):
    id: str
    session_id: str
    exercise_id: str
    order_index: int
    created_at: datetime
    exercise: Optional[Exercise] = None
    sets: List[ExerciseSet] = []

class WorkoutExerciseCreate(BaseModel):
    exercise_id: str
    order_index: int = 0

class WorkoutSession(BaseModel):
    id: str
    user_id: str
    name: str
    start_time: datetime
    end_time: Optional[datetime] = None
    is_completed: bool = False
    created_at: datetime
    exercises: List[WorkoutExercise] = []

class WorkoutSessionCreate(BaseModel):
    name: str
    start_time: Optional[datetime] = None

class WorkoutSessionUpdate(BaseModel):
    name: Optional[str] = None
    end_time: Optional[datetime] = None
    is_completed: Optional[bool] = None

# HIIT Models
class HIITWorkout(BaseModel):
    id: str
    title_en: str
    title_fr: str
    description_en: Optional[str] = None
    description_fr: Optional[str] = None
    work_duration: int  # seconds
    rest_duration: int  # seconds
    total_duration: int  # seconds
    total_rounds: int
    is_custom: bool = False
    user_id: Optional[str] = None
    created_at: datetime

class HIITWorkoutCreate(BaseModel):
    title_en: str
    title_fr: str
    description_en: Optional[str] = None
    description_fr: Optional[str] = None
    work_duration: int
    rest_duration: int
    total_rounds: int

class HIITSession(BaseModel):
    id: str
    user_id: str
    workout_id: Optional[str] = None
    start_time: datetime
    end_time: Optional[datetime] = None
    current_phase: str = "work"  # work, rest, complete
    current_round: int = 1
    is_completed: bool = False
    created_at: datetime
    workout: Optional[HIITWorkout] = None

class HIITSessionCreate(BaseModel):
    workout_id: Optional[str] = None
    start_time: Optional[datetime] = None

class HIITSessionUpdate(BaseModel):
    current_phase: Optional[str] = None
    current_round: Optional[int] = None
    end_time: Optional[datetime] = None
    is_completed: Optional[bool] = None

# Cardio Models
class CardioActivity(BaseModel):
    id: str
    activity_type: str  # running, walking, bike, etc.
    name_en: str
    name_fr: str
    is_custom: bool = False
    user_id: Optional[str] = None
    created_at: datetime

class CardioActivityCreate(BaseModel):
    activity_type: str
    name_en: str
    name_fr: str

class CardioSession(BaseModel):
    id: str
    user_id: str
    activity_type: str
    activity_title: str
    format_title: str
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: int = 0
    distance_km: Decimal = Decimal('0')
    target_distance_km: Optional[Decimal] = None
    target_duration_seconds: Optional[int] = None
    average_speed_kmh: Decimal = Decimal('0')
    current_speed_kmh: Decimal = Decimal('0')
    steps: int = 0
    calories: int = 0
    is_running: bool = False
    is_paused: bool = False
    notes: Optional[str] = None
    created_at: datetime

class CardioSessionCreate(BaseModel):
    activity_type: str
    activity_title: str
    format_title: str
    target_distance_km: Optional[Decimal] = None
    target_duration_seconds: Optional[int] = None
    start_time: Optional[datetime] = None

class CardioSessionUpdate(BaseModel):
    end_time: Optional[datetime] = None
    duration_seconds: Optional[int] = None
    distance_km: Optional[Decimal] = None
    average_speed_kmh: Optional[Decimal] = None
    current_speed_kmh: Optional[Decimal] = None
    steps: Optional[int] = None
    calories: Optional[int] = None
    is_running: Optional[bool] = None
    is_paused: Optional[bool] = None
    notes: Optional[str] = None

# Response Models
class ExerciseStats(BaseModel):
    total_workouts: int
    total_exercises: int
    total_sets: int
    total_weight_lifted: Decimal
    favorite_muscle_groups: List[Dict[str, Any]]
    recent_prs: List[Dict[str, Any]]

class WorkoutSummary(BaseModel):
    session_id: str
    name: str
    date: date
    duration_minutes: Optional[int]
    exercises_count: int
    sets_count: int
    total_weight: Decimal

# ============================================================================
# EXERCISE ENDPOINTS
# ============================================================================

@router.get("/exercises", response_model=List[Exercise])
async def get_exercises(
    muscle_group: Optional[str] = Query(None, description="Filter by muscle group"),
    equipment: Optional[str] = Query(None, description="Filter by equipment"),
    search: Optional[str] = Query(None, description="Search in exercise names"),
    include_custom: bool = Query(True, description="Include custom exercises"),
    limit: int = Query(50, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user)
):
    """Get list of exercises with optional filtering"""
    supabase = get_supabase_client()
    
    query = supabase.table("exercises").select("*")
    
    # Apply filters
    if muscle_group:
        query = query.eq("muscle_group", muscle_group)
    
    if equipment:
        query = query.eq("equipment", equipment)
    
    if search:
        query = query.or_(f"name_en.ilike.%{search}%,name_fr.ilike.%{search}%")
    
    if not include_custom:
        query = query.eq("is_custom", False)
    else:
        # Include public exercises and user's custom exercises
        query = query.or_(f"is_custom.eq.false,user_id.eq.{current_user['id']}")
    
    query = query.range(offset, offset + limit - 1).order("name_en")
    
    result = query.execute()
    
    if result.data is None:
        raise HTTPException(status_code=500, detail="Failed to fetch exercises")
    
    return result.data

@router.get("/exercises/muscle-groups")
async def get_muscle_groups(current_user: dict = Depends(get_current_user)):
    """Get list of available muscle groups"""
    supabase = get_supabase_client()
    
    result = supabase.table("exercises").select("muscle_group").execute()
    
    if result.data is None:
        raise HTTPException(status_code=500, detail="Failed to fetch muscle groups")
    
    muscle_groups = list(set([ex["muscle_group"] for ex in result.data if ex["muscle_group"]]))
    return {"muscle_groups": sorted(muscle_groups)}

@router.get("/exercises/{exercise_id}", response_model=Exercise)
async def get_exercise(
    exercise_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get specific exercise by ID"""
    supabase = get_supabase_client()
    
    result = supabase.table("exercises").select("*").eq("id", exercise_id).execute()
    
    if not result.data:
        raise HTTPException(status_code=404, detail="Exercise not found")
    
    exercise = result.data[0]
    
    # Check if user can access this exercise
    if exercise["is_custom"] and exercise["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Access denied to this custom exercise")
    
    return exercise

@router.post("/exercises", response_model=Exercise)
async def create_custom_exercise(
    exercise: ExerciseCreate,
    current_user: dict = Depends(get_current_user)
):
    """Create a custom exercise"""
    supabase = get_supabase_client()
    
    exercise_data = {
        **exercise.dict(),
        "is_custom": True,
        "user_id": current_user["id"]
    }
    
    result = supabase.table("exercises").insert(exercise_data).execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create exercise")
    
    return result.data[0]

# ============================================================================
# WORKOUT SESSION ENDPOINTS
# ============================================================================

@router.get("/workouts", response_model=List[WorkoutSession])
async def get_workout_sessions(
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    include_exercises: bool = Query(False),
    current_user: dict = Depends(get_current_user)
):
    """Get user's workout sessions"""
    supabase = get_supabase_client()
    
    select_query = "*"
    if include_exercises:
        select_query += ", workout_exercises(*, exercises(*), exercise_sets(*))"
    
    result = supabase.table("workout_sessions")\
        .select(select_query)\
        .eq("user_id", current_user["id"])\
        .range(offset, offset + limit - 1)\
        .order("start_time", desc=True)\
        .execute()
    
    if result.data is None:
        raise HTTPException(status_code=500, detail="Failed to fetch workout sessions")
    
    return result.data

@router.get("/workouts/{session_id}", response_model=WorkoutSession)
async def get_workout_session(
    session_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Get specific workout session with exercises and sets"""
    supabase = get_supabase_client()
    
    result = supabase.table("workout_sessions")\
        .select("*, workout_exercises(*, exercises(*), exercise_sets(*))")\
        .eq("id", session_id)\
        .eq("user_id", current_user["id"])\
        .execute()
    
    if not result.data:
        raise HTTPException(status_code=404, detail="Workout session not found")
    
    return result.data[0]

@router.post("/workouts", response_model=WorkoutSession)
async def create_workout_session(
    workout: WorkoutSessionCreate,
    current_user: dict = Depends(get_current_user)
):
    """Create a new workout session"""
    supabase = get_supabase_client()
    
    workout_data = {
        **workout.dict(),
        "user_id": current_user["id"],
        "start_time": workout.start_time or datetime.utcnow()
    }
    
    result = supabase.table("workout_sessions").insert(workout_data).execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create workout session")
    
    return result.data[0]

@router.put("/workouts/{session_id}", response_model=WorkoutSession)
async def update_workout_session(
    session_id: str,
    workout_update: WorkoutSessionUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Update workout session"""
    supabase = get_supabase_client()
    
    # Verify ownership
    session_check = supabase.table("workout_sessions")\
        .select("id")\
        .eq("id", session_id)\
        .eq("user_id", current_user["id"])\
        .execute()
    
    if not session_check.data:
        raise HTTPException(status_code=404, detail="Workout session not found")
    
    update_data = {k: v for k, v in workout_update.dict().items() if v is not None}
    
    result = supabase.table("workout_sessions")\
        .update(update_data)\
        .eq("id", session_id)\
        .execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to update workout session")
    
    return result.data[0]

# ============================================================================
# WORKOUT EXERCISES ENDPOINTS
# ============================================================================

@router.post("/workouts/{session_id}/exercises", response_model=WorkoutExercise)
async def add_exercise_to_workout(
    session_id: str,
    exercise: WorkoutExerciseCreate,
    current_user: dict = Depends(get_current_user)
):
    """Add an exercise to a workout session"""
    supabase = get_supabase_client()
    
    # Verify session ownership
    session_check = supabase.table("workout_sessions")\
        .select("id")\
        .eq("id", session_id)\
        .eq("user_id", current_user["id"])\
        .execute()
    
    if not session_check.data:
        raise HTTPException(status_code=404, detail="Workout session not found")
    
    exercise_data = {
        **exercise.dict(),
        "session_id": session_id
    }
    
    result = supabase.table("workout_exercises").insert(exercise_data).execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to add exercise to workout")
    
    return result.data[0]

@router.delete("/workouts/{session_id}/exercises/{exercise_id}")
async def remove_exercise_from_workout(
    session_id: str,
    exercise_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Remove an exercise from a workout session"""
    supabase = get_supabase_client()
    
    # Verify session ownership through workout_exercises
    exercise_check = supabase.table("workout_exercises")\
        .select("*, workout_sessions!inner(user_id)")\
        .eq("id", exercise_id)\
        .eq("session_id", session_id)\
        .execute()
    
    if not exercise_check.data or exercise_check.data[0]["workout_sessions"]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Exercise not found in workout")
    
    # Delete associated sets first
    supabase.table("exercise_sets").delete().eq("workout_exercise_id", exercise_id).execute()
    
    # Delete the exercise
    result = supabase.table("workout_exercises").delete().eq("id", exercise_id).execute()
    
    return {"message": "Exercise removed from workout"}

# ============================================================================
# EXERCISE SETS ENDPOINTS
# ============================================================================

@router.post("/workouts/exercises/{workout_exercise_id}/sets", response_model=ExerciseSet)
async def add_set_to_exercise(
    workout_exercise_id: str,
    exercise_set: ExerciseSetCreate,
    current_user: dict = Depends(get_current_user)
):
    """Add a set to an exercise in a workout"""
    supabase = get_supabase_client()
    
    # Verify ownership through workout_exercises -> workout_sessions
    exercise_check = supabase.table("workout_exercises")\
        .select("*, workout_sessions!inner(user_id)")\
        .eq("id", workout_exercise_id)\
        .execute()
    
    if not exercise_check.data or exercise_check.data[0]["workout_sessions"]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Workout exercise not found")
    
    set_data = {
        **exercise_set.dict(),
        "workout_exercise_id": workout_exercise_id
    }
    
    result = supabase.table("exercise_sets").insert(set_data).execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to add set")
    
    return result.data[0]

@router.put("/sets/{set_id}", response_model=ExerciseSet)
async def update_exercise_set(
    set_id: str,
    set_update: ExerciseSetUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Update an exercise set"""
    supabase = get_supabase_client()
    
    # Verify ownership
    set_check = supabase.table("exercise_sets")\
        .select("*, workout_exercises!inner(*, workout_sessions!inner(user_id))")\
        .eq("id", set_id)\
        .execute()
    
    if not set_check.data or set_check.data[0]["workout_exercises"]["workout_sessions"]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Exercise set not found")
    
    update_data = {k: v for k, v in set_update.dict().items() if v is not None}
    
    result = supabase.table("exercise_sets")\
        .update(update_data)\
        .eq("id", set_id)\
        .execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to update set")
    
    return result.data[0]

@router.delete("/sets/{set_id}")
async def delete_exercise_set(
    set_id: str,
    current_user: dict = Depends(get_current_user)
):
    """Delete an exercise set"""
    supabase = get_supabase_client()
    
    # Verify ownership
    set_check = supabase.table("exercise_sets")\
        .select("*, workout_exercises!inner(*, workout_sessions!inner(user_id))")\
        .eq("id", set_id)\
        .execute()
    
    if not set_check.data or set_check.data[0]["workout_exercises"]["workout_sessions"]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=404, detail="Exercise set not found")
    
    result = supabase.table("exercise_sets").delete().eq("id", set_id).execute()
    
    return {"message": "Exercise set deleted"}

# ============================================================================
# HIIT ENDPOINTS
# ============================================================================

@router.get("/hiit/workouts", response_model=List[HIITWorkout])
async def get_hiit_workouts(
    include_custom: bool = Query(True),
    current_user: dict = Depends(get_current_user)
):
    """Get available HIIT workouts"""
    supabase = get_supabase_client()
    
    query = supabase.table("hiit_workouts").select("*")
    
    if not include_custom:
        query = query.eq("is_custom", False)
    else:
        query = query.or_(f"is_custom.eq.false,user_id.eq.{current_user['id']}")
    
    result = query.order("title_en").execute()
    
    if result.data is None:
        raise HTTPException(status_code=500, detail="Failed to fetch HIIT workouts")
    
    return result.data

@router.post("/hiit/workouts", response_model=HIITWorkout)
async def create_hiit_workout(
    workout: HIITWorkoutCreate,
    current_user: dict = Depends(get_current_user)
):
    """Create a custom HIIT workout"""
    supabase = get_supabase_client()
    
    # Calculate total duration
    total_duration = (workout.work_duration + workout.rest_duration) * workout.total_rounds
    
    workout_data = {
        **workout.dict(),
        "total_duration": total_duration,
        "is_custom": True,
        "user_id": current_user["id"]
    }
    
    result = supabase.table("hiit_workouts").insert(workout_data).execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create HIIT workout")
    
    return result.data[0]

@router.get("/hiit/sessions", response_model=List[HIITSession])
async def get_hiit_sessions(
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user)
):
    """Get user's HIIT sessions"""
    supabase = get_supabase_client()
    
    result = supabase.table("hiit_sessions")\
        .select("*, hiit_workouts(*)")\
        .eq("user_id", current_user["id"])\
        .range(offset, offset + limit - 1)\
        .order("start_time", desc=True)\
        .execute()
    
    if result.data is None:
        raise HTTPException(status_code=500, detail="Failed to fetch HIIT sessions")
    
    return result.data

@router.post("/hiit/sessions", response_model=HIITSession)
async def create_hiit_session(
    session: HIITSessionCreate,
    current_user: dict = Depends(get_current_user)
):
    """Start a new HIIT session"""
    supabase = get_supabase_client()
    
    session_data = {
        **session.dict(),
        "user_id": current_user["id"],
        "start_time": session.start_time or datetime.utcnow()
    }
    
    result = supabase.table("hiit_sessions").insert(session_data).execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create HIIT session")
    
    return result.data[0]

@router.put("/hiit/sessions/{session_id}", response_model=HIITSession)
async def update_hiit_session(
    session_id: str,
    session_update: HIITSessionUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Update HIIT session (progress, completion, etc.)"""
    supabase = get_supabase_client()
    
    # Verify ownership
    session_check = supabase.table("hiit_sessions")\
        .select("id")\
        .eq("id", session_id)\
        .eq("user_id", current_user["id"])\
        .execute()
    
    if not session_check.data:
        raise HTTPException(status_code=404, detail="HIIT session not found")
    
    update_data = {k: v for k, v in session_update.dict().items() if v is not None}
    
    result = supabase.table("hiit_sessions")\
        .update(update_data)\
        .eq("id", session_id)\
        .execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to update HIIT session")
    
    return result.data[0]

# ============================================================================
# CARDIO ENDPOINTS
# ============================================================================

@router.get("/cardio/activities", response_model=List[CardioActivity])
async def get_cardio_activities(
    include_custom: bool = Query(True),
    current_user: dict = Depends(get_current_user)
):
    """Get available cardio activities"""
    supabase = get_supabase_client()
    
    query = supabase.table("cardio_activities").select("*")
    
    if not include_custom:
        query = query.eq("is_custom", False)
    else:
        query = query.or_(f"is_custom.eq.false,user_id.eq.{current_user['id']}")
    
    result = query.order("name_en").execute()
    
    if result.data is None:
        raise HTTPException(status_code=500, detail="Failed to fetch cardio activities")
    
    return result.data

@router.post("/cardio/activities", response_model=CardioActivity)
async def create_cardio_activity(
    activity: CardioActivityCreate,
    current_user: dict = Depends(get_current_user)
):
    """Create a custom cardio activity"""
    supabase = get_supabase_client()
    
    activity_data = {
        **activity.dict(),
        "is_custom": True,
        "user_id": current_user["id"]
    }
    
    result = supabase.table("cardio_activities").insert(activity_data).execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create cardio activity")
    
    return result.data[0]

@router.get("/cardio/sessions", response_model=List[CardioSession])
async def get_cardio_sessions(
    limit: int = Query(20, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user)
):
    """Get user's cardio sessions"""
    supabase = get_supabase_client()
    
    result = supabase.table("cardio_sessions")\
        .select("*")\
        .eq("user_id", current_user["id"])\
        .range(offset, offset + limit - 1)\
        .order("start_time", desc=True)\
        .execute()
    
    if result.data is None:
        raise HTTPException(status_code=500, detail="Failed to fetch cardio sessions")
    
    return result.data

@router.post("/cardio/sessions", response_model=CardioSession)
async def create_cardio_session(
    session: CardioSessionCreate,
    current_user: dict = Depends(get_current_user)
):
    """Start a new cardio session"""
    supabase = get_supabase_client()
    
    session_data = {
        **session.dict(),
        "user_id": current_user["id"],
        "start_time": session.start_time or datetime.utcnow()
    }
    
    result = supabase.table("cardio_sessions").insert(session_data).execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to create cardio session")
    
    return result.data[0]

@router.put("/cardio/sessions/{session_id}", response_model=CardioSession)
async def update_cardio_session(
    session_id: str,
    session_update: CardioSessionUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Update cardio session (real-time tracking data)"""
    supabase = get_supabase_client()
    
    # Verify ownership
    session_check = supabase.table("cardio_sessions")\
        .select("id")\
        .eq("id", session_id)\
        .eq("user_id", current_user["id"])\
        .execute()
    
    if not session_check.data:
        raise HTTPException(status_code=404, detail="Cardio session not found")
    
    update_data = {k: v for k, v in session_update.dict().items() if v is not None}
    
    result = supabase.table("cardio_sessions")\
        .update(update_data)\
        .eq("id", session_id)\
        .execute()
    
    if not result.data:
        raise HTTPException(status_code=500, detail="Failed to update cardio session")
    
    return result.data[0]

# ============================================================================
# STATISTICS & ANALYTICS ENDPOINTS
# ============================================================================

@router.get("/stats", response_model=ExerciseStats)
async def get_exercise_stats(
    days: int = Query(30, description="Number of days to analyze"),
    current_user: dict = Depends(get_current_user)
):
    """Get user's exercise statistics"""
    supabase = get_supabase_client()
    
    # Get workout sessions count
    workouts_result = supabase.table("workout_sessions")\
        .select("id", count="exact")\
        .eq("user_id", current_user["id"])\
        .gte("start_time", (datetime.utcnow() - timedelta(days=days)).isoformat())\
        .execute()
    
    total_workouts = workouts_result.count or 0
    
    # Get total exercises and sets with weight
    sets_result = supabase.rpc("get_exercise_stats", {
        "user_id": current_user["id"],
        "days_back": days
    }).execute()
    
    if sets_result.data:
        stats_data = sets_result.data[0]
        return ExerciseStats(
            total_workouts=total_workouts,
            total_exercises=stats_data.get("total_exercises", 0),
            total_sets=stats_data.get("total_sets", 0),
            total_weight_lifted=Decimal(str(stats_data.get("total_weight", 0))),
            favorite_muscle_groups=stats_data.get("favorite_muscle_groups", []),
            recent_prs=stats_data.get("recent_prs", [])
        )
    
    return ExerciseStats(
        total_workouts=total_workouts,
        total_exercises=0,
        total_sets=0,
        total_weight_lifted=Decimal('0'),
        favorite_muscle_groups=[],
        recent_prs=[]
    )

@router.get("/workouts/summary", response_model=List[WorkoutSummary])
async def get_workout_summaries(
    days: int = Query(30),
    current_user: dict = Depends(get_current_user)
):
    """Get workout summaries for the specified period"""
    supabase = get_supabase_client()
    
    result = supabase.rpc("get_workout_summaries", {
        "user_id": current_user["id"],
        "days_back": days
    }).execute()
    
    if result.data is None:
        raise HTTPException(status_code=500, detail="Failed to fetch workout summaries")
    
    return result.data 