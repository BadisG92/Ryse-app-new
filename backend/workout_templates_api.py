"""
Workout Templates API - Gestion des templates d'entraînement
Permet de gérer les templates pré-paramétrés et personnalisés
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from uuid import UUID
import logging
from datetime import datetime

from auth import get_current_user
from database import get_supabase_client

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/workout-templates", tags=["Workout Templates"])

# ==================== MODÈLES PYDANTIC ====================

class WorkoutTemplateExerciseCreate(BaseModel):
    exercise_id: UUID
    order_index: int = 0
    suggested_sets: int = 3
    suggested_reps_min: int = 8
    suggested_reps_max: int = 12
    suggested_weight_percentage: Optional[float] = None
    suggested_rest_seconds: int = 60
    notes_en: Optional[str] = None
    notes_fr: Optional[str] = None

class WorkoutTemplateExerciseResponse(BaseModel):
    id: UUID
    exercise_id: UUID
    exercise_name_en: str
    exercise_name_fr: str
    muscle_group: str
    equipment: str
    order_index: int
    suggested_sets: int
    suggested_reps_min: int
    suggested_reps_max: int
    suggested_weight_percentage: Optional[float]
    suggested_rest_seconds: int
    notes_en: Optional[str]
    notes_fr: Optional[str]

class WorkoutTemplateCreate(BaseModel):
    name_en: str = Field(..., min_length=1, max_length=100)
    name_fr: str = Field(..., min_length=1, max_length=100)
    description_en: Optional[str] = None
    description_fr: Optional[str] = None
    difficulty_level: str = Field(default="beginner")
    estimated_duration_minutes: int = Field(default=60, ge=10, le=300)
    target_muscle_groups: List[str] = []
    equipment_needed: List[str] = []
    calories_burned_estimate: int = Field(default=0, ge=0)
    is_public: bool = False

class WorkoutTemplateUpdate(BaseModel):
    name_en: Optional[str] = Field(None, min_length=1, max_length=100)
    name_fr: Optional[str] = Field(None, min_length=1, max_length=100)
    description_en: Optional[str] = None
    description_fr: Optional[str] = None
    difficulty_level: Optional[str] = Field(None, regex="^(beginner|intermediate|advanced)$")
    estimated_duration_minutes: Optional[int] = Field(None, ge=10, le=300)
    target_muscle_groups: Optional[List[str]] = None
    equipment_needed: Optional[List[str]] = None
    calories_burned_estimate: Optional[int] = Field(None, ge=0)
    is_public: Optional[bool] = None

class WorkoutTemplateResponse(BaseModel):
    id: UUID
    name_en: str
    name_fr: str
    description_en: Optional[str]
    description_fr: Optional[str]
    difficulty_level: str
    estimated_duration_minutes: int
    target_muscle_groups: List[str]
    equipment_needed: List[str]
    calories_burned_estimate: int
    is_custom: bool
    is_public: bool
    user_id: Optional[UUID]
    created_from_session_id: Optional[UUID]
    usage_count: int
    average_rating: float
    created_at: datetime
    updated_at: datetime
    exercises: List[WorkoutTemplateExerciseResponse] = []

class CreateTemplateFromSessionRequest(BaseModel):
    session_id: UUID
    name_en: str = Field(..., min_length=1, max_length=100)
    name_fr: str = Field(..., min_length=1, max_length=100)
    description_en: Optional[str] = None
    description_fr: Optional[str] = None
    is_public: bool = False

class WorkoutTemplateRatingCreate(BaseModel):
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None

class WorkoutTemplateRatingResponse(BaseModel):
    id: UUID
    template_id: UUID
    user_id: UUID
    rating: int
    comment: Optional[str]
    created_at: datetime

# ==================== ENDPOINTS ====================

@router.get("/", response_model=List[WorkoutTemplateResponse])
async def get_workout_templates(
    difficulty: Optional[str] = Query(None),
    muscle_group: Optional[str] = Query(None),
    is_custom: Optional[bool] = Query(None),
    search: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user)
):
    """Récupérer la liste des templates d'entraînement avec filtres"""
    try:
        supabase = get_supabase_client()
        
        query = supabase.table("workout_templates").select("*")
        
        if difficulty:
            query = query.eq("difficulty_level", difficulty)
        if is_custom is not None:
            query = query.eq("is_custom", is_custom)
        if muscle_group:
            query = query.contains("target_muscle_groups", [muscle_group])
        if search:
            query = query.or_(f"name_en.ilike.%{search}%,name_fr.ilike.%{search}%")
        
        query = query.order("usage_count", desc=True).order("average_rating", desc=True)
        query = query.range(offset, offset + limit - 1)
        
        result = query.execute()
        
        return [WorkoutTemplateResponse(**template) for template in result.data]
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des templates: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{template_id}", response_model=WorkoutTemplateResponse)
async def get_workout_template(
    template_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Récupérer un template d'entraînement spécifique"""
    try:
        supabase = get_supabase_client()
        
        result = supabase.table("workout_templates").select("""
            *,
            workout_template_exercises(
                id, exercise_id, order_index, suggested_sets,
                suggested_reps_min, suggested_reps_max, suggested_weight_percentage,
                suggested_rest_seconds, notes_en, notes_fr,
                exercises(name_en, name_fr, muscle_group, equipment)
            )
        """).eq("id", str(template_id)).execute()
        
        if not result.data:
            raise HTTPException(status_code=404, detail="Template non trouvé")
        
        template = result.data[0]
        
        # Transformer les exercices
        exercises = []
        for te in template.get("workout_template_exercises", []):
            exercise_data = te.get("exercises", {})
            exercises.append(WorkoutTemplateExerciseResponse(
                id=te["id"],
                exercise_id=te["exercise_id"],
                exercise_name_en=exercise_data.get("name_en", ""),
                exercise_name_fr=exercise_data.get("name_fr", ""),
                muscle_group=exercise_data.get("muscle_group", ""),
                equipment=exercise_data.get("equipment", ""),
                order_index=te["order_index"],
                suggested_sets=te["suggested_sets"],
                suggested_reps_min=te["suggested_reps_min"],
                suggested_reps_max=te["suggested_reps_max"],
                suggested_weight_percentage=te["suggested_weight_percentage"],
                suggested_rest_seconds=te["suggested_rest_seconds"],
                notes_en=te["notes_en"],
                notes_fr=te["notes_fr"]
            ))
        
        exercises.sort(key=lambda x: x.order_index)
        
        return WorkoutTemplateResponse(**template, exercises=exercises)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la récupération du template: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/", response_model=WorkoutTemplateResponse)
async def create_workout_template(
    template: WorkoutTemplateCreate,
    current_user: dict = Depends(get_current_user)
):
    """Créer un nouveau template d'entraînement personnalisé"""
    try:
        supabase = get_supabase_client()
        user_id = current_user["sub"]
        
        # Créer le template principal
        template_data = {
            "name_en": template.name_en,
            "name_fr": template.name_fr,
            "description_en": template.description_en,
            "description_fr": template.description_fr,
            "difficulty_level": template.difficulty_level,
            "estimated_duration_minutes": template.estimated_duration_minutes,
            "target_muscle_groups": template.target_muscle_groups,
            "equipment_needed": template.equipment_needed,
            "calories_burned_estimate": template.calories_burned_estimate,
            "is_custom": True,
            "is_public": template.is_public,
            "user_id": user_id
        }
        
        result = supabase.table("workout_templates").insert(template_data).execute()
        
        if not result.data:
            raise HTTPException(status_code=400, detail="Erreur lors de la création du template")
        
        template_id = result.data[0]["id"]
        
        # Ajouter les exercices
        if template.exercises:
            exercises_data = []
            for exercise in template.exercises:
                exercises_data.append({
                    "template_id": template_id,
                    "exercise_id": str(exercise.exercise_id),
                    "order_index": exercise.order_index,
                    "suggested_sets": exercise.suggested_sets,
                    "suggested_reps_min": exercise.suggested_reps_min,
                    "suggested_reps_max": exercise.suggested_reps_max,
                    "suggested_weight_percentage": exercise.suggested_weight_percentage,
                    "suggested_rest_seconds": exercise.suggested_rest_seconds,
                    "notes_en": exercise.notes_en,
                    "notes_fr": exercise.notes_fr
                })
            
            supabase.table("workout_template_exercises").insert(exercises_data).execute()
        
        # Récupérer le template complet créé
        return await get_workout_template(UUID(template_id), current_user)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la création du template: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/from-session", response_model=WorkoutTemplateResponse)
async def create_template_from_session(
    request: CreateTemplateFromSessionRequest,
    current_user: dict = Depends(get_current_user)
):
    """Créer un template à partir d'une séance d'entraînement existante"""
    try:
        supabase = get_supabase_client()
        user_id = current_user["sub"]
        
        # Vérifier que la session existe et appartient à l'utilisateur
        session_result = supabase.table("workout_sessions").select("""
            *,
            workout_exercises(
                exercise_id, order_index,
                exercise_sets(reps, weight, set_order)
            )
        """).eq("id", str(request.session_id)).eq("user_id", user_id).execute()
        
        if not session_result.data:
            raise HTTPException(status_code=404, detail="Session non trouvée")
        
        session = session_result.data[0]
        
        # Calculer les statistiques des exercices
        exercises_stats = {}
        for we in session.get("workout_exercises", []):
            exercise_id = we["exercise_id"]
            sets_data = we.get("exercise_sets", [])
            
            if sets_data:
                avg_reps = sum(s["reps"] for s in sets_data) / len(sets_data)
                exercises_stats[exercise_id] = {
                    "order_index": we["order_index"],
                    "sets_count": len(sets_data),
                    "avg_reps": int(avg_reps)
                }
        
        # Créer le template
        template_data = {
            "name_en": request.name_en,
            "name_fr": request.name_fr,
            "description_en": request.description_en,
            "description_fr": request.description_fr,
            "difficulty_level": "intermediate",
            "estimated_duration_minutes": 60,
            "is_custom": True,
            "is_public": request.is_public,
            "user_id": user_id,
            "created_from_session_id": str(request.session_id)
        }
        
        result = supabase.table("workout_templates").insert(template_data).execute()
        template_id = result.data[0]["id"]
        
        # Ajouter les exercices avec les statistiques calculées
        if exercises_stats:
            exercises_data = []
            for exercise_id, stats in exercises_stats.items():
                exercises_data.append({
                    "template_id": template_id,
                    "exercise_id": exercise_id,
                    "order_index": stats["order_index"],
                    "suggested_sets": stats["sets_count"],
                    "suggested_reps_min": max(1, stats["avg_reps"] - 2),
                    "suggested_reps_max": stats["avg_reps"] + 2,
                    "suggested_rest_seconds": 60
                })
            
            supabase.table("workout_template_exercises").insert(exercises_data).execute()
        
        return WorkoutTemplateResponse(**result.data[0])
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la création du template depuis la session: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/{template_id}", response_model=WorkoutTemplateResponse)
async def update_workout_template(
    template_id: UUID,
    template_update: WorkoutTemplateUpdate,
    current_user: dict = Depends(get_current_user)
):
    """Mettre à jour un template d'entraînement (seulement ses propres templates)"""
    try:
        supabase = get_supabase_client()
        user_id = current_user["sub"]
        
        # Vérifier que le template existe et appartient à l'utilisateur
        existing = supabase.table("workout_templates").select("*").eq("id", str(template_id)).eq("user_id", user_id).execute()
        
        if not existing.data:
            raise HTTPException(status_code=404, detail="Template non trouvé ou non autorisé")
        
        # Préparer les données de mise à jour
        update_data = {}
        for field, value in template_update.dict(exclude_unset=True).items():
            update_data[field] = value
        
        if update_data:
            update_data["updated_at"] = datetime.utcnow().isoformat()
            supabase.table("workout_templates").update(update_data).eq("id", str(template_id)).execute()
        
        return await get_workout_template(template_id, current_user)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la mise à jour du template: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/{template_id}")
async def delete_workout_template(
    template_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Supprimer un template d'entraînement (seulement ses propres templates)"""
    try:
        supabase = get_supabase_client()
        user_id = current_user["sub"]
        
        # Vérifier que le template existe et appartient à l'utilisateur
        existing = supabase.table("workout_templates").select("*").eq("id", str(template_id)).eq("user_id", user_id).execute()
        
        if not existing.data:
            raise HTTPException(status_code=404, detail="Template non trouvé ou non autorisé")
        
        # Supprimer le template (les exercices seront supprimés en cascade)
        supabase.table("workout_templates").delete().eq("id", str(template_id)).execute()
        
        return {"message": "Template supprimé avec succès"}
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la suppression du template: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{template_id}/use")
async def use_workout_template(
    template_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """Utiliser un template pour créer une nouvelle session d'entraînement"""
    try:
        supabase = get_supabase_client()
        user_id = current_user["sub"]
        
        # Récupérer le template avec ses exercices
        template_result = supabase.table("workout_templates").select("""
            *,
            workout_template_exercises(
                exercise_id, order_index, suggested_sets,
                suggested_reps_min, suggested_reps_max, suggested_rest_seconds
            )
        """).eq("id", str(template_id)).execute()
        
        if not template_result.data:
            raise HTTPException(status_code=404, detail="Template non trouvé")
        
        template = template_result.data[0]
        
        # Créer une nouvelle session d'entraînement
        session_data = {
            "user_id": user_id,
            "name": f"{template['name_fr']} - {datetime.now().strftime('%d/%m/%Y')}",
            "start_time": datetime.utcnow().isoformat(),
            "is_completed": False
        }
        
        session_result = supabase.table("workout_sessions").insert(session_data).execute()
        session_id = session_result.data[0]["id"]
        
        # Ajouter les exercices du template à la session
        if template.get("workout_template_exercises"):
            exercises_data = []
            for te in template["workout_template_exercises"]:
                exercises_data.append({
                    "session_id": session_id,
                    "exercise_id": te["exercise_id"],
                    "order_index": te["order_index"]
                })
            
            supabase.table("workout_exercises").insert(exercises_data).execute()
        
        # Incrémenter le compteur d'utilisation
        supabase.rpc("increment_template_usage", {"template_uuid": str(template_id)}).execute()
        
        return {
            "message": "Session créée à partir du template",
            "session_id": session_id,
            "template_suggestions": {
                "exercises": [
                    {
                        "exercise_id": te["exercise_id"],
                        "suggested_sets": te["suggested_sets"],
                        "suggested_reps_range": f"{te['suggested_reps_min']}-{te['suggested_reps_max']}",
                        "suggested_rest_seconds": te["suggested_rest_seconds"]
                    }
                    for te in template.get("workout_template_exercises", [])
                ]
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de l'utilisation du template: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/{template_id}/rate", response_model=WorkoutTemplateRatingResponse)
async def rate_workout_template(
    template_id: UUID,
    rating: WorkoutTemplateRatingCreate,
    current_user: dict = Depends(get_current_user)
):
    """Noter un template d'entraînement"""
    try:
        supabase = get_supabase_client()
        user_id = current_user["sub"]
        
        # Vérifier que le template existe
        template_check = supabase.table("workout_templates").select("id").eq("id", str(template_id)).execute()
        if not template_check.data:
            raise HTTPException(status_code=404, detail="Template non trouvé")
        
        # Insérer ou mettre à jour la note
        rating_data = {
            "template_id": str(template_id),
            "user_id": user_id,
            "rating": rating.rating,
            "comment": rating.comment
        }
        
        result = supabase.table("workout_template_ratings").upsert(rating_data).execute()
        
        return WorkoutTemplateRatingResponse(**result.data[0])
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erreur lors de la notation du template: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{template_id}/ratings", response_model=List[WorkoutTemplateRatingResponse])
async def get_template_ratings(
    template_id: UUID,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user)
):
    """Récupérer les évaluations d'un template"""
    try:
        supabase = get_supabase_client()
        
        result = supabase.table("workout_template_ratings").select("*").eq("template_id", str(template_id)).order("created_at", desc=True).range(offset, offset + limit - 1).execute()
        
        return [WorkoutTemplateRatingResponse(**rating) for rating in result.data]
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des évaluations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/user/my-templates", response_model=List[WorkoutTemplateResponse])
async def get_my_templates(
    current_user: dict = Depends(get_current_user)
):
    """Récupérer tous les templates créés par l'utilisateur"""
    try:
        supabase = get_supabase_client()
        user_id = current_user["sub"]
        
        result = supabase.table("workout_templates").select("""
            *,
            workout_template_exercises(
                id, exercise_id, order_index, suggested_sets,
                suggested_reps_min, suggested_reps_max, suggested_weight_percentage,
                suggested_rest_seconds, notes_en, notes_fr,
                exercises(name_en, name_fr, muscle_group, equipment)
            )
        """).eq("user_id", user_id).order("created_at", desc=True).execute()
        
        templates = []
        for template in result.data:
            exercises = []
            for te in template.get("workout_template_exercises", []):
                exercise_data = te.get("exercises", {})
                exercises.append(WorkoutTemplateExerciseResponse(
                    id=te["id"],
                    exercise_id=te["exercise_id"],
                    exercise_name_en=exercise_data.get("name_en", ""),
                    exercise_name_fr=exercise_data.get("name_fr", ""),
                    muscle_group=exercise_data.get("muscle_group", ""),
                    equipment=exercise_data.get("equipment", ""),
                    order_index=te["order_index"],
                    suggested_sets=te["suggested_sets"],
                    suggested_reps_min=te["suggested_reps_min"],
                    suggested_reps_max=te["suggested_reps_max"],
                    suggested_weight_percentage=te["suggested_weight_percentage"],
                    suggested_rest_seconds=te["suggested_rest_seconds"],
                    notes_en=te["notes_en"],
                    notes_fr=te["notes_fr"]
                ))
            
            exercises.sort(key=lambda x: x.order_index)
            templates.append(WorkoutTemplateResponse(**template, exercises=exercises))
        
        return templates
        
    except Exception as e:
        logger.error(f"Erreur lors de la récupération des templates utilisateur: {e}")
        raise HTTPException(status_code=500, detail=str(e)) 