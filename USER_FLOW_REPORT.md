# Ryse App - User Journey & Flow Report

## Executive Summary
Ryse is a comprehensive fitness and nutrition coaching app that guides users through personalized health journeys. The app combines AI-powered food tracking, workout management, and progress monitoring to help users achieve their fitness goals.

---

## 🚀 User Onboarding Flow

### Initial Setup Journey
1. **Authentication**
   - User opens app → Login/Signup screen
   - Options: Email/Password, Google Sign-in, Apple Sign-in
   - Password recovery available

2. **Gamified Onboarding Process** (`onboarding_gamified_hybrid.dart`)
   - **Step 1: Personal Information**
     - Gender selection (visual cards)
     - Age input
     - Birth date (month/day/year)

   - **Step 2: Physical Metrics**
     - Current weight (metric/imperial toggle)
     - Height measurement
     - Target weight setting

   - **Step 3: Activity Level**
     - Sedentary
     - Lightly active
     - Moderately active
     - Very active
     - Extremely active

   - **Step 4: Fitness Goals**
     - Weight loss
     - Weight gain
     - Muscle building
     - Maintenance
     - General fitness

   - **Step 5: Obstacles & Challenges**
     - Time constraints
     - Motivation
     - Knowledge
     - Dietary restrictions

   - **Step 6: Dietary Preferences**
     - Vegetarian
     - Vegan
     - Gluten-free
     - Dairy-free
     - Other restrictions

3. **Calorie & Macro Calculation**
   - Loading animation with progress messages
   - BMR calculation based on user data
   - TDEE adjustment for activity level
   - Goal-based calorie adjustment
   - Default macro split: 30% protein, 40% carbs, 30% fat
   - Option to customize macros

4. **Profile Creation**
   - Data saved to Supabase
   - User preferences stored
   - Dashboard initialized

---

## 🥗 NUTRITION USER JOURNEY

### Main Nutrition Dashboard (`nutrition_dashboard_hybrid.dart`)

#### Dashboard Overview
Users see a comprehensive nutrition dashboard with:
- **Daily Calorie Progress Ring**: Visual representation of calories consumed vs. target
- **Macronutrient Breakdown**: Protein, Carbs, Fat progress bars
- **Today's Meals Summary**: List of consumed meals
- **Quick Actions**: Add food, water tracking, view journal

### Food Entry Methods

#### 1. AI Scanner (Primary Method)
**Flow**: Dashboard → "+" Button → AI Scanner
- Camera permission request
- Live camera preview
- Capture photo button
- AI analysis (Google Vision + Gemini)
- Results display with:
  - Food identification
  - Portion estimation
  - Nutritional breakdown
- Confirmation/Edit options
- Select meal type (Breakfast/Lunch/Dinner/Snack)
- Save to journal

#### 2. Barcode Scanner
**Flow**: Dashboard → "+" Button → Barcode Scanner
- Camera permission request
- Barcode scanning interface
- Product lookup (OpenFoodFacts API)
- Product details display
- Quantity adjustment
- Meal selection
- Save to journal

#### 3. Manual Food Search
**Flow**: Dashboard → "+" Button → Manual Search
- Search bar interface
- Real-time search results
- Food database (localized)
- Recent/Frequent foods section
- Custom food creation option
- Food selection → Quantity input
- Nutritional preview
- Meal assignment
- Save to journal

#### 4. Recipe Selection
**Flow**: Dashboard → "+" Button → Recipes
- Recipe library display
- Categories/Tags filtering
- Recipe search
- Recipe details:
  - Ingredients list
  - Nutritional information
  - Preparation steps
  - Portion adjustment
- Add to meal
- Save to journal

### Meal Management

#### Creating Meals
1. **New Meal Creation**
   - Select meal type or create custom
   - Add foods via any method above
   - Real-time calorie/macro updates
   - Save meal as template (optional)

2. **Meal Types**
   - Breakfast (Petit-déjeuner)
   - Lunch (Déjeuner)
   - Dinner (Dîner)
   - Snacks (Collations)
   - Custom meal types

#### Nutrition Journal (`nutrition_journal_hybrid.dart`)
- **Daily View**: Shows all meals for selected date
- **Calendar View**: Navigate between dates
- **Meal Cards Display**:
  - Meal name and time
  - Food items list
  - Calorie total
  - Edit/Delete options
- **Food Item Actions**:
  - Edit quantity
  - Delete item
  - View details
  - Copy to another meal

