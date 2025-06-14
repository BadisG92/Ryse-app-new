"""
Test script for Nutrition Module APIs
Tests all endpoints with sample data
"""

import asyncio
import json
import requests
from datetime import date, datetime
from uuid import uuid4
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# API Configuration
BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api/nutrition"

# Test user token (you'll need to replace this with a real token)
TEST_TOKEN = "your-test-jwt-token-here"
HEADERS = {
    "Authorization": f"Bearer {TEST_TOKEN}",
    "Content-Type": "application/json"
}

class NutritionAPITester:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update(HEADERS)
        
    def test_food_search(self):
        """Test food search functionality"""
        logger.info("Testing food search...")
        
        # Test basic search
        search_data = {
            "query": "pomme",
            "language": "fr",
            "limit": 10
        }
        
        response = self.session.post(f"{API_BASE}/foods/search", json=search_data)
        logger.info(f"Food search response: {response.status_code}")
        
        if response.status_code == 200:
            results = response.json()
            logger.info(f"Found {len(results)} foods")
            if results:
                logger.info(f"First result: {results[0]['name']} - {results[0]['calories']} cal")
        else:
            logger.error(f"Food search failed: {response.text}")
            
        return response.status_code == 200
    
    def test_food_search_with_filters(self):
        """Test food search with nutritional filters"""
        logger.info("Testing food search with filters...")
        
        search_data = {
            "query": "",
            "language": "en",
            "category": "Fruits",
            "min_calories": 40,
            "max_calories": 100,
            "limit": 5
        }
        
        response = self.session.post(f"{API_BASE}/foods/search", json=search_data)
        logger.info(f"Filtered search response: {response.status_code}")
        
        if response.status_code == 200:
            results = response.json()
            logger.info(f"Found {len(results)} filtered foods")
            for food in results:
                logger.info(f"- {food['name']}: {food['calories']} cal, category: {food['category']}")
        
        return response.status_code == 200
    
    def test_add_food_to_journal(self):
        """Test adding food to journal"""
        logger.info("Testing add food to journal...")
        
        # First, search for a food to add
        search_data = {"query": "apple", "language": "en", "limit": 1}
        search_response = self.session.post(f"{API_BASE}/foods/search", json=search_data)
        
        if search_response.status_code != 200 or not search_response.json():
            logger.error("No foods found for journal test")
            return False
            
        food = search_response.json()[0]
        
        # Add to journal
        journal_data = {
            "food_id": food["id"],
            "quantity": 150.0,
            "unit": "g",
            "meal_type": "breakfast",
            "consumed_at": datetime.now().isoformat()
        }
        
        response = self.session.post(f"{API_BASE}/journal/add", json=journal_data)
        logger.info(f"Add to journal response: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            logger.info(f"Added meal: {result['total_calories']} calories")
            return result["meal_id"]
        else:
            logger.error(f"Add to journal failed: {response.text}")
            return None
    
    def test_daily_meals(self):
        """Test getting daily meals"""
        logger.info("Testing get daily meals...")
        
        today = date.today().isoformat()
        response = self.session.get(f"{API_BASE}/journal/daily?date_param={today}&language=fr")
        
        logger.info(f"Daily meals response: {response.status_code}")
        
        if response.status_code == 200:
            meals = response.json()
            logger.info(f"Found {len(meals)} meals for today")
            for meal in meals:
                logger.info(f"- {meal['food_name']}: {meal['quantity']}{meal['unit']} ({meal['calories']} cal)")
        
        return response.status_code == 200
    
    def test_daily_summary(self):
        """Test getting daily nutrition summary"""
        logger.info("Testing daily nutrition summary...")
        
        today = date.today().isoformat()
        response = self.session.get(f"{API_BASE}/journal/summary?date_param={today}")
        
        logger.info(f"Daily summary response: {response.status_code}")
        
        if response.status_code == 200:
            summary = response.json()
            logger.info(f"Daily summary: {summary['total_calories']} cal, {summary['total_meals']} meals")
            logger.info(f"Macros: P:{summary['total_proteins']}g C:{summary['total_carbs']}g F:{summary['total_fats']}g")
            if summary['meals_by_type']:
                logger.info(f"Meals by type: {summary['meals_by_type']}")
        
        return response.status_code == 200
    
    def test_nutrition_history(self):
        """Test getting nutrition history"""
        logger.info("Testing nutrition history...")
        
        response = self.session.get(f"{API_BASE}/journal/history")
        
        logger.info(f"Nutrition history response: {response.status_code}")
        
        if response.status_code == 200:
            history = response.json()
            logger.info(f"Found {len(history)} days of history")
            for day in history[:3]:  # Show first 3 days
                logger.info(f"- {day['date']}: {day['total_calories']} cal, {day['meal_count']} meals")
        
        return response.status_code == 200
    
    def test_food_suggestions(self):
        """Test getting food suggestions"""
        logger.info("Testing food suggestions...")
        
        response = self.session.get(f"{API_BASE}/foods/suggestions?language=fr&limit=5")
        
        logger.info(f"Food suggestions response: {response.status_code}")
        
        if response.status_code == 200:
            suggestions = response.json()
            logger.info(f"Found {len(suggestions)} suggestions")
            for suggestion in suggestions:
                logger.info(f"- {suggestion['name']}: used {suggestion['frequency_score']} times")
        
        return response.status_code == 200
    
    def test_meal_details(self, meal_id):
        """Test getting meal details"""
        if not meal_id:
            logger.info("Skipping meal details test (no meal ID)")
            return True
            
        logger.info(f"Testing meal details for ID: {meal_id}")
        
        response = self.session.get(f"{API_BASE}/journal/meal/{meal_id}?language=fr")
        
        logger.info(f"Meal details response: {response.status_code}")
        
        if response.status_code == 200:
            details = response.json()
            logger.info(f"Meal details: {details['food_name']} - {details['quantity']}{details['unit']}")
            logger.info(f"Consumed at: {details['consumed_at']}")
        
        return response.status_code == 200
    
    def test_update_meal(self, meal_id):
        """Test updating a meal entry"""
        if not meal_id:
            logger.info("Skipping meal update test (no meal ID)")
            return True
            
        logger.info(f"Testing meal update for ID: {meal_id}")
        
        update_data = {
            "quantity": 200.0,
            "meal_type": "lunch"
        }
        
        response = self.session.put(f"{API_BASE}/journal/meal/{meal_id}", json=update_data)
        
        logger.info(f"Meal update response: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            logger.info(f"Updated meal: {result['total_calories']} calories")
        
        return response.status_code == 200
    
    def test_barcode_scan(self):
        """Test barcode scanning (placeholder)"""
        logger.info("Testing barcode scan...")
        
        response = self.session.post(f"{API_BASE}/barcode/scan?barcode=1234567890123&language=fr")
        
        logger.info(f"Barcode scan response: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            logger.info(f"Barcode result: {result['message']}")
        
        return response.status_code == 200
    
    def test_nutritional_recommendations(self):
        """Test getting nutritional recommendations"""
        logger.info("Testing nutritional recommendations...")
        
        response = self.session.get(f"{API_BASE}/goals/recommendations")
        
        logger.info(f"Recommendations response: {response.status_code}")
        
        if response.status_code == 200:
            recommendations = response.json()
            logger.info(f"Daily calories recommendation: {recommendations['daily_calories']}")
            logger.info(f"Recommendations: {recommendations['recommendations']}")
        
        return response.status_code == 200
    
    def test_export_data(self):
        """Test exporting nutrition data"""
        logger.info("Testing data export...")
        
        response = self.session.get(f"{API_BASE}/export?format=json")
        
        logger.info(f"Export response: {response.status_code}")
        
        if response.status_code == 200:
            export_data = response.json()
            logger.info(f"Export period: {export_data['period']}")
            logger.info(f"Data entries: {len(export_data['data'])}")
        
        return response.status_code == 200
    
    def run_all_tests(self):
        """Run all nutrition API tests"""
        logger.info("Starting Nutrition API Tests...")
        logger.info("=" * 50)
        
        results = {}
        meal_id = None
        
        # Test search functionality
        results["food_search"] = self.test_food_search()
        results["food_search_filtered"] = self.test_food_search_with_filters()
        
        # Test journal functionality
        meal_id = self.test_add_food_to_journal()
        results["add_to_journal"] = meal_id is not None
        
        results["daily_meals"] = self.test_daily_meals()
        results["daily_summary"] = self.test_daily_summary()
        results["nutrition_history"] = self.test_nutrition_history()
        
        # Test meal management
        results["meal_details"] = self.test_meal_details(meal_id)
        results["update_meal"] = self.test_update_meal(meal_id)
        
        # Test additional features
        results["food_suggestions"] = self.test_food_suggestions()
        results["barcode_scan"] = self.test_barcode_scan()
        results["recommendations"] = self.test_nutritional_recommendations()
        results["export_data"] = self.test_export_data()
        
        # Summary
        logger.info("=" * 50)
        logger.info("Test Results Summary:")
        passed = sum(1 for result in results.values() if result)
        total = len(results)
        
        for test_name, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            logger.info(f"{test_name}: {status}")
        
        logger.info(f"\nOverall: {passed}/{total} tests passed")
        
        if passed == total:
            logger.info("🎉 All tests passed! Nutrition API is working correctly.")
        else:
            logger.warning(f"⚠️  {total - passed} tests failed. Check the logs above.")
        
        return results

def main():
    """Main test function"""
    print("Ryze App - Nutrition API Test Suite")
    print("=" * 40)
    
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code != 200:
            print("❌ Server is not running or not healthy")
            return
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to server. Make sure it's running on localhost:8000")
        return
    
    print("✅ Server is running")
    
    # Note about authentication
    if TEST_TOKEN == "your-test-jwt-token-here":
        print("\n⚠️  WARNING: Using placeholder token. Replace TEST_TOKEN with a real JWT token for full testing.")
        print("Some tests may fail due to authentication.")
    
    print("\nStarting tests...\n")
    
    # Run tests
    tester = NutritionAPITester()
    results = tester.run_all_tests()
    
    return results

if __name__ == "__main__":
    main() 