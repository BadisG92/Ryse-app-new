#!/usr/bin/env python3
"""
Test suite for Exercise API Module
Tests all exercise, workout, HIIT, and cardio endpoints
"""

import requests
import json
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:8000"
TEST_TOKEN = "your-test-token-here"  # Replace with actual token
HEADERS = {"Authorization": f"Bearer {TEST_TOKEN}"}

def test_get_exercises():
    """Test getting list of exercises"""
    print("Testing GET /api/exercise/exercises...")
    response = requests.get(f"{BASE_URL}/api/exercise/exercises", headers=HEADERS)
    
    if response.status_code == 200:
        exercises = response.json()
        print(f"✅ Found {len(exercises)} exercises")
        if exercises:
            print(f"   Example: {exercises[0]['name_en']} ({exercises[0]['muscle_group']})")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")

def test_get_muscle_groups():
    """Test getting muscle groups"""
    print("Testing GET /api/exercise/exercises/muscle-groups...")
    response = requests.get(f"{BASE_URL}/api/exercise/exercises/muscle-groups", headers=HEADERS)
    
    if response.status_code == 200:
        data = response.json()
        muscle_groups = data["muscle_groups"]
        print(f"✅ Found {len(muscle_groups)} muscle groups")
        print(f"   Groups: {muscle_groups[:5]}...")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")

def test_create_workout():
    """Test creating a workout session"""
    print("Testing POST /api/exercise/workouts...")
    
    workout_data = {
        "name": "Test API Workout",
        "start_time": datetime.utcnow().isoformat()
    }
    
    response = requests.post(f"{BASE_URL}/api/exercise/workouts", 
                           json=workout_data, 
                           headers=HEADERS)
    
    if response.status_code == 200:
        workout = response.json()
        print(f"✅ Created workout: {workout['name']}")
        return workout["id"]
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")
        return None

def test_hiit_workouts():
    """Test getting HIIT workouts"""
    print("Testing GET /api/exercise/hiit/workouts...")
    response = requests.get(f"{BASE_URL}/api/exercise/hiit/workouts", headers=HEADERS)
    
    if response.status_code == 200:
        workouts = response.json()
        print(f"✅ Found {len(workouts)} HIIT workouts")
        if workouts:
            print(f"   Example: {workouts[0]['title_en']} ({workouts[0]['total_duration']}s)")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")

def test_cardio_activities():
    """Test getting cardio activities"""
    print("Testing GET /api/exercise/cardio/activities...")
    response = requests.get(f"{BASE_URL}/api/exercise/cardio/activities", headers=HEADERS)
    
    if response.status_code == 200:
        activities = response.json()
        print(f"✅ Found {len(activities)} cardio activities")
        if activities:
            print(f"   Example: {activities[0]['name_en']} ({activities[0]['activity_type']})")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")

def test_exercise_stats():
    """Test getting exercise statistics"""
    print("Testing GET /api/exercise/stats...")
    response = requests.get(f"{BASE_URL}/api/exercise/stats?days=30", headers=HEADERS)
    
    if response.status_code == 200:
        stats = response.json()
        print(f"✅ Exercise stats:")
        print(f"   Total workouts: {stats['total_workouts']}")
        print(f"   Total exercises: {stats['total_exercises']}")
        print(f"   Total sets: {stats['total_sets']}")
        print(f"   Total weight lifted: {stats['total_weight_lifted']}kg")
    else:
        print(f"❌ Error: {response.status_code} - {response.text}")

def run_all_tests():
    """Run all exercise API tests"""
    print("🏋️ Starting Exercise API Tests...")
    print("=" * 50)
    
    test_get_exercises()
    print()
    
    test_get_muscle_groups()
    print()
    
    test_create_workout()
    print()
    
    test_hiit_workouts()
    print()
    
    test_cardio_activities()
    print()
    
    test_exercise_stats()
    print()
    
    print("=" * 50)
    print("✅ Exercise API testing completed!")

if __name__ == "__main__":
    run_all_tests() 