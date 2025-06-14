from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, date
from enum import Enum

# =======================
# BASE MODELS
# =======================

class TimestampMixin(BaseModel):
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

# =======================
# USER MODELS
# =======================

class UserCreate(BaseModel):
    email: str
    password: str
    name: Optional[str] = None

class UserLogin(BaseModel):
    email: str
    password: str

class UserProfile(BaseModel):
    id: str
    email: str
    name: Optional[str] = None
    is_onboarded: bool = False
    created_at: datetime
    updated_at: datetime

class UserUpdate(BaseModel):
    name: Optional[str] = None
    is_onboarded: Optional[bool] = None

# =======================
# EXERCISE MODELS
# =======================

class ExerciseBase(BaseModel):
    name: str
    muscle_group: str
    equipment: str = ""
    description: str = ""

class ExerciseCreate(ExerciseBase):
    is_custom: bool = False

class Exercise(ExerciseBase, TimestampMixin):
    id: str
    is_custom: bool = False
    created_by: Optional[str] = None

# =======================
# WORKOUT MODELS
# =======================

class ExerciseSetBase(BaseModel):
    reps: int
    weight: float
    is_completed: bool = False

class ExerciseSetCreate(ExerciseSetBase):
    pass

class ExerciseSet(ExerciseSetBase, TimestampMixin):
    id: str
    workout_exercise_id: str
    set_order: int = 1

class WorkoutExerciseBase(BaseModel):
    exercise_id: str
    order_index: int = 0

class WorkoutExerciseCreate(WorkoutExerciseBase):
    sets: List[ExerciseSetCreate] = []

class WorkoutExercise(WorkoutExerciseBase, TimestampMixin):
    id: str
    session_id: str
    exercise: Optional[Exercise] = None
    sets: List[ExerciseSet] = []

class WorkoutSessionBase(BaseModel):
    name: str
    start_time: datetime
    end_time: Optional[datetime] = None

class WorkoutSessionCreate(WorkoutSessionBase):
    exercises: List[WorkoutExerciseCreate] = []

class WorkoutSession(WorkoutSessionBase, TimestampMixin):
    id: str
    user_id: str
    is_completed: bool = False
    exercises: List[WorkoutExercise] = []

# =======================
# HIIT MODELS
# =======================

class HiitWorkoutBase(BaseModel):
    title: str
    description: Optional[str] = None
    work_duration: int  # seconds
    rest_duration: int  # seconds
    total_duration: int  # minutes
    total_rounds: int

class HiitWorkoutCreate(HiitWorkoutBase):
    is_custom: bool = False

class HiitWorkout(HiitWorkoutBase, TimestampMixin):
    id: str
    is_custom: bool = False
    created_by: Optional[str] = None

class HiitPhase(str, Enum):
    WORK = "work"
    REST = "rest"
    WARMUP = "warmup"
    COOLDOWN = "cooldown"
    FINISHED = "finished"

class HiitSessionBase(BaseModel):
    workout_id: str
    start_time: datetime
    end_time: Optional[datetime] = None
    current_phase: HiitPhase = HiitPhase.WORK
    current_round: int = 1

class HiitSessionCreate(HiitSessionBase):
    pass

class HiitSession(HiitSessionBase, TimestampMixin):
    id: str
    user_id: str
    is_completed: bool = False
    workout: Optional[HiitWorkout] = None

# =======================
# CARDIO MODELS
# =======================

class CardioSessionBase(BaseModel):
    activity_type: str  # running, bike, walking
    activity_title: str
    format_title: str
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_seconds: int = 0
    distance_km: float = 0
    target_distance_km: Optional[float] = None
    target_duration_seconds: Optional[int] = None
    average_speed_kmh: float = 0
    current_speed_kmh: float = 0
    steps: int = 0
    calories: int = 0
    is_running: bool = False
    is_paused: bool = False
    notes: Optional[str] = None

