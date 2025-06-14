from fastapi import APIRouter, HTTPException, Depends, status, Query
from typing import List, Optional
from datetime import date
from models import Food, FoodCreate, Meal, MealCreate, MealFoodItem, MealFoodItemCreate, MessageResponse
from database import get_supabase_client, get_current_user
from supabase import Client

router = APIRouter()

# Foods
@router.get("/foods", response_model=List[Food])
async def get_foods(
    search: Optional[str] = Query(None, description="Search foods by name"),
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(50, ge=1, le=100, description="Items per page"),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get all foods with optional search"""
    try:
        query = supabase.table("foods").select("*")
        
        if search:
            query = query.ilike("name", f"%{search}%")
        
        offset = (page - 1) * per_page
        response = query.order("name").range(offset, offset + per_page - 1).execute()
        
        foods = [Food(**food) for food in response.data]
        return foods
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get foods: {str(e)}"
        )

@router.get("/foods/{food_id}", response_model=Food)
async def get_food(
    food_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get a specific food by ID"""
    try:
        response = supabase.table("foods").select("*").eq("id", food_id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Food not found"
            )
        
        return Food(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get food: {str(e)}"
        )

@router.post("/foods", response_model=Food)
async def create_custom_food(
    food_data: FoodCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Create a custom food"""
    try:
        food_dict = food_data.dict()
        food_dict["created_by"] = current_user.id
        food_dict["is_custom"] = True
        
        response = supabase.table("foods").insert(food_dict).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create food"
            )
        
        return Food(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create food: {str(e)}"
        )

# Meals
@router.get("/meals", response_model=List[Meal])
async def get_user_meals(
    meal_date: Optional[date] = Query(None, description="Filter by date"),
    meal_time: Optional[str] = Query(None, description="Filter by meal time"),
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get user's meals"""
    try:
        query = supabase.table("meals").select("*").eq("user_id", current_user.id)
        
        if meal_date:
            query = query.eq("date", meal_date.isoformat())
        if meal_time:
            query = query.eq("meal_time", meal_time)
        
        offset = (page - 1) * per_page
        response = query.order("date", desc=True).order("meal_time").range(offset, offset + per_page - 1).execute()
        
        meals = [Meal(**meal) for meal in response.data]
        return meals
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get meals: {str(e)}"
        )

@router.get("/meals/{meal_id}", response_model=Meal)
async def get_meal(
    meal_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get a specific meal with food items"""
    try:
        response = supabase.table("meals").select("*").eq("id", meal_id).eq("user_id", current_user.id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal not found or not owned by user"
            )
        
        return Meal(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get meal: {str(e)}"
        )

@router.post("/meals", response_model=Meal)
async def create_meal(
    meal_data: MealCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Create a new meal"""
    try:
        meal_dict = meal_data.dict()
        meal_dict["user_id"] = current_user.id
        
        response = supabase.table("meals").insert(meal_dict).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create meal"
            )
        
        return Meal(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to create meal: {str(e)}"
        )

# Meal Food Items
@router.get("/meals/{meal_id}/items", response_model=List[MealFoodItem])
async def get_meal_food_items(
    meal_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get food items for a specific meal"""
    try:
        # Verify meal ownership
        meal_response = supabase.table("meals").select("id").eq("id", meal_id).eq("user_id", current_user.id).execute()
        
        if not meal_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal not found or not owned by user"
            )
        
        # Get meal food items with food details
        response = supabase.table("meal_food_items").select("""
            *,
            food:foods(*)
        """).eq("meal_id", meal_id).execute()
        
        items = [MealFoodItem(**item) for item in response.data]
        return items
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get meal food items: {str(e)}"
        )

@router.post("/meals/{meal_id}/items", response_model=MealFoodItem)
async def add_food_to_meal(
    meal_id: str,
    food_item_data: MealFoodItemCreate,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Add a food item to a meal"""
    try:
        # Verify meal ownership
        meal_response = supabase.table("meals").select("id").eq("id", meal_id).eq("user_id", current_user.id).execute()
        
        if not meal_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal not found or not owned by user"
            )
        
        # Add food item to meal
        item_dict = food_item_data.dict()
        item_dict["meal_id"] = meal_id
        
        response = supabase.table("meal_food_items").insert(item_dict).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to add food item to meal"
            )
        
        return MealFoodItem(**response.data[0])
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to add food item to meal: {str(e)}"
        )

@router.delete("/meals/{meal_id}/items/{item_id}", response_model=MessageResponse)
async def remove_food_from_meal(
    meal_id: str,
    item_id: str,
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Remove a food item from a meal"""
    try:
        # Verify meal ownership
        meal_response = supabase.table("meals").select("id").eq("id", meal_id).eq("user_id", current_user.id).execute()
        
        if not meal_response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Meal not found or not owned by user"
            )
        
        # Remove food item
        response = supabase.table("meal_food_items").delete().eq("id", item_id).eq("meal_id", meal_id).execute()
        
        if not response.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Food item not found in meal"
            )
        
        return MessageResponse(message="Food item removed from meal successfully")
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to remove food item from meal: {str(e)}"
        )

@router.get("/daily-summary", response_model=dict)
async def get_daily_nutrition_summary(
    summary_date: date = Query(..., description="Date for nutrition summary"),
    current_user = Depends(get_current_user),
    supabase: Client = Depends(get_supabase_client)
):
    """Get daily nutrition summary"""
    try:
        # Get all meals for the day with food items
        meals_response = supabase.table("meals").select("""
            *,
            items:meal_food_items(
                *,
                food:foods(*)
            )
        """).eq("user_id", current_user.id).eq("date", summary_date.isoformat()).execute()
        
        total_calories = 0
        total_protein = 0
        total_carbs = 0
        total_fat = 0
        
        for meal in meals_response.data:
            if meal.get("items"):
                for item in meal["items"]:
                    if item.get("food"):
                        food = item["food"]
                        # Calculate based on portion (assuming portion is in grams)
                        portion_multiplier = float(item.get("portion", "100").replace("g", "")) / 100
                        
                        total_calories += food["calories_per_100g"] * portion_multiplier
                        total_protein += food["protein_per_100g"] * portion_multiplier
                        total_carbs += food["carbs_per_100g"] * portion_multiplier
                        total_fat += food["fat_per_100g"] * portion_multiplier
        
        return {
            "date": summary_date.isoformat(),
            "total_calories": round(total_calories),
            "total_protein": round(total_protein, 1),
            "total_carbs": round(total_carbs, 1),
            "total_fat": round(total_fat, 1),
            "meals_count": len(meals_response.data)
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get daily nutrition summary: {str(e)}"
        ) 