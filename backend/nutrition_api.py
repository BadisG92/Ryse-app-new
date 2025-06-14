"""
Nutrition Module APIs for Ryze App
Handles food journal management, searches, and nutritional calculations
"""

from fastapi import APIRouter, HTTPException, Depends, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import date, datetime
from decimal import Decimal
from uuid import UUID
import logging

from .database import get_supabase_client
from .auth import get_current_user

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create router
nutrition_router = APIRouter(prefix="/api/nutrition", tags=["nutrition"])

# Pydantic models
class FoodSearchRequest(BaseModel):
    query: str = Field("", description="Search query for food name")
    language: str = Field("en", description="Language code (en/fr)")
    category: Optional[str] = Field(None, description="Filter by food category")
    min_calories: Optional[int] = Field(None, description="Minimum calories filter")
    max_calories: Optional[int] = Field(None, description="Maximum calories filter")
    min_proteins: Optional[float] = Field(None, description="Minimum proteins filter")
    max_proteins: Optional[float] = Field(None, description="Maximum proteins filter")
    limit: int = Field(50, description="Maximum number of results")

class FoodSearchResult(BaseModel):
    id: UUID
    name: str
    calories: int
    proteins: float
    carbs: float
    fats: float
    category: Optional[str]
    is_custom: bool
    user_id: Optional[UUID]
    relevance_score: float

class AddFoodToJournalRequest(BaseModel):
    food_id: UUID
    quantity: float = Field(..., gt=0, description="Quantity in specified unit")
    unit: str = Field("g", description="Unit of measurement")
    meal_type: str = Field("other", description="Type of meal (breakfast, lunch, dinner, snack, other)")
    consumed_at: Optional[datetime] = Field(None, description="When the food was consumed")

class MealEntry(BaseModel):
    meal_id: UUID
    total_calories: float
    total_proteins: float
    total_carbs: float
    total_fats: float

class UpdateMealRequest(BaseModel):
    quantity: Optional[float] = Field(None, gt=0)
    unit: Optional[str] = None
    meal_type: Optional[str] = None

class DailyNutritionSummary(BaseModel):
    summary_date: date
    total_meals: int
    total_calories: float
    total_proteins: float
    total_carbs: float
    total_fats: float
    meals_by_type: Dict[str, int]
    hourly_distribution: Dict[str, float]

class NutritionHistoryEntry(BaseModel):
    date: date
    total_calories: float
    total_proteins: float
    total_carbs: float
    total_fats: float
    meal_count: int
    avg_calories_per_meal: float

class FoodSuggestion(BaseModel):
    id: UUID
    name: str
    calories: int
    proteins: float
    carbs: float
    fats: float
    category: Optional[str]
    frequency_score: int
    last_consumed: datetime

class MealDetails(BaseModel):
    meal_id: UUID
    food_id: UUID
    food_name: str
    quantity: float
    unit: str
    meal_type: str
    consumed_at: datetime
    calories: float
    proteins: float
    carbs: float
    fats: float
    food_category: Optional[str]
    is_custom_food: bool

class DailyMeal(BaseModel):
    meal_id: UUID
    food_id: UUID
    food_name: str
    quantity: float
    unit: str
    meal_type: str
    consumed_at: datetime
    calories: float
    proteins: float
    carbs: float
    fats: float
    food_category: Optional[str]

# API Endpoints