class CardioSessionCreate(CardioSessionBase):
    pass

class CardioSession(CardioSessionBase, TimestampMixin):
    id: str
    user_id: str

class LocationPointBase(BaseModel):
    latitude: float
    longitude: float
    altitude: Optional[float] = None
    speed_kmh: Optional[float] = None
    recorded_at: datetime

class LocationPointCreate(LocationPointBase):
    pass

class LocationPoint(LocationPointBase, TimestampMixin):
    id: str
    cardio_session_id: str

# =======================
# NUTRITION MODELS
# =======================

class FoodBase(BaseModel):
    name: str
    calories_per_100g: int
    protein_per_100g: float = 0
    carbs_per_100g: float = 0
    fat_per_100g: float = 0

class FoodCreate(FoodBase):
    is_custom: bool = False

class Food(FoodBase, TimestampMixin):
    id: str
    is_custom: bool = False
    created_by: Optional[str] = None

class MealBase(BaseModel):
    meal_time: str  # breakfast, lunch, dinner, snack
    name: str
    date: date

class MealCreate(MealBase):
    pass

class Meal(MealBase, TimestampMixin):
    id: str
    user_id: str

class MealFoodItemBase(BaseModel):
    food_id: str
    portion: str
    calories: int

class MealFoodItemCreate(MealFoodItemBase):
    pass

class MealFoodItem(MealFoodItemBase, TimestampMixin):
    id: str
    meal_id: str
    food: Optional[Food] = None

# =======================
# RESPONSE MODELS
# =======================

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserProfile

class MessageResponse(BaseModel):
    message: str
    success: bool = True

class ListResponse(BaseModel):
    items: List[dict]
    total: int
    page: int = 1
    per_page: int = 20

# =======================
# MOBILE-OPTIMIZED MODELS
# =======================

class ExerciseLite(BaseModel):
    """Lightweight exercise model for mobile lists"""
    id: str
    name: str
    muscle_group: str
    equipment: str = ""

class WorkoutSummary(BaseModel):
    """Lightweight workout summary for mobile dashboard"""
    id: str
    name: str
    start_time: datetime
    duration_minutes: Optional[int] = None
    exercises_count: int = 0
    is_completed: bool = False

class NutritionSummary(BaseModel):
    """Daily nutrition summary for mobile dashboard"""
    date: date
    total_calories: int
    total_protein: float
    total_carbs: float
    total_fat: float
    meals_count: int
    water_intake_ml: int = 0

class MobileSync(BaseModel):
    """Synchronization data for offline mobile app"""
    last_sync: datetime
    exercises: List[ExerciseLite] = []
    workouts: List[WorkoutSummary] = []
    nutrition: Optional[NutritionSummary] = None
    pending_uploads: int = 0

class BatchRequest(BaseModel):
    """Batch operations for mobile efficiency"""
    operations: List[dict]
    sync_timestamp: datetime

class BatchResponse(BaseModel):
    """Batch operation results"""
    results: List[dict]
    errors: List[dict] = []
    sync_timestamp: datetime
    success_count: int
    error_count: int

class OfflineAction(BaseModel):
    """Offline action to be synced when online"""
    id: str
    action_type: str  # create, update, delete
    resource_type: str  # workout, meal, etc.
    data: dict
    timestamp: datetime
    user_id: str

# =======================
# PAGINATION MODELS
# =======================

class PaginatedResponse(BaseModel):
    """Enhanced pagination for mobile"""
    items: List[dict]
    total: int
    page: int
    per_page: int
    total_pages: int
    has_next: bool
    has_prev: bool
    
    @classmethod
    def create(cls, items: List[dict], total: int, page: int, per_page: int):
        total_pages = (total + per_page - 1) // per_page
        return cls(
            items=items,
            total=total,
            page=page,
            per_page=per_page,
            total_pages=total_pages,
            has_next=page < total_pages,
            has_prev=page > 1
        ) 