# Ryze App - Data Structure & Flow Analysis

> **Last Updated**: December 2024  
> **Purpose**: Comprehensive analysis of all data points, structures, and flows in the ryze_app for backend implementation reference.  
> **Status**: ✅ Complete analysis - Ready for backend implementation

---

## 📋 TABLE OF CONTENTS

1. [App Architecture Overview](#app-architecture-overview)
2. [Onboarding Flow](#onboarding-flow)
3. [Main Dashboard (Home)](#main-dashboard-home)
4. [Nutrition Section](#nutrition-section)
5. [Sport Section](#sport-section)
6. [Progress Section](#progress-section)
7. [Specialized Screens](#specialized-screens)
8. [Data Models](#data-models)
9. [Data Classification](#data-classification)
10. [Backend Requirements](#backend-requirements)

---

## 🏗️ APP ARCHITECTURE OVERVIEW

### Navigation Structure
```
RyzeApp
├── OnboardingGamifiedHybrid (first-time users)
└── MainApp (4 tabs)
    ├── Home (MainDashboardHybrid)
    ├── Nutrition (NutritionSection)
    │   ├── Dashboard (NutritionDashboardHybrid)
    │   ├── Journal (NutritionJournalHybrid)
    │   └── Recipes (NutritionRecipesHybrid)
    ├── Sport (SportSection)
    │   ├── Dashboard (SportDashboard)
    │   ├── Cardio (SportCardioHybrid)
    │   └── Musculation (SportMusculationHybrid)
    └── Progress (GlobalProgress)
```

### Data Persistence
- **Local**: SharedPreferences for user settings and offline data
- **Models**: Separate model files for each domain (nutrition, sport, user)
- **State Management**: StatefulWidgets with local state + static data classes

---

## 🚀 ONBOARDING FLOW

**File**: `lib/components/onboarding_gamified_hybrid.dart`

### User Input Data Collected

| Field | Type | Purpose | Validation |
|-------|------|---------|------------|
| `gender` | String | BMR calculation | Required: 'Homme'/'Femme'/'Autre' |
| `birthMonth` | String | Age calculation | 1-12 |
| `birthDay` | String | Age calculation | 1-31 |
| `birthYear` | String | Age calculation | Current year - 100 to current year |
| `age` | String | Calculated from birth date | Auto-calculated |
| `height` | String | BMR calculation | Required (cm or inches) |
| `weight` | String | BMR calculation | Required (kg or lbs) |
| `isMetric` | bool | Unit system | Default: true |
| `activity` | String | TDEE calculation | Required: sedentary/light/moderate/very/extra |
| `goal` | String | Calorie adjustment | Required: lose/lose_fast/maintain/gain |
| `obstacles` | List<String> | Personalization | Multiple selection |
| `restrictions` | List<String> | Diet customization | Multiple selection |

### Calculated Values

| Value | Formula | Purpose |
|-------|---------|---------|
| **BMR** | Mifflin-St Jeor equation | Base metabolic rate |
| **TDEE** | BMR × activity factor | Total daily energy expenditure |
| **Daily Calories** | TDEE ± goal adjustment | Personalized calorie target |
| **Macros** | Protein/Carbs/Fat ratios | Nutritional targets |

### Activity Factors
```dart
static const Map<String, double> activityFactors = {
  'sedentary': 1.2,    // Little/no exercise
  'light': 1.375,      // Light exercise 1-3 days/week
  'moderate': 1.55,    // Moderate exercise 3-5 days/week
  'very': 1.725,       // Hard exercise 6-7 days/week
  'extra': 1.9,        // Very hard exercise, physical job
};
```

### Goal Adjustments
```dart
switch (goal) {
  case 'lose': return (tdee - 500).round();      // -0.5kg/week
  case 'lose_fast': return (tdee - 750).round(); // -0.75kg/week
  case 'maintain': return tdee.round();          // Maintenance
  case 'gain': return (tdee + 300).round();      // +0.3kg/week
}
```

---

## 🏠 MAIN DASHBOARD (HOME)

**File**: `lib/components/main_dashboard_hybrid.dart`

### Static User Profile Data
```dart
static const UserProfile userProfile = UserProfile(
  name: 'Rihab',              // Fixed value - should be user input
  streak: 7,                  // Days consecutive usage
  todayScore: 85,             // % of daily goals completed
  todayXP: 250,               // XP gained today
  isPremium: false,           // Subscription status
  photosUsed: 2,              // Free tier: 3/day limit
  dailyCalories: 2500,        // From onboarding calculation
  currentCalories: 1247,      // Sum of logged meals
);
```

### Daily Goals Tracking
```dart
static const List<DailyGoal> dailyGoals = [
  // Goal 1: Meal Tracking
  DailyGoal(
    id: 'meals',
    label: 'Suivre mes repas aujourd\'hui',
    progress: 67,               // 2/3 meals logged
    currentValue: 2,            // Meals logged count
    targetValue: 3,             // Target meals per day
    xp: 25,                     // XP reward
  ),
  
  // Goal 2: Water Intake
  DailyGoal(
    id: 'water',
    label: 'Boire 2L d\'eau',
    progress: 75,               // 1.5L/2L
    currentValue: 1.5,          // Liters consumed
    targetValue: 2.0,           // Daily water goal
    unit: 'L',
    xp: 15,
  ),
  
  // Goal 3: Calorie Target
  DailyGoal(
    id: 'calories',
    label: 'Atteindre mes calories',
    progress: 80,               // 1600/2000 cal
    currentValue: 1600,         // Calories consumed
    targetValue: 2000,          // Daily calorie target
    unit: 'cal',
    xp: 25,
  ),
  
  // Goal 4: Workout
  DailyGoal(
    id: 'workout',
    label: 'Faire une séance aujourd\'hui',
    progress: 100,              // 1/1 session completed
    currentValue: 1,            // Sessions completed
    targetValue: 1,             // Daily workout goal
    completed: true,
    xp: 30,
  ),
];
```

### Quick Actions
- **Add Meal**: Navigate to food logging options
- **Add Water**: Quick water logging with presets
- **Take Photo**: AI food scanner (premium limits)
- **Cardio**: Start cardio session
- **Musculation**: Start strength session
- **Weight Tracking**: Log current weight

### Calculated Values
- **Calories Progress**: `currentCalories / dailyCalories`
- **Remaining Calories**: `max(0, dailyCalories - currentCalories)`
- **Completion Score**: Average of all goal progress percentages

---

## 🍎 NUTRITION SECTION

### 🎯 A. Nutrition Dashboard
**File**: `lib/components/nutrition_dashboard_hybrid.dart`

#### Main Nutrition Profile
```dart
static const NutritionProfile profile = NutritionProfile(
  targetCalories: 2500,       // From onboarding calculation
  currentCalories: 1247,      // Sum of logged foods
  targetProtein: 150,         // 30% of calories (variable)
  currentProtein: 85,         // Sum from logged foods
  targetCarbs: 250,           // 40% of calories (variable)
  currentCarbs: 120,          // Sum from logged foods
  targetFat: 80,              // 30% of calories (variable)
  currentFat: 45,             // Sum from logged foods
  waterLevel: 0.48,           // 0.0-1.0 (48% of 2L goal)
);
```

#### Animated Counters
- **Calories**: Animates from 0 to current value
- **Protein**: Animates with different timing
- **Carbs**: Animates with different timing
- **Fat**: Animates with different timing

#### Meal Progress Tracking
```dart
static const List<Meal> meals = [
  Meal(
    id: 'breakfast',
    name: 'Petit-déjeuner',
    calories: 320,
    isCompleted: true,
    time: TimeOfDay(hour: 8, minute: 0),
  ),
  Meal(
    id: 'lunch',
    name: 'Déjeuner',
    calories: 450,
    isCompleted: true,
    time: TimeOfDay(hour: 12, minute: 30),
  ),
  Meal(
    id: 'snack',
    name: 'Collation',
    calories: 180,
    isCompleted: true,
    time: TimeOfDay(hour: 16, minute: 0),
  ),
  Meal(
    id: 'dinner',
    name: 'Dîner',
    calories: 0,              // Not completed yet
    isCompleted: false,
    time: TimeOfDay(hour: 20, minute: 0),
  ),
];
```

#### Water Tracking Options
```dart
static const List<WaterOption> waterOptions = [
  WaterOption(label: '1 verre', amount: '250 ml', milliliters: 250),
  WaterOption(label: '1 gourde', amount: '500 ml', milliliters: 500),
  WaterOption(label: '1 litre', amount: '1000 ml', milliliters: 1000),
];
```

#### AI Nutrition Tips
```dart
static const List<NutritionTip> tips = [
  NutritionTip(
    content: '💡 Astuce : Buvez un verre d\'eau avant chaque repas...',
    category: 'hydration',
    accentColor: Color(0xFF0B132B),
  ),
  NutritionTip(
    content: '⏰ Timing parfait : Consommez vos protéines dans les 30 minutes...',
    category: 'timing',
    accentColor: Color(0xFF1C2951),
  ),
  // Additional tips...
];
```

### 📖 B. Nutrition Journal
**File**: `lib/components/nutrition_journal_hybrid.dart`

#### Data Structure
- **Daily meal breakdown** organized by time periods
- **Food items** with detailed nutritional information
- **Portion tracking** with quantity adjustments
- **Meal assignment** to specific time slots

### 👨‍🍳 C. Nutrition Recipes
**File**: `lib/components/nutrition_recipes_hybrid.dart`

#### Recipe Data Structure
- **Recipe metadata**: name, servings, prep time
- **Ingredients list**: with quantities and nutritional values
- **Instructions**: step-by-step cooking directions
- **Nutritional summary**: total calories, macros per serving

---

## 🏃‍♂️ SPORT SECTION

### 🎯 A. Sport Dashboard
**File**: `lib/components/sport_dashboard.dart`

#### Weekly Calorie Tracking
```dart
// Animated values
int weeklyCalories = 1260;           // Burned this week (animated)
const int targetWeeklyCalories = 2000; // Weekly target
final int avgDailyCalories = (weeklyCalories / 7).round(); // ~180/day
```

#### Activity Calendar (7-day view)
```dart
final List<Map<String, dynamic>> recentWorkouts = [
  {"date": "L", "hasWorkout": true, "activities": ["musculation"]},
  {"date": "M", "hasWorkout": false, "activities": []},
  {"date": "M", "hasWorkout": true, "activities": ["cardio"]},
  {"date": "J", "hasWorkout": true, "activities": ["musculation", "cardio"]},
  {"date": "V", "hasWorkout": false, "activities": []},
  {"date": "S", "hasWorkout": true, "activities": ["cardio"]},
  {"date": "D", "hasWorkout": false, "activities": []},
];
```

#### Streak & Summary Data
```dart
int dailyStreak = 7;    // Consecutive days with workouts
int weeklyStreak = 3;   // Consecutive weeks with target achievement
```

### 🏃 B. Cardio Section
**File**: `lib/components/sport_cardio_hybrid.dart`

#### Real-time Session Data
```dart
class CardioSessionData {
  final String activityType;         // 'running', 'bike', 'walking'
  final String activityTitle;        // Display name
  final DateTime startTime;          // Session start
  DateTime? endTime;                 // Session end
  Duration duration;                 // Real-time duration
  double distance;                   // km (GPS or manual)
  double? targetDistance;            // Goal distance (optional)
  Duration? targetDuration;          // Goal duration (optional)
  bool isRunning;                    // Session state
  bool isPaused;                     // Pause state
  List<LocationPoint> route;         // GPS tracking points
  double averageSpeed;               // km/h calculated
  double currentSpeed;               // km/h real-time
  int steps;                         // Pedometer (walking)
  int calories;                      // Estimated burn
}
```

#### GPS Tracking
```dart
class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;
}
```

#### Calorie Estimation
```dart
// Calories per minute by activity
switch (activityType) {
  case 'running': caloriesPerMinute = 12.0;  // ~720 cal/h
  case 'bike': caloriesPerMinute = 8.0;      // ~480 cal/h
  case 'walking': caloriesPerMinute = 5.0;   // ~300 cal/h
}
calories = (duration.inMinutes * caloriesPerMinute).round();
```

### 💪 C. Musculation Section
**File**: `lib/components/sport_musculation_hybrid.dart`

#### Exercise Database Structure
```dart
class Exercise {
  final String id;              // Unique identifier
  final String name;            // Exercise name
  final String muscleGroup;     // Target muscle group
  final String equipment;       // Required equipment
  final String description;     // Exercise description
  final bool isCustom;          // User-created exercise
}
```

#### Workout Session Tracking
```dart
class WorkoutSession {
  final String id;                      // Session identifier
  final String name;                    // Session name
  final DateTime startTime;             // Session start
  final DateTime? endTime;              // Session end
  final List<WorkoutExercise> exercises; // Exercise list
  final bool isCompleted;               // Completion status
  
  // Calculated properties
  Duration get duration;                // Session length
  int get totalSets;                    // Total sets count
  int get completedSets;                // Completed sets count
}
```

#### Set Tracking
```dart
class ExerciseSet {
  final int reps;           // Repetitions performed
  final double weight;      // Weight used (kg)
  final bool isCompleted;   // Set completion status
}

class WorkoutExercise {
  final Exercise exercise;          // Exercise reference
  final List<ExerciseSet> sets;     // Sets performed
}
```

#### Session Metrics Calculation
```dart
// Total weight lifted
double get _totalWeight {
  return _exercises.fold(0.0, (sum, exercise) => 
    sum + exercise.sets
      .where((set) => set.isCompleted)
      .fold(0.0, (setSum, set) => setSum + (set.weight * set.reps))
  );
}

// Estimated calories burned
int get _estimatedCalories {
  final baseCalories = _totalWeight * 0.35;     // Weight-based
  final timeCalories = _sessionDuration.inMinutes * 5.0; // Time-based
  return (baseCalories + timeCalories).round();
}
```

---

## 📊 PROGRESS SECTION

**File**: `lib/components/global_progress_hybrid.dart`

### Weight Evolution Tracking
```dart
class WeightProgress {
  final double currentWeight;           // Current weight (kg)
  final double initialWeight;          // Starting weight
  final double targetWeight;           // Goal weight
  final List<WeightEntry> history;     // Historical entries
  final DateTime lastUpdate;           // Last logged date
}

class WeightEntry {
  final DateTime date;
  final double weight;
  final String? notes;                 // Optional notes
}
```

### Weekly Balance Summary
```dart
class WeeklyBalance {
  final int caloriesConsumed;          // Total food calories
  final int caloriesBurned;            // Total exercise calories
  final int netCalories;               // Net balance
  final double weightChange;           // Weight delta (kg)
  final bool onTrack;                  // Goal progress status
}
```

### Daily Tracking Overview
```dart
class TrackingDay {
  final DateTime date;
  final bool nutritionLogged;          // Meals tracked
  final bool workoutCompleted;         // Exercise done
  final double completionRate;         // % of goals hit
  final int xpEarned;                  // XP for the day
}
```

### AI Recommendations
```dart
class AIRecommendation {
  final String title;                  // Recommendation title
  final String content;                // Detailed advice
  final String category;               // Type: nutrition/sport/general
  final int priority;                  // Display priority
  final DateTime generated;           // When created
}
```

---

## 🔧 SPECIALIZED SCREENS

### 📷 AI Scanner Screen
**File**: `lib/screens/ai_scanner_screen.dart`

#### Data Flow
1. **Camera Capture**: Device camera access
2. **Image Processing**: AI analysis (simulated)
3. **Food Recognition**: Identify food items
4. **Nutritional Estimation**: Calculate values
5. **User Confirmation**: Allow editing before saving

#### Output Data Structure
```dart
class ScannedFood {
  final String name;                   // Identified food name
  final int estimatedCalories;         // Per portion
  final double estimatedWeight;        // Portion size (g)
  final Map<String, double> macros;    // Protein, carbs, fat
  final double confidence;             // AI confidence score
  final String imagePath;              // Captured image
}
```

### 📱 Barcode Scanner Screen
**File**: `lib/screens/barcode_scanner_screen.dart`

#### Data Flow
1. **Barcode Scanning**: Camera barcode detection
2. **Product Lookup**: External database query
3. **Nutritional Facts**: Per 100g values
4. **Quantity Adjustment**: User portion input
5. **Meal Assignment**: Select meal type

#### Product Data Structure
```dart
class ScannedProduct {
  final String barcode;                // EAN/UPC code
  final String productName;            // Official product name
  final String brand;                  // Manufacturer
  final int caloriesPer100g;          // Base nutritional values
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double userQuantity;          // User-specified amount
}
```

### ✏️ Manual Food Entry Screen
**File**: `lib/screens/manual_food_entry_screen.dart`

#### User Input Fields
```dart
// Required fields
final String name;                   // Food name
final double quantity;               // Amount in grams
final int calories;                  // Per 100g

// Optional nutritional values (per 100g)
final double? protein;
final double? carbs;
final double? fat;
final double? fiber;
final double? sugar;
final double? sodium;
```

### 🏋️ Workout Session Screen
**File**: `lib/screens/workout_session_screen.dart`

#### Real-time Session Data
```dart
class ActiveWorkoutSession {
  final String sessionName;           // User-defined name
  final DateTime startTime;           // Session start
  final List<WorkoutExercise> exercises; // Exercise queue
  final int currentExerciseIndex;     // Active exercise
  final Duration currentDuration;     // Real-time timer
  final Map<String, TextEditingController> controllers; // Input controllers
}
```

#### Input Tracking per Set
```dart
// Per exercise, per set tracking
Map<String, Map<int, TextEditingController>> _weightControllers;
Map<String, Map<int, TextEditingController>> _repsControllers;
Map<String, Map<int, FocusNode>> _weightFocusNodes;
Map<String, Map<int, FocusNode>> _repsFocusNodes;
```

#### Session Metrics (Real-time)
- **Total Sets**: Count of all sets across exercises
- **Completed Sets**: Count of sets marked complete
- **Total Weight**: Sum of (weight × reps) for completed sets
- **Session Duration**: Real-time timer from start
- **Estimated Calories**: Formula-based calculation

---

## 🗃️ DATA MODELS

### Core Model Files

#### `lib/models/nutrition_models.dart`
```dart
class Meal {
  final String time;                   // Meal time slot
  final String name;                   // Meal name
  final List<FoodItem> items;          // Food items in meal
}

class FoodItem {
  final String name;                   // Food name
  final int calories;                  // Calorie content
  final String portion;                // Portion description
}
```

#### `lib/models/sport_models.dart`
```dart
// Exercise, ExerciseSet, WorkoutExercise, WorkoutSession classes
// MuscleGroups constants
// Exercise database structure
```

#### `lib/models/cardio_session_models.dart`
```dart
// CardioSessionData, LocationPoint classes
// GPS tracking structure
// Activity type definitions
```

#### `lib/models/hiit_models.dart`
```dart
// HIIT-specific workout structures
// Interval timing data
// High-intensity exercise definitions
```

### UI Model Files

#### `lib/components/ui/dashboard_models.dart`
```dart
// UserProfile, DailyGoal, QuickAction
// ModulePreview, CommunityStats
// MetabolicCalculator utility class
// DashboardData static data
```

#### `lib/components/ui/nutrition_models.dart`
```dart
// NutritionProfile, MacroNutrient, Meal
// NutritionQuickAction, WaterOption, NutritionTip
// NutritionData static data
```

#### `lib/components/ui/global_progress_models.dart`
```dart
// WeightProgress, WeeklyBalance, TrackingDay
// AIRecommendation, HeaderStats
// GlobalProgressData static data
```

---

## 🏷️ DATA CLASSIFICATION

### 👤 User Input Data
**Description**: Data directly entered by users
- Personal information (age, weight, height, goals)
- Food logging (meal entries, portions, custom foods)
- Exercise tracking (sets, reps, weights, durations)
- Manual measurements (weight updates, water intake)
- Preferences and settings

### 🧮 Calculated/Derived Data
**Description**: Values computed from user data
- BMR (Basal Metabolic Rate)
- TDEE (Total Daily Energy Expenditure)
- Daily calorie and macro targets
- Progress percentages and completion rates
- Averages, trends, and historical analysis
- Estimated calories burned during activities

### 📊 Aggregate Data
**Description**: Summary data across time periods
- Weekly/monthly summaries
- Streak calculations (daily, weekly)
- Goal completion rates
- Historical trends and patterns
- Performance metrics and analytics

### ⚡ Real-time Data
**Description**: Live data during active sessions
- Session timers and duration tracking
- GPS location data (for cardio)
- Live progress counters and animations
- Current session metrics
- Real-time form input validation

### 🔢 Static/Reference Data
**Description**: Fixed data for app functionality
- Exercise database and muscle groups
- Food database and nutritional references
- UI strings, labels, and messages
- Achievement thresholds and XP values
- Formula constants and calculation factors

### 🌐 External Data Sources
**Description**: Data from external APIs/services
- Barcode product database lookups
- GPS and location services
- Device sensors (pedometer, etc.)
- AI image recognition results
- Nutritional database queries

---

## 🔌 BACKEND REQUIREMENTS

### 🗄️ Database Schema Requirements

#### Users Table
```sql
users (
  id, email, password_hash, created_at, updated_at,
  name, gender, birth_date, height, weight, activity_level,
  goal, is_metric, is_premium, streak_days, total_xp
)
```

#### User Goals Table
```sql
user_goals (
  id, user_id, daily_calories, target_protein, target_carbs, target_fat,
  daily_water_goal, workout_frequency, created_at, updated_at
)
```

#### Food Database
```sql
foods (
  id, name, brand, barcode, calories_per_100g,
  protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, created_at, is_verified
)
```

#### User Food Logs
```sql
food_logs (
  id, user_id, food_id, meal_type, quantity_grams,
  logged_at, calories, protein, carbs, fat
)
```

#### Exercise Database
```sql
exercises (
  id, name, muscle_group, equipment, description,
  is_custom, created_by_user_id, created_at
)
```

#### Workout Sessions
```sql
workout_sessions (
  id, user_id, name, start_time, end_time,
  total_sets, completed_sets, total_weight,
  estimated_calories, created_at
)
```

#### Workout Exercises
```sql
workout_exercises (
  id, session_id, exercise_id, sets_planned,
  sets_completed, created_at
)
```

#### Exercise Sets
```sql
exercise_sets (
  id, workout_exercise_id, set_number, reps,
  weight_kg, is_completed, completed_at
)
```

#### Cardio Sessions
```sql
cardio_sessions (
  id, user_id, activity_type, start_time, end_time,
  distance_km, average_speed, steps, calories,
  gps_route_json, created_at
)
```

#### Weight Tracking
```sql
weight_entries (
  id, user_id, weight_kg, recorded_at, notes
)
```

#### Water Intake
```sql
water_logs (
  id, user_id, amount_ml, logged_at
)
```

### 🔄 API Endpoints Required

#### Authentication
- `POST /auth/register` - User registration
- `POST /auth/login` - User login
- `POST /auth/refresh` - Token refresh
- `POST /auth/logout` - User logout

#### User Profile
- `GET /user/profile` - Get user data
- `PUT /user/profile` - Update user data
- `POST /user/onboarding` - Complete onboarding
- `GET /user/goals` - Get user goals
- `PUT /user/goals` - Update user goals

#### Nutrition
- `GET /nutrition/foods/search` - Search food database
- `GET /nutrition/foods/barcode/{code}` - Lookup by barcode
- `POST /nutrition/foods` - Create custom food
- `POST /nutrition/logs` - Log food intake
- `GET /nutrition/logs/{date}` - Get daily logs
- `DELETE /nutrition/logs/{id}` - Remove food log
- `POST /nutrition/water` - Log water intake
- `GET /nutrition/dashboard/{date}` - Dashboard data

#### Sport
- `GET /sport/exercises` - Get exercise database
- `POST /sport/exercises` - Create custom exercise
- `POST /sport/sessions` - Start workout session
- `PUT /sport/sessions/{id}` - Update session
- `POST /sport/sessions/{id}/complete` - Complete session
- `GET /sport/sessions/recent` - Recent workouts
- `POST /sport/cardio` - Log cardio session
- `GET /sport/dashboard` - Sport dashboard data

#### Progress
- `POST /progress/weight` - Log weight entry
- `GET /progress/weight/history` - Weight history
- `GET /progress/weekly-summary` - Weekly summary
- `GET /progress/dashboard` - Progress dashboard
- `GET /progress/analytics` - Advanced analytics

#### AI & External Services
- `POST /ai/analyze-food-image` - AI food recognition
- `GET /external/barcode/{code}` - External barcode lookup
- `POST /external/gps-route` - Save GPS tracking data

### 🔐 Data Security & Privacy
- All user data encrypted at rest
- Secure API authentication with JWT tokens
- Privacy-compliant data handling
- GDPR compliance for EU users
- Data export functionality for users
- Secure image upload and processing

### 📈 Analytics & Reporting
- Daily/weekly/monthly progress summaries
- Goal achievement tracking
- Streak calculations and maintenance
- Performance trend analysis
- Personalized recommendations generation
- Usage analytics (privacy-compliant)

---

## 📝 MAINTENANCE NOTES

### 🔄 Update Procedures
1. **When adding new data points**: Update this document with new fields
2. **When modifying existing models**: Update corresponding sections
3. **When adding new screens**: Add complete data analysis
4. **When changing calculations**: Update formula documentation

### 🧪 Testing Requirements
- Unit tests for all calculation functions
- Integration tests for data persistence
- UI tests for data entry workflows
- Performance tests for large datasets
- Security tests for data protection

### 📚 Developer Resources
- **Model Files**: Check `/lib/models/` for current data structures
- **UI Models**: Check `/lib/components/ui/` for UI-specific models
- **Static Data**: Look for `Data` classes with static properties
- **Calculations**: Search for `Calculator` classes and calculation methods

---

> **⚠️ Important**: This document should be updated whenever any data-related changes are made to the app. Keep it in sync with the actual implementation to ensure accurate backend development. 