"""
Custom Content API - Task 8: Develop Custom Content Features
Permet aux utilisateurs de créer et gérer du contenu personnalisé avec partage communautaire
"""

from fastapi import APIRouter, HTTPException, Depends, Query, UploadFile, File
from typing import List, Optional, Dict, Any, Union
from pydantic import BaseModel, Field, validator
from uuid import UUID, uuid4
from datetime import datetime
import json

# Import des dépendances (simulation pour le développement)
try:
    from database import get_supabase_client
    from auth import get_current_user
except ImportError:
    # Fallback pour le développement
    def get_supabase_client():
        return None
    def get_current_user():
        return {"id": "test-user-id", "email": "test@example.com"}

router = APIRouter(prefix="/api/custom-content", tags=["Custom Content"])

# ==================== MODELS ====================

class ContentTag(BaseModel):
    id: Optional[UUID] = None
    name: str
    color: str = "#007AFF"
    category: str = Field(..., regex="^(food|exercise|recipe|workout)$")
    usage_count: int = 0

class CustomFood(BaseModel):
    id: Optional[UUID] = None
    name_en: str
    name_fr: str
    calories: int = Field(..., ge=0)
    proteins: float = Field(default=0, ge=0)
    carbs: float = Field(default=0, ge=0)
    fats: float = Field(default=0, ge=0)
    category: Optional[str] = None
    tags: List[str] = []
    source_url: Optional[str] = None
    is_public: bool = False
    is_verified: bool = False
    
    @validator('calories')
    def validate_calories(cls, v):
        if v > 1000:
            raise ValueError('Calories seem too high for 100g')
        return v

class CustomExercise(BaseModel):
    id: Optional[UUID] = None
    name_en: str
    name_fr: str
    muscle_group: str
    equipment: str = ""
    description: str = ""
    instructions_en: Optional[str] = None
    instructions_fr: Optional[str] = None
    difficulty_level: str = Field(default="beginner", regex="^(beginner|intermediate|advanced)$")
    tags: List[str] = []
    video_url: Optional[str] = None
    image_url: Optional[str] = None
    is_public: bool = False
    is_verified: bool = False

class CustomRecipe(BaseModel):
    id: Optional[UUID] = None
    name_en: str
    name_fr: str
    ingredients: Dict[str, Any]  # JSONB format
    steps_en: List[str]
    steps_fr: List[str]
    image_url: Optional[str] = None
    duration: Optional[str] = None
    servings: int = Field(..., ge=1)
    difficulty: Optional[str] = None
    tags: List[str] = []
    source_url: Optional[str] = None
    nutrition_per_serving: Optional[Dict[str, Any]] = None
    is_public: bool = False
    is_verified: bool = False

class UserCollection(BaseModel):
    id: Optional[UUID] = None
    name: str
    description: Optional[str] = None
    is_public: bool = False
    collection_type: str = Field(..., regex="^(foods|exercises|recipes|workouts)$")
    item_ids: List[UUID] = []

class CommunityRating(BaseModel):
    id: Optional[UUID] = None
    content_type: str = Field(..., regex="^(food|exercise|recipe|workout_template|hiit_workout)$")
    content_id: UUID
    rating: int = Field(..., ge=1, le=5)
    comment: Optional[str] = None
    is_helpful: bool = True

class ContentReport(BaseModel):
    content_type: str = Field(..., regex="^(food|exercise|recipe|workout_template|hiit_workout)$")
    content_id: UUID
    reason: str = Field(..., regex="^(inappropriate|spam|incorrect_info|copyright|other)$")
    description: Optional[str] = None

class ContentFilters(BaseModel):
    search: Optional[str] = None
    tags: List[str] = []
    category: Optional[str] = None
    difficulty: Optional[str] = None
    min_rating: float = 0.0
    only_verified: bool = False
    only_public: bool = False
    created_by_me: bool = False

class PaginationParams(BaseModel):
    page: int = Field(default=1, ge=1)
    limit: int = Field(default=20, ge=1, le=100)

# ==================== CUSTOM FOODS API ====================