### Water Tracking
**Flow**: Dashboard → Water Widget → Add Water
- Quick add buttons (+250ml, +500ml)
- Custom amount input
- Daily goal progress
- Hydration reminders
- Historical tracking

### Custom Food Creation
**Flow**: Any food search → "Create Custom Food"
- Food name input
- Brand (optional)
- Serving size
- Nutritional values:
  - Calories
  - Protein
  - Carbs
  - Fat
  - Fiber (optional)
- Save to personal database
- Available in future searches

---

## 💪 SPORT & FITNESS USER JOURNEY

### Sport Dashboard (`sport_dashboard.dart`)

#### Dashboard Overview
- **Weekly Activity Summary**: Calendar view with workout indicators
- **Calories Burned Today**: Animated counter
- **Active Minutes**: Daily activity time
- **Workout Streak**: Consecutive days trained
- **Recent Workouts**: Last 3-5 sessions
- **Quick Start Options**: Start workout, cardio, HIIT

### Workout Types

#### 1. Strength Training (`workout_session_screen.dart`)

**Starting a Workout**
Flow: Sport Dashboard → "Start Workout"
1. **Session Setup**
   - Name your session
   - Select from templates or create custom
   - Choose exercises from library

2. **Exercise Selection** (`exercise_selection_bottom_sheet.dart`)
   - Search exercises
   - Filter by muscle group:
     - Chest (Pectoraux)
     - Back (Dos)
     - Legs (Jambes)
     - Shoulders (Épaules)
     - Arms (Bras)
     - Core (Abdominaux)
   - View exercise details
   - Add to workout

3. **During Workout Session**
   - **Timer Display**: Shows elapsed time
   - **Exercise Cards**: Current exercise display
   - **Set Management**:
     - Weight input (kg/lbs)
     - Reps input
     - Rest timer between sets
     - Add/Remove sets
   - **Exercise History**: View previous performance
   - **Navigation**: Next/Previous exercise
   - **Intensity Selection**: Low/Moderate/High

4. **Workout Completion**
   - Summary screen:
     - Total duration
     - Exercises completed
     - Total volume (weight × reps)
     - Calories burned
   - Save workout
   - Add notes (optional)
   - Share progress (optional)

#### 2. Cardio Activities (`cardio_tracking_screen.dart`)

**Starting Cardio**
Flow: Sport Dashboard → "Start Cardio"

1. **Activity Selection**
   - Running (Course)
   - Cycling (Vélo)
   - Swimming (Natation)
   - Walking (Marche)
   - Other activities

2. **Live Tracking Mode**
   - **Real-time Metrics**:
     - Duration timer
     - Distance (if applicable)
     - Pace/Speed
     - Heart rate (if connected)
     - Calories burned
   - **Controls**:
     - Pause/Resume
     - End session
   - **GPS Tracking** (for outdoor activities)

3. **Manual Entry** (`manual_cardio_entry_screen.dart`)
   - Select activity type
   - Enter duration
   - Enter distance (optional)
   - Select intensity
   - Add notes
   - Save entry

#### 3. HIIT Workouts (`hiit_session_screen.dart`)

**HIIT Setup**
Flow: Sport Dashboard → "Start HIIT"

1. **Configuration** (`hiit_config_screen.dart`)
   - Work duration (seconds)
   - Rest duration (seconds)
   - Number of rounds
   - Exercise selection
   - Warm-up/Cool-down options

2. **During HIIT Session**
   - **Visual Timer**: Large countdown display
   - **Phase Indicators**:
     - Work phase (green)
     - Rest phase (yellow)
     - Transition warnings
   - **Audio Cues**: Beeps for phase changes
   - **Round Counter**: Current round/Total rounds
   - **Pause/Skip Options**

3. **Session Completion**
   - Total time
   - Calories burned
   - Exercises completed
   - Save to history

### Workout Programs

**Program Selection** (`program_selection_bottom_sheet.dart`)
- Pre-built programs:
  - Beginner Full Body
  - Push/Pull/Legs
  - Upper/Lower Split
  - 5x5 Strength
- Custom program creation
- Program scheduling
- Progress tracking per program

### Exercise Library
- **Localized Exercises**: Multi-language support
- **Exercise Details**:
  - Animated demonstrations
  - Muscle groups targeted
  - Difficulty level
  - Equipment needed
  - Instructions/Tips

---

## 📊 PROGRESS TRACKING

### Weight Evolution (`weight_evolution_screen.dart`)
- **Weight Entry**: Manual input with date
- **Progress Chart**: Line graph visualization
- **Statistics**:
  - Starting weight
  - Current weight
  - Goal weight
  - Total loss/gain
  - Weekly average change
