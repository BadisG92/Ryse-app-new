# Ryze API Backend

FastAPI backend for the Ryze fitness and nutrition application with **mobile-first optimizations**.

## 🚀 Features

- **Authentication**: User registration, login, JWT tokens via Supabase Auth
- **User Management**: Profile management, onboarding flow
- **Exercise Management**: Browse exercises, create custom exercises, filter by muscle group/equipment
- **Workout Tracking**: Create workout sessions, track sets/reps/weights, workout history
- **HIIT Workouts**: Predefined and custom HIIT workouts, session tracking with phases
- **Cardio Tracking**: Cardio sessions with GPS location tracking, distance, speed, calories
- **Nutrition**: Food database, meal tracking, daily nutrition summaries
- **📱 Mobile Optimizations**: Lightweight endpoints, batch operations, offline sync, compression

## 📱 Mobile-Specific Features

### Performance Optimizations
- **GZip Compression**: Reduces data usage by ~70%
- **Lightweight Models**: Simplified responses for mobile lists
- **Batch Operations**: Process multiple actions in single request
- **Response Caching**: Headers for client-side caching
- **Performance Monitoring**: Request timing headers

### Mobile Endpoints (`/api/v1/mobile`)
- `GET /mobile/dashboard` - Optimized dashboard with today's summary
- `GET /mobile/exercises/lite` - Lightweight exercise list
- `POST /mobile/batch` - Batch operations for efficiency
- `GET /mobile/sync` - Synchronization data for offline apps
- `POST /mobile/offline-actions` - Sync offline actions when online

### Offline Support (Planned)
- Offline action queuing
- Sync conflict resolution
- Progressive data loading
- Background sync capabilities

## 📋 API Endpoints

### Authentication (`/api/v1/auth`)
- `POST /auth/register` - Register new user
- `POST /auth/login` - User login
- `POST /auth/logout` - User logout
- `GET /auth/me` - Get current user profile
- `POST /auth/refresh` - Refresh access token

### Users (`/api/v1/users`)
- `GET /users/profile` - Get user profile
- `PUT /users/profile` - Update user profile
- `DELETE /users/profile` - Delete user account
- `POST /users/onboarding/complete` - Complete onboarding

### Exercises (`/api/v1/exercises`)
- `GET /exercises/` - Get all exercises (with filtering)
- `GET /exercises/muscle-groups` - Get muscle groups
- `GET /exercises/equipment` - Get equipment types
- `GET /exercises/{exercise_id}` - Get specific exercise
- `POST /exercises/` - Create custom exercise
- `PUT /exercises/{exercise_id}` - Update custom exercise
- `DELETE /exercises/{exercise_id}` - Delete custom exercise
- `GET /exercises/user/custom` - Get user's custom exercises

### Workouts (`/api/v1/workouts`)
- `GET /workouts/` - Get user's workouts
- `GET /workouts/{workout_id}` - Get specific workout
- `POST /workouts/` - Create new workout
- `PUT /workouts/{workout_id}/complete` - Complete workout
- `PUT /workouts/{workout_id}/sets/{set_id}` - Update exercise set
- `DELETE /workouts/{workout_id}` - Delete workout

### HIIT (`/api/v1/hiit`)
- `GET /hiit/workouts` - Get HIIT workouts
- `GET /hiit/workouts/{workout_id}` - Get specific HIIT workout
- `POST /hiit/workouts` - Create custom HIIT workout
- `GET /hiit/sessions` - Get user's HIIT sessions
- `POST /hiit/sessions` - Start HIIT session
- `PUT /hiit/sessions/{session_id}/phase` - Update session phase
- `PUT /hiit/sessions/{session_id}/complete` - Complete session

### Cardio (`/api/v1/cardio`)
- `GET /cardio/sessions` - Get cardio sessions
- `GET /cardio/sessions/{session_id}` - Get specific session
- `POST /cardio/sessions` - Start cardio session
- `PUT /cardio/sessions/{session_id}` - Update session data
- `PUT /cardio/sessions/{session_id}/complete` - Complete session
- `POST /cardio/sessions/{session_id}/locations` - Add location point
- `GET /cardio/sessions/{session_id}/locations` - Get location points