@router.get("/foods", response_model=Dict[str, Any])
async def get_custom_foods(
    filters: ContentFilters = Depends(),
    pagination: PaginationParams = Depends(),
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Récupère les aliments personnalisés avec filtres et pagination"""
    try:
        # Construction de la requête avec filtres
        query = supabase.table("foods").select("*")
        
        # Filtres de base
        if filters.created_by_me:
            query = query.eq("user_id", current_user["id"])
        elif filters.only_public:
            query = query.eq("is_public", True)
        else:
            # Contenu public OU créé par l'utilisateur
            query = query.or_(f"is_public.eq.true,user_id.eq.{current_user['id']}")
        
        if filters.only_verified:
            query = query.eq("is_verified", True)
        
        if filters.min_rating > 0:
            query = query.gte("community_rating", filters.min_rating)
        
        if filters.category:
            query = query.eq("category", filters.category)
        
        if filters.search:
            query = query.or_(f"name_en.ilike.%{filters.search}%,name_fr.ilike.%{filters.search}%")
        
        if filters.tags:
            for tag in filters.tags:
                query = query.contains("tags", [tag])
        
        # Pagination
        offset = (pagination.page - 1) * pagination.limit
        query = query.range(offset, offset + pagination.limit - 1)
        query = query.order("community_rating", desc=True)
        
        result = query.execute()
        
        # Count total pour pagination
        count_query = supabase.table("foods").select("id", count="exact")
        if filters.created_by_me:
            count_query = count_query.eq("user_id", current_user["id"])
        elif filters.only_public:
            count_query = count_query.eq("is_public", True)
        
        count_result = count_query.execute()
        total = count_result.count if hasattr(count_result, 'count') else len(result.data)
        
        return {
            "data": result.data,
            "pagination": {
                "page": pagination.page,
                "limit": pagination.limit,
                "total": total,
                "total_pages": (total + pagination.limit - 1) // pagination.limit
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération des aliments: {str(e)}")

@router.post("/foods", response_model=Dict[str, Any])
async def create_custom_food(
    food: CustomFood,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Crée un nouvel aliment personnalisé"""
    try:
        food_data = food.dict(exclude={'id'})
        food_data['user_id'] = current_user['id']
        food_data['is_custom'] = True
        
        result = supabase.table("foods").insert(food_data).execute()
        
        # Créer une contribution communautaire
        contribution_data = {
            "contributor_id": current_user["id"],
            "content_type": "food",
            "content_id": result.data[0]["id"],
            "contribution_type": "created",
            "moderation_status": "approved" if not food.is_public else "pending"
        }
        supabase.table("community_contributions").insert(contribution_data).execute()
        
        return {
            "message": "Aliment créé avec succès",
            "food": result.data[0],
            "requires_moderation": food.is_public
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la création de l'aliment: {str(e)}")

@router.put("/foods/{food_id}")
async def update_custom_food(
    food_id: UUID,
    food: CustomFood,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Met à jour un aliment personnalisé"""
    try:
        # Vérifier que l'utilisateur peut modifier cet aliment
        existing = supabase.table("foods").select("*").eq("id", food_id).execute()
        if not existing.data:
            raise HTTPException(status_code=404, detail="Aliment non trouvé")
        
        if existing.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Non autorisé à modifier cet aliment")
        
        food_data = food.dict(exclude={'id'})
        result = supabase.table("foods").update(food_data).eq("id", food_id).execute()
        
        return {"message": "Aliment mis à jour avec succès", "food": result.data[0]}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la mise à jour: {str(e)}")

@router.delete("/foods/{food_id}")
async def delete_custom_food(
    food_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Supprime un aliment personnalisé"""
    try:
        # Vérifier que l'utilisateur peut supprimer cet aliment
        existing = supabase.table("foods").select("*").eq("id", food_id).execute()
        if not existing.data:
            raise HTTPException(status_code=404, detail="Aliment non trouvé")
        
        if existing.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Non autorisé à supprimer cet aliment")
        
        supabase.table("foods").delete().eq("id", food_id).execute()
        
        return {"message": "Aliment supprimé avec succès"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la suppression: {str(e)}")

# ==================== CUSTOM EXERCISES API ====================

@router.get("/exercises", response_model=Dict[str, Any])
async def get_custom_exercises(
    filters: ContentFilters = Depends(),
    pagination: PaginationParams = Depends(),
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Récupère les exercices personnalisés avec filtres et pagination"""
    try:
        query = supabase.table("exercises").select("*")
        
        if filters.created_by_me:
            query = query.eq("user_id", current_user["id"])
        elif filters.only_public:
            query = query.eq("is_public", True)
        else:
            query = query.or_(f"is_public.eq.true,user_id.eq.{current_user['id']}")
        
        if filters.only_verified:
            query = query.eq("is_verified", True)
        
        if filters.min_rating > 0:
            query = query.gte("community_rating", filters.min_rating)
        
        if filters.category:  # muscle_group pour les exercices
            query = query.eq("muscle_group", filters.category)
        
        if filters.difficulty:
            query = query.eq("difficulty_level", filters.difficulty)
        
        if filters.search:
            query = query.or_(f"name_en.ilike.%{filters.search}%,name_fr.ilike.%{filters.search}%")
        
        if filters.tags:
            for tag in filters.tags:
                query = query.contains("tags", [tag])
        
        offset = (pagination.page - 1) * pagination.limit
        query = query.range(offset, offset + pagination.limit - 1)
        query = query.order("community_rating", desc=True)
        
        result = query.execute()
        
        # Count total
        count_query = supabase.table("exercises").select("id", count="exact")
        if filters.created_by_me:
            count_query = count_query.eq("user_id", current_user["id"])
        elif filters.only_public:
            count_query = count_query.eq("is_public", True)
        
        count_result = count_query.execute()
        total = count_result.count if hasattr(count_result, 'count') else len(result.data)
        
        return {
            "data": result.data,
            "pagination": {
                "page": pagination.page,
                "limit": pagination.limit,
                "total": total,
                "total_pages": (total + pagination.limit - 1) // pagination.limit
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération des exercices: {str(e)}")

@router.post("/exercises", response_model=Dict[str, Any])
async def create_custom_exercise(
    exercise: CustomExercise,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Crée un nouvel exercice personnalisé"""
    try:
        exercise_data = exercise.dict(exclude={'id'})
        exercise_data['user_id'] = current_user['id']
        exercise_data['is_custom'] = True
        
        result = supabase.table("exercises").insert(exercise_data).execute()
        
        # Créer une contribution communautaire
        contribution_data = {
            "contributor_id": current_user["id"],
            "content_type": "exercise",
            "content_id": result.data[0]["id"],
            "contribution_type": "created",
            "moderation_status": "approved" if not exercise.is_public else "pending"
        }
        supabase.table("community_contributions").insert(contribution_data).execute()
        
        return {
            "message": "Exercice créé avec succès",
            "exercise": result.data[0],
            "requires_moderation": exercise.is_public
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la création de l'exercice: {str(e)}")

@router.put("/exercises/{exercise_id}")
async def update_custom_exercise(
    exercise_id: UUID,
    exercise: CustomExercise,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Met à jour un exercice personnalisé"""
    try:
        existing = supabase.table("exercises").select("*").eq("id", exercise_id).execute()
        if not existing.data:
            raise HTTPException(status_code=404, detail="Exercice non trouvé")
        
        if existing.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Non autorisé à modifier cet exercice")
        
        exercise_data = exercise.dict(exclude={'id'})
        result = supabase.table("exercises").update(exercise_data).eq("id", exercise_id).execute()
        
        return {"message": "Exercice mis à jour avec succès", "exercise": result.data[0]}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la mise à jour: {str(e)}")

@router.delete("/exercises/{exercise_id}")
async def delete_custom_exercise(
    exercise_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Supprime un exercice personnalisé"""
    try:
        existing = supabase.table("exercises").select("*").eq("id", exercise_id).execute()
        if not existing.data:
            raise HTTPException(status_code=404, detail="Exercice non trouvé")
        
        if existing.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Non autorisé à supprimer cet exercice")
        
        supabase.table("exercises").delete().eq("id", exercise_id).execute()
        
        return {"message": "Exercice supprimé avec succès"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la suppression: {str(e)}")

# ==================== CUSTOM RECIPES API ====================

@router.get("/recipes", response_model=Dict[str, Any])
async def get_custom_recipes(
    filters: ContentFilters = Depends(),
    pagination: PaginationParams = Depends(),
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Récupère les recettes personnalisées avec filtres et pagination"""
    try:
        query = supabase.table("recipes").select("*")
        
        if filters.created_by_me:
            query = query.eq("user_id", current_user["id"])
        elif filters.only_public:
            query = query.eq("is_public", True)
        else:
            query = query.or_(f"is_public.eq.true,user_id.eq.{current_user['id']}")
        
        if filters.only_verified:
            query = query.eq("is_verified", True)
        
        if filters.min_rating > 0:
            query = query.gte("community_rating", filters.min_rating)
        
        if filters.difficulty:
            query = query.eq("difficulty", filters.difficulty)
        
        if filters.search:
            query = query.or_(f"name_en.ilike.%{filters.search}%,name_fr.ilike.%{filters.search}%")
        
        if filters.tags:
            for tag in filters.tags:
                query = query.contains("tags", [tag])
        
        offset = (pagination.page - 1) * pagination.limit
        query = query.range(offset, offset + pagination.limit - 1)
        query = query.order("community_rating", desc=True)
        
        result = query.execute()
        
        count_query = supabase.table("recipes").select("id", count="exact")
        if filters.created_by_me:
            count_query = count_query.eq("user_id", current_user["id"])
        elif filters.only_public:
            count_query = count_query.eq("is_public", True)
        
        count_result = count_query.execute()
        total = count_result.count if hasattr(count_result, 'count') else len(result.data)
        
        return {
            "data": result.data,
            "pagination": {
                "page": pagination.page,
                "limit": pagination.limit,
                "total": total,
                "total_pages": (total + pagination.limit - 1) // pagination.limit
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération des recettes: {str(e)}")

@router.post("/recipes", response_model=Dict[str, Any])
async def create_custom_recipe(
    recipe: CustomRecipe,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Crée une nouvelle recette personnalisée"""
    try:
        recipe_data = recipe.dict(exclude={'id'})
        recipe_data['user_id'] = current_user['id']
        recipe_data['is_custom'] = True
        
        result = supabase.table("recipes").insert(recipe_data).execute()
        
        # Créer une contribution communautaire
        contribution_data = {
            "contributor_id": current_user["id"],
            "content_type": "recipe",
            "content_id": result.data[0]["id"],
            "contribution_type": "created",
            "moderation_status": "approved" if not recipe.is_public else "pending"
        }
        supabase.table("community_contributions").insert(contribution_data).execute()
        
        return {
            "message": "Recette créée avec succès",
            "recipe": result.data[0],
            "requires_moderation": recipe.is_public
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la création de la recette: {str(e)}")

@router.put("/recipes/{recipe_id}")
async def update_custom_recipe(
    recipe_id: UUID,
    recipe: CustomRecipe,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Met à jour une recette personnalisée"""
    try:
        existing = supabase.table("recipes").select("*").eq("id", recipe_id).execute()
        if not existing.data:
            raise HTTPException(status_code=404, detail="Recette non trouvée")
        
        if existing.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Non autorisé à modifier cette recette")
        
        recipe_data = recipe.dict(exclude={'id'})
        result = supabase.table("recipes").update(recipe_data).eq("id", recipe_id).execute()
        
        return {"message": "Recette mise à jour avec succès", "recipe": result.data[0]}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la mise à jour: {str(e)}")

@router.delete("/recipes/{recipe_id}")
async def delete_custom_recipe(
    recipe_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Supprime une recette personnalisée"""
    try:
        existing = supabase.table("recipes").select("*").eq("id", recipe_id).execute()
        if not existing.data:
            raise HTTPException(status_code=404, detail="Recette non trouvée")
        
        if existing.data[0]["user_id"] != current_user["id"]:
            raise HTTPException(status_code=403, detail="Non autorisé à supprimer cette recette")
        
        supabase.table("recipes").delete().eq("id", recipe_id).execute()
        
        return {"message": "Recette supprimée avec succès"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la suppression: {str(e)}")

# ==================== COLLECTIONS API ====================

@router.get("/collections", response_model=List[UserCollection])
async def get_user_collections(
    collection_type: Optional[str] = Query(None, regex="^(foods|exercises|recipes|workouts)$"),
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Récupère les collections de l'utilisateur"""
    try:
        query = supabase.table("user_collections").select("*").eq("user_id", current_user["id"])
        
        if collection_type:
            query = query.eq("collection_type", collection_type)
        
        result = query.execute()
        return result.data
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération des collections: {str(e)}")

@router.post("/collections", response_model=Dict[str, Any])
async def create_collection(
    collection: UserCollection,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Crée une nouvelle collection"""
    try:
        collection_data = collection.dict(exclude={'id'})
        collection_data['user_id'] = current_user['id']
        
        result = supabase.table("user_collections").insert(collection_data).execute()
        
        return {"message": "Collection créée avec succès", "collection": result.data[0]}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la création de la collection: {str(e)}")

@router.put("/collections/{collection_id}/items/{item_id}")
async def add_item_to_collection(
    collection_id: UUID,
    item_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Ajoute un élément à une collection"""
    try:
        # Récupérer la collection
        collection_result = supabase.table("user_collections").select("*").eq("id", collection_id).eq("user_id", current_user["id"]).execute()
        
        if not collection_result.data:
            raise HTTPException(status_code=404, detail="Collection non trouvée")
        
        collection = collection_result.data[0]
        item_ids = collection.get("item_ids", [])
        
        if str(item_id) not in [str(id) for id in item_ids]:
            item_ids.append(str(item_id))
            
            supabase.table("user_collections").update({"item_ids": item_ids}).eq("id", collection_id).execute()
        
        return {"message": "Élément ajouté à la collection avec succès"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'ajout à la collection: {str(e)}")

@router.delete("/collections/{collection_id}/items/{item_id}")
async def remove_item_from_collection(
    collection_id: UUID,
    item_id: UUID,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Retire un élément d'une collection"""
    try:
        collection_result = supabase.table("user_collections").select("*").eq("id", collection_id).eq("user_id", current_user["id"]).execute()
        
        if not collection_result.data:
            raise HTTPException(status_code=404, detail="Collection non trouvée")
        
        collection = collection_result.data[0]
        item_ids = collection.get("item_ids", [])
        
        item_ids = [id for id in item_ids if str(id) != str(item_id)]
        
        supabase.table("user_collections").update({"item_ids": item_ids}).eq("id", collection_id).execute()
        
        return {"message": "Élément retiré de la collection avec succès"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors du retrait de la collection: {str(e)}")

# ==================== COMMUNITY RATINGS API ====================

@router.post("/ratings", response_model=Dict[str, Any])
async def create_rating(
    rating: CommunityRating,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Crée ou met à jour une note communautaire"""
    try:
        rating_data = rating.dict(exclude={'id'})
        rating_data['user_id'] = current_user['id']
        
        # Vérifier si un rating existe déjà
        existing = supabase.table("community_ratings").select("*").eq("user_id", current_user["id"]).eq("content_type", rating.content_type).eq("content_id", rating.content_id).execute()
        
        if existing.data:
            # Mettre à jour le rating existant
            result = supabase.table("community_ratings").update(rating_data).eq("id", existing.data[0]["id"]).execute()
            message = "Note mise à jour avec succès"
        else:
            # Créer un nouveau rating
            result = supabase.table("community_ratings").insert(rating_data).execute()
            message = "Note ajoutée avec succès"
        
        return {"message": message, "rating": result.data[0]}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'ajout de la note: {str(e)}")

@router.get("/ratings/{content_type}/{content_id}")
async def get_content_ratings(
    content_type: str,
    content_id: UUID,
    supabase = Depends(get_supabase_client)
):
    """Récupère les notes d'un contenu"""
    try:
        result = supabase.table("community_ratings").select("*").eq("content_type", content_type).eq("content_id", content_id).order("created_at", desc=True).execute()
        
        # Statistiques des ratings
        ratings = [r["rating"] for r in result.data]
        stats = {
            "average": sum(ratings) / len(ratings) if ratings else 0,
            "count": len(ratings),
            "distribution": {str(i): ratings.count(i) for i in range(1, 6)}
        }
        
        return {"ratings": result.data, "statistics": stats}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération des notes: {str(e)}")

# ==================== CONTENT REPORTS API ====================

@router.post("/reports", response_model=Dict[str, Any])
async def create_report(
    report: ContentReport,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Signale un contenu inapproprié"""
    try:
        report_data = report.dict()
        report_data['reported_by'] = current_user['id']
        
        result = supabase.table("content_reports").insert(report_data).execute()
        
        return {"message": "Signalement envoyé avec succès", "report": result.data[0]}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors du signalement: {str(e)}")

# ==================== TAGS API ====================

@router.get("/tags", response_model=List[ContentTag])
async def get_content_tags(
    category: Optional[str] = Query(None, regex="^(food|exercise|recipe|workout)$"),
    supabase = Depends(get_supabase_client)
):
    """Récupère les tags disponibles"""
    try:
        query = supabase.table("content_tags").select("*")
        
        if category:
            query = query.eq("category", category)
        
        result = query.order("usage_count", desc=True).execute()
        return result.data
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération des tags: {str(e)}")

@router.post("/tags", response_model=Dict[str, Any])
async def create_tag(
    tag: ContentTag,
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Suggère un nouveau tag"""
    try:
        tag_data = tag.dict(exclude={'id', 'usage_count'})
        
        # Vérifier si le tag existe déjà
        existing = supabase.table("content_tags").select("*").eq("name", tag.name).execute()
        
        if existing.data:
            raise HTTPException(status_code=400, detail="Ce tag existe déjà")
        
        result = supabase.table("content_tags").insert(tag_data).execute()
        
        return {"message": "Tag suggéré avec succès", "tag": result.data[0]}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la création du tag: {str(e)}")

# ==================== SIMILAR CONTENT API ====================

@router.get("/similar/{content_type}/{content_id}")
async def get_similar_content(
    content_type: str,
    content_id: UUID,
    limit: int = Query(default=5, ge=1, le=20),
    supabase = Depends(get_supabase_client)
):
    """Récupère du contenu similaire basé sur les tags et catégories"""
    try:
        # Utiliser la fonction PostgreSQL créée dans la migration
        result = supabase.rpc("get_similar_content", {
            "content_type": content_type,
            "content_id": str(content_id),
            "limit_count": limit
        }).execute()
        
        return {"similar_content": result.data}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération du contenu similaire: {str(e)}")

# ==================== COMMUNITY STATS API ====================

@router.get("/community/stats")
async def get_community_stats(
    supabase = Depends(get_supabase_client)
):
    """Récupère les statistiques de la communauté"""
    try:
        result = supabase.rpc("get_community_stats").execute()
        
        if result.data:
            stats = result.data[0]
            return {
                "community_statistics": {
                    "total_custom_foods": stats.get("total_custom_foods", 0),
                    "total_custom_exercises": stats.get("total_custom_exercises", 0),
                    "total_custom_recipes": stats.get("total_custom_recipes", 0),
                    "total_public_content": stats.get("total_public_content", 0),
                    "total_ratings": stats.get("total_ratings", 0),
                    "average_rating": float(stats.get("average_rating", 0.0)),
                    "top_contributors": stats.get("top_contributors", [])
                }
            }
        
        return {"community_statistics": {"message": "Aucune donnée disponible"}}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de la récupération des statistiques: {str(e)}")

# ==================== BULK IMPORT API ====================

@router.post("/import/foods")
async def bulk_import_foods(
    foods: List[CustomFood],
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Importe plusieurs aliments en une fois"""
    try:
        foods_data = []
        for food in foods:
            food_data = food.dict(exclude={'id'})
            food_data['user_id'] = current_user['id']
            food_data['is_custom'] = True
            foods_data.append(food_data)
        
        result = supabase.table("foods").insert(foods_data).execute()
        
        return {
            "message": f"{len(result.data)} aliments importés avec succès",
            "imported_count": len(result.data)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'import en masse: {str(e)}")

@router.post("/import/exercises")
async def bulk_import_exercises(
    exercises: List[CustomExercise],
    current_user: dict = Depends(get_current_user),
    supabase = Depends(get_supabase_client)
):
    """Importe plusieurs exercices en une fois"""
    try:
        exercises_data = []
        for exercise in exercises:
            exercise_data = exercise.dict(exclude={'id'})
            exercise_data['user_id'] = current_user['id']
            exercise_data['is_custom'] = True
            exercises_data.append(exercise_data)
        
        result = supabase.table("exercises").insert(exercises_data).execute()
        
        return {
            "message": f"{len(result.data)} exercices importés avec succès",
            "imported_count": len(result.data)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur lors de l'import en masse: {str(e)}")