- **Milestones**: Achievement markers

### Global Progress (`global_progress_hybrid.dart`)
- **Combined Metrics**:
  - Nutrition adherence
  - Workout consistency
  - Weight progress
  - Streak maintenance
- **Achievement System**:
  - Badges earned
  - Levels/Points
  - Challenges completed
- **Progress Photos** (optional)

### Streak System
- **Daily Check-ins**: Automatic when logging food/workout
- **Streak Counter**: Consecutive days
- **Streak Rewards**: Badges at milestones (7, 30, 100 days)
- **Streak Recovery**: Miss one day allowance

---

## ⚙️ SETTINGS & CUSTOMIZATION

### Settings Screen (`settings_screen.dart`)

#### Account Management
- Profile information
- Change password
- Email preferences
- Social account linking

#### App Preferences
- **Language**: English/French toggle
- **Units**: Metric/Imperial
- **Notifications**:
  - Meal reminders
  - Workout reminders
  - Water reminders
  - Progress updates

#### Goals & Targets
- Update calorie target
- Adjust macros
- Change weight goal
- Modify activity level

#### Data Management
- Export data
- Delete account
- Privacy settings
- Clear cache

---

## 🔄 OFFLINE MODE

### Offline Capabilities
- **Cached Data**: Recent meals, exercises, workouts
- **Offline Queue**: Actions saved for sync
- **Limited Features**:
  - Can log workouts
  - Can add manual food entries
  - Cannot use AI scanner
  - Cannot access online recipes

### Sync Process
- Automatic sync on reconnection
- Conflict resolution
- Progress indication
- Error handling with retry

---

## 📱 USER INTERACTION PATTERNS

### Navigation
- **Bottom Navigation Bar**: Main sections (Dashboard, Nutrition, Sport, Progress, Settings)
- **Floating Action Button**: Quick add actions
- **Swipe Gestures**: Navigate between dates in journals
- **Pull to Refresh**: Update data in lists

### Data Entry
- **Smart Defaults**: Pre-filled with common values
- **Quick Actions**: One-tap for frequent tasks
- **Batch Operations**: Multi-select for bulk actions
- **Undo Options**: Recent action reversal

### Feedback Mechanisms
- **Visual Feedback**:
  - Progress animations
  - Success checkmarks
  - Loading indicators
- **Haptic Feedback**: On important actions
- **Toast Messages**: Quick status updates
- **Bottom Sheets**: Contextual actions

### Personalization
- **Smart Suggestions**: Based on history
- **Frequent Foods**: Quick access list
- **Recent Workouts**: Easy re-selection
- **Favorite Recipes**: Bookmarking system

---

## 🎯 KEY USER FLOWS

### Daily Routine Flow
1. **Morning**:
   - Open app → Check daily goals
   - Log breakfast via AI scanner
   - Review nutrition targets

2. **Pre-Workout**:
   - Check workout plan
   - Log pre-workout snack
   - Start workout session

3. **Post-Workout**:
   - Complete workout
   - Log post-workout meal
   - Update water intake

4. **Evening**:
   - Log dinner
   - Review daily summary
   - Check tomorrow's plan

### Weekly Planning Flow
1. Review previous week's progress
2. Adjust goals if needed
3. Plan workout schedule
4. Prepare meal plans
5. Set weekly challenges

---

## 🚨 ERROR HANDLING & EDGE CASES

### Common Scenarios
- **No Internet**: Offline mode activation
- **Camera Permission Denied**: Manual entry fallback
- **Food Not Found**: Custom creation option
- **Sync Conflicts**: User choice resolution
- **Invalid Data**: Validation messages

### Recovery Paths
- Clear error messages
- Suggested actions
- Alternative methods
- Support contact option

---

## 📈 METRICS & ANALYTICS

### User Engagement Tracking
- Daily active users
- Feature usage statistics
- Session duration
- Retention rates
- Goal completion rates

### Performance Metrics
- App load time
- API response times
- Camera processing speed
- Sync efficiency

---

## 🔮 FUTURE ENHANCEMENTS (Identified Opportunities)

### Nutrition
- Meal planning wizard
- Restaurant menu integration
- Social meal sharing
- Nutrition coaching tips

### Sport
- Live workout classes
- Exercise form checking (AI)
- Heart rate integration
- Strava/Garmin sync

### Social Features
- Friend challenges
- Community groups
- Progress sharing
- Leaderboards

### AI Enhancements
- Personalized recommendations
- Predictive goal adjustments
- Smart meal suggestions
- Workout optimization