### Nutrition (`/api/v1/nutrition`)
- `GET /nutrition/foods` - Get foods (with search)
- `GET /nutrition/foods/{food_id}` - Get specific food
- `POST /nutrition/foods` - Create custom food
- `GET /nutrition/meals` - Get user's meals
- `GET /nutrition/meals/{meal_id}` - Get specific meal
- `POST /nutrition/meals` - Create meal
- `GET /nutrition/meals/{meal_id}/items` - Get meal food items
- `POST /nutrition/meals/{meal_id}/items` - Add food to meal
- `DELETE /nutrition/meals/{meal_id}/items/{item_id}` - Remove food from meal
- `GET /nutrition/daily-summary` - Get daily nutrition summary

### Mobile (`/api/v1/mobile`) 📱
- `GET /mobile/dashboard` - Mobile dashboard summary
- `GET /mobile/exercises/lite` - Lightweight exercise list
- `POST /mobile/batch` - Batch operations
- `GET /mobile/sync` - Sync data for offline
- `POST /mobile/offline-actions` - Sync offline actions

## 🛠️ Setup

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Environment Variables**
   Create a `.env` file in the backend directory:
   ```env
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_KEY=your_supabase_anon_key
   DEBUG=true
   ENVIRONMENT=development
   ```

3. **Run the Server**
   ```bash
   python main.py
   # or
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

4. **Access Documentation**
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

## 📱 Mobile Integration Guide

### Flutter HTTP Client Setup
```dart
// Configure HTTP client for mobile optimizations
final client = http.Client();
final headers = {
  'Accept-Encoding': 'gzip',
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
};
```

### Batch Operations Example
```dart
// Batch multiple operations for efficiency
final batchRequest = {
  'operations': [
    {'type': 'insert', 'table': 'meals', 'data': mealData},
    {'type': 'update', 'table': 'workouts', 'id': workoutId, 'data': updateData},
  ],
  'sync_timestamp': DateTime.now().toIso8601String(),
};
```

### Dashboard Integration
```dart
// Get mobile-optimized dashboard
final dashboard = await api.get('/api/v1/mobile/dashboard');
// Returns: workouts summary, nutrition totals, quick actions
```

## 🗄️ Database Schema

The API uses Supabase PostgreSQL with the following main tables:
- `users` - User profiles and authentication
- `exercises` - Exercise library (predefined + custom)
- `workout_sessions` - Workout sessions
- `workout_exercises` - Exercises within workout sessions
- `exercise_sets` - Individual sets (reps, weight)
- `hiit_workouts` - HIIT workout templates
- `hiit_sessions` - HIIT workout sessions
- `cardio_sessions` - Cardio activity sessions
- `location_points` - GPS tracking for cardio
- `foods` - Food nutrition database
- `meals` - User meal entries
- `meal_food_items` - Foods within meals

## 🔐 Authentication

The API uses Supabase Auth for authentication:
- JWT tokens for API access
- Row Level Security (RLS) for data protection
- All endpoints (except health checks) require authentication
- Bearer token format: `Authorization: Bearer <token>`

## 📱 Mobile Performance Features

### Data Compression
- **GZip compression** reduces response sizes by ~70%
- **Lightweight models** for list views (ExerciseLite, WorkoutSummary)
- **Selective field loading** to minimize data transfer

### Caching Strategy
- **HTTP headers** for client-side caching
- **ETag support** for conditional requests
- **Last-Modified** headers for incremental updates

### Batch Operations
- **Multiple operations** in single request
- **Reduced network calls** for better performance
- **Transaction-like** behavior for data consistency

### Offline Support (Planned)
- **Action queuing** for offline operations
- **Conflict resolution** for sync scenarios
- **Progressive sync** for large datasets

## 🚦 Error Handling

Standard HTTP status codes:
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `422` - Validation Error
- `429` - Rate Limited (mobile protection)
- `500` - Internal Server Error

All errors return JSON with `detail` field explaining the issue.

## 🧪 Testing

Use the interactive Swagger documentation at `/docs` to test all endpoints.

Mobile-optimized testing:
```bash
# Test compression
curl -H "Accept-Encoding: gzip" "http://localhost:8000/api/v1/mobile/dashboard"

# Test batch operations
curl -X POST "http://localhost:8000/api/v1/mobile/batch" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"operations": [{"type": "insert", "table": "meals", "data": {...}}]}'
```

## 📊 Performance Monitoring

The API includes performance monitoring:
- **Response time headers** (`X-Process-Time`)
- **Request counting** for analytics
- **Error rate tracking** for reliability
- **Mobile-specific metrics** for optimization 