@nutrition_router.post("/foods/search", response_model=List[FoodSearchResult])
async def search_foods(
    search_request: FoodSearchRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Search for foods with advanced filtering options
    """
    try:
        supabase = get_supabase_client()
        
        # Call the search function
        result = supabase.rpc('search_foods_advanced', {
            'search_query': search_request.query,
            'language_code': search_request.language,
            'category_filter': search_request.category,
            'min_calories': search_request.min_calories,
            'max_calories': search_request.max_calories,
            'min_proteins': search_request.min_proteins,
            'max_proteins': search_request.max_proteins,
            'user_id_param': current_user['id'],
            'limit_count': search_request.limit
        }).execute()
        
        if result.data:
            return [FoodSearchResult(**item) for item in result.data]
        return []
        
    except Exception as e:
        logger.error(f"Error searching foods: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error searching foods: {str(e)}")

@nutrition_router.get("/foods/suggestions", response_model=List[FoodSuggestion])
async def get_food_suggestions(
    language: str = Query("en", description="Language code"),
    limit: int = Query(10, description="Number of suggestions"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get food suggestions based on user's consumption history
    """
    try:
        supabase = get_supabase_client()
        
        result = supabase.rpc('get_food_suggestions', {
            'user_id_param': current_user['id'],
            'language_code': language,
            'limit_count': limit
        }).execute()
        
        if result.data:
            return [FoodSuggestion(**item) for item in result.data]
        return []
        
    except Exception as e:
        logger.error(f"Error getting food suggestions: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting food suggestions: {str(e)}")

@nutrition_router.post("/journal/add", response_model=MealEntry)
async def add_food_to_journal(
    add_request: AddFoodToJournalRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Add a food item to the user's food journal
    """
    try:
        supabase = get_supabase_client()
        
        consumed_at = add_request.consumed_at or datetime.now()
        
        result = supabase.rpc('add_food_to_journal', {
            'user_id_param': current_user['id'],
            'food_id_param': str(add_request.food_id),
            'quantity_param': add_request.quantity,
            'unit_param': add_request.unit,
            'meal_type_param': add_request.meal_type,
            'consumed_at_param': consumed_at.isoformat()
        }).execute()
        
        if result.data and len(result.data) > 0:
            return MealEntry(**result.data[0])
        else:
            raise HTTPException(status_code=400, detail="Failed to add food to journal")
            
    except Exception as e:
        logger.error(f"Error adding food to journal: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error adding food to journal: {str(e)}")

@nutrition_router.get("/journal/daily", response_model=List[DailyMeal])
async def get_daily_meals(
    date_param: date = Query(None, description="Date to get meals for (default: today)"),
    language: str = Query("en", description="Language code"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get all meals for a specific day
    """
    try:
        supabase = get_supabase_client()
        
        target_date = date_param or date.today()
        
        result = supabase.rpc('get_daily_meals', {
            'user_id_param': current_user['id'],
            'date_param': target_date.isoformat(),
            'language_code': language
        }).execute()
        
        if result.data:
            return [DailyMeal(**item) for item in result.data]
        return []
        
    except Exception as e:
        logger.error(f"Error getting daily meals: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting daily meals: {str(e)}")

@nutrition_router.get("/journal/summary", response_model=DailyNutritionSummary)
async def get_daily_nutrition_summary(
    date_param: date = Query(None, description="Date to get summary for (default: today)"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get nutritional summary for a specific day
    """
    try:
        supabase = get_supabase_client()
        
        target_date = date_param or date.today()
        
        result = supabase.rpc('get_daily_nutrition_summary', {
            'user_id_param': current_user['id'],
            'date_param': target_date.isoformat()
        }).execute()
        
        if result.data and len(result.data) > 0:
            return DailyNutritionSummary(**result.data[0])
        else:
            # Return empty summary if no data
            return DailyNutritionSummary(
                summary_date=target_date,
                total_meals=0,
                total_calories=0.0,
                total_proteins=0.0,
                total_carbs=0.0,
                total_fats=0.0,
                meals_by_type={},
                hourly_distribution={}
            )
            
    except Exception as e:
        logger.error(f"Error getting daily nutrition summary: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting daily nutrition summary: {str(e)}")

@nutrition_router.get("/journal/history", response_model=List[NutritionHistoryEntry])
async def get_nutrition_history(
    start_date: date = Query(None, description="Start date for history"),
    end_date: date = Query(None, description="End date for history"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get nutrition history over a date range
    """
    try:
        supabase = get_supabase_client()
        
        # Default to last 7 days if no dates provided
        end_date = end_date or date.today()
        start_date = start_date or date.today().replace(day=date.today().day - 7)
        
        result = supabase.rpc('get_nutrition_history', {
            'user_id_param': current_user['id'],
            'start_date': start_date.isoformat(),
            'end_date': end_date.isoformat()
        }).execute()
        
        if result.data:
            return [NutritionHistoryEntry(**item) for item in result.data]
        return []
        
    except Exception as e:
        logger.error(f"Error getting nutrition history: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting nutrition history: {str(e)}")

@nutrition_router.get("/journal/meal/{meal_id}", response_model=MealDetails)
async def get_meal_details(
    meal_id: UUID,
    language: str = Query("en", description="Language code"),
    current_user: dict = Depends(get_current_user)
):
    """
    Get detailed information about a specific meal entry
    """
    try:
        supabase = get_supabase_client()
        
        result = supabase.rpc('get_meal_details', {
            'meal_id_param': str(meal_id),
            'user_id_param': current_user['id'],
            'language_code': language
        }).execute()
        
        if result.data and len(result.data) > 0:
            return MealDetails(**result.data[0])
        else:
            raise HTTPException(status_code=404, detail="Meal not found")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting meal details: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting meal details: {str(e)}")

@nutrition_router.put("/journal/meal/{meal_id}", response_model=MealEntry)
async def update_meal_entry(
    meal_id: UUID,
    update_request: UpdateMealRequest,
    current_user: dict = Depends(get_current_user)
):
    """
    Update a meal entry in the food journal
    """
    try:
        supabase = get_supabase_client()
        
        result = supabase.rpc('update_meal_entry', {
            'meal_id_param': str(meal_id),
            'user_id_param': current_user['id'],
            'new_quantity': update_request.quantity,
            'new_unit': update_request.unit,
            'new_meal_type': update_request.meal_type
        }).execute()
        
        if result.data and len(result.data) > 0:
            return MealEntry(**result.data[0])
        else:
            raise HTTPException(status_code=404, detail="Meal not found or update failed")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating meal entry: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error updating meal entry: {str(e)}")

@nutrition_router.delete("/journal/meal/{meal_id}")
async def delete_meal_entry(
    meal_id: UUID,
    current_user: dict = Depends(get_current_user)
):
    """
    Delete a meal entry from the food journal
    """
    try:
        supabase = get_supabase_client()
        
        result = supabase.rpc('delete_meal_entry', {
            'meal_id_param': str(meal_id),
            'user_id_param': current_user['id']
        }).execute()
        
        if result.data and result.data[0]:
            return {"message": "Meal entry deleted successfully"}
        else:
            raise HTTPException(status_code=404, detail="Meal not found")
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting meal entry: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error deleting meal entry: {str(e)}")

# Barcode scanning endpoint (placeholder for external service integration)
@nutrition_router.post("/barcode/scan")
async def scan_barcode(
    barcode: str = Query(..., description="Barcode to scan"),
    language: str = Query("en", description="Language for product info"),
    current_user: dict = Depends(get_current_user)
):
    """
    Scan a barcode and return food information
    This is a placeholder for integration with external barcode APIs like OpenFoodFacts
    """
    try:
        # TODO: Integrate with external barcode scanning service
        # For now, return a placeholder response
        
        # Example integration with OpenFoodFacts API would go here
        # import requests
        # response = requests.get(f"https://world.openfoodfacts.org/api/v0/product/{barcode}.json")
        
        return {
            "message": "Barcode scanning not yet implemented",
            "barcode": barcode,
            "suggestion": "Please search for the food manually or add it as a custom food item"
        }
        
    except Exception as e:
        logger.error(f"Error scanning barcode: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error scanning barcode: {str(e)}")

# Nutritional goals and recommendations
@nutrition_router.get("/goals/recommendations")
async def get_nutritional_recommendations(
    current_user: dict = Depends(get_current_user)
):
    """
    Get personalized nutritional recommendations based on user profile and goals
    """
    try:
        # TODO: Implement personalized recommendations based on:
        # - User profile (age, weight, height, activity level)
        # - Fitness goals (weight loss, muscle gain, maintenance)
        # - Current nutrition patterns
        
        # Placeholder recommendations
        return {
            "daily_calories": 2000,
            "daily_proteins": 150,
            "daily_carbs": 250,
            "daily_fats": 67,
            "recommendations": [
                "Increase protein intake for muscle building",
                "Add more vegetables for micronutrients",
                "Consider timing carbs around workouts"
            ]
        }
        
    except Exception as e:
        logger.error(f"Error getting nutritional recommendations: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error getting recommendations: {str(e)}")

# Export nutrition data
@nutrition_router.get("/export")
async def export_nutrition_data(
    start_date: date = Query(None, description="Start date for export"),
    end_date: date = Query(None, description="End date for export"),
    format: str = Query("json", description="Export format (json, csv)"),
    current_user: dict = Depends(get_current_user)
):
    """
    Export user's nutrition data for a specified date range
    """
    try:
        # Get nutrition history for the specified period
        supabase = get_supabase_client()
        
        end_date = end_date or date.today()
        start_date = start_date or date.today().replace(day=date.today().day - 30)
        
        result = supabase.rpc('get_nutrition_history', {
            'user_id_param': current_user['id'],
            'start_date': start_date.isoformat(),
            'end_date': end_date.isoformat()
        }).execute()
        
        if format.lower() == "csv":
            # TODO: Convert to CSV format
            return {"message": "CSV export not yet implemented", "data": result.data}
        else:
            return {
                "export_date": datetime.now().isoformat(),
                "period": f"{start_date} to {end_date}",
                "data": result.data or []
            }
            
    except Exception as e:
        logger.error(f"Error exporting nutrition data: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error exporting data: {str(e)}") 