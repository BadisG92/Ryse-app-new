# Ryse App - AI-Powered Fitness & Nutrition Coach

## Quick Commands
```bash
# Development
flutter run                    # Run app in debug mode
flutter run --release         # Run app in release mode
flutter build apk            # Build Android APK
flutter build ios            # Build iOS app
flutter build appbundle      # Build for Play Store

# Testing & Analysis
flutter test                 # Run unit tests
flutter analyze              # Static code analysis
flutter doctor              # Check environment setup

# Maintenance
flutter clean               # Clean build artifacts
flutter pub get             # Install dependencies
flutter pub upgrade         # Update dependencies
flutter pub outdated        # Check for outdated packages

# Database Operations
npx supabase db dump        # Export database schema
```

## Project Architecture

### Core Directories
```
lib/
├── bottom_sheets/          # Bottom sheet UI components
├── components/             # Reusable UI components
│   ├── ui/                # Basic UI widgets
│   └── shared/            # Shared components
├── config/                # App configuration
├── core/                  # Core architecture
│   ├── infrastructure/    # Infrastructure layer
│   ├── data/             # Data layer
│   └── domain/           # Domain layer
├── features/             # Feature modules
├── models/               # Data models
├── pages/                # Main app pages
├── providers/            # State management
├── screens/              # Screen implementations
├── services/             # Business logic services
└── utils/                # Utility functions
```

## 📱 iOS Widget

### Smart Meal Widget (NEW!)
**Le widget iOS intelligent qui transforme l'expérience utilisateur**

- **Détection Contextuelle**: Affiche automatiquement le bon repas selon l'heure
  - 7h-10h → Petit-déjeuner 🌅
  - 11h-14h → Déjeuner 🌤️
  - 18h-21h → Dîner 🌙
- **Actions Rapides**: 5 boutons pour ajouter rapidement (📝 Manuel, 📸 Scanner, 🔍 Barcode, 🍳 Recettes, 💬 Chat)
- **Progression Temps Réel**: Visualisation instantanée des calories
- **2 Tailles**: Small (Lock Screen) et Medium (Home Screen)
- **Deep Links Intelligents**: Navigation directe vers l'app avec contexte pré-sélectionné

**Documentation**:
- [`WIDGET_INSTALLATION_GUIDE.md`](WIDGET_INSTALLATION_GUIDE.md) - Guide complet d'installation
- [`WIDGET_README.md`](WIDGET_README.md) - Documentation technique
- [`WIDGET_IMPLEMENTATION_SUMMARY.md`](WIDGET_IMPLEMENTATION_SUMMARY.md) - Résumé de l'implémentation

**Fichiers**:
- `lib/services/widget_deep_link_handler.dart` - Gestion des deep links
- `lib/services/meal_widget_data_provider.dart` - Synchronisation données
- `ios/RyseMealWidget/RyseMealWidget.swift` - Widget iOS

## Key Features & Functionality

### 1. Nutrition Management
- **AI Food Scanner**: Camera-based food recognition using Google Vision API
- **Barcode Scanner**: Product identification via barcode with manual entry option
  - Tap-to-scan functionality with Google Vision API
  - Manual barcode entry dialog (without test codes in production)
  - OpenFoodFacts integration for product nutrition data
  - Editable nutritional values (per 100g)
  - Auto-save to custom foods database with duplicate detection
  - Disclaimer for OpenFoodFacts data accuracy
- **Manual Food Entry**: Search and add foods manually
- **Recipe Management**: Create, save, and track recipes
- **Meal Planning**: Organize meals (breakfast, lunch, dinner, snacks)
- **Calorie Tracking**: Daily calorie intake monitoring
- **Macro Tracking**: Proteins, carbs, fats, fiber tracking
- **Water Intake**: Hydration tracking with reminders
- **Custom Foods**: Create personalized food entries
- **Food Localization**: Multi-language food database (EN/FR)

### 2. Sport & Fitness
- **Workout Tracking**: Log strength training sessions
- **Cardio Sessions**: Track running, cycling, swimming, etc.
- **HIIT Workouts**: High-intensity interval training support
- **Exercise Library**: Comprehensive exercise database
- **Calorie Burn**: Activity-based calorie calculation
- **Progress Tracking**: Visual progress charts and statistics
- **Workout History**: Complete exercise history log
- **Offline Mode**: Continue workouts without internet
- **Sport Dashboard**: Overview of fitness activities

### 3. User Progress & Goals
- **Weight Evolution**: Track weight changes over time
- **Body Measurements**: Track various body metrics
- **Goal Setting**: Set and track fitness goals
- **Streak System**: Maintain daily activity streaks
- **Achievement Badges**: Gamification elements
- **Progress Charts**: Visual representation of progress
- **Global Dashboard**: Comprehensive progress overview

### 4. AI & Intelligence
- **Gemini Integration**: AI-powered food analysis
- **Google Vision API**: Image recognition for food
- **Smart Recommendations**: Personalized meal suggestions
- **Nutritional Analysis**: Automatic nutrient calculation
- **OpenFoodFacts**: Product database integration

## Core Services

### Authentication & User Management
- `auth_service.dart`: Supabase authentication, social login
- `user_model.dart`: User profile management

### Nutrition Services
- `food_entries_service.dart`: Food entry CRUD operations
- `calorie_target_service.dart`: Daily calorie goals
- `recipe_service.dart`: Recipe management
- `water_service.dart`: Water intake tracking
- `localized_food_service.dart`: Multi-language food data
- `openfoodfacts_service.dart`: Product database API integration
- `barcode_detection_service.dart`: Barcode scanning with Google Vision API and checksum validation

### Sport & Fitness Services
- `cardio_service.dart`: Cardio activity tracking
- `cardio_session_manager.dart`: Session state management
- `workout_service.dart`: Strength training workouts
- `workout_cache_service.dart`: Offline workout caching
- `sport_dashboard_service.dart`: Fitness analytics
- `calorie_burn_service.dart`: Energy expenditure calculation
- `offline_workout_service.dart`: Offline mode support

### AI & Analysis Services
- `ai_analysis_service.dart`: AI-powered food recognition
- `gemini_analysis_service_v2.dart`: Enhanced Gemini integration
- `recipe_image_service.dart`: Recipe image processing

### Progress & Goals
- `progress_service_v2.dart`: Progress tracking system
- `weight_service.dart`: Weight management
- `streak_service.dart`: Streak maintenance
- `unified_calorie_system.dart`: Calorie calculations

### Infrastructure Services
- `database_service.dart`: Supabase database operations
- `fast_cache_service.dart`: Performance caching
- `offline_queue.dart`: Offline operation queue
- `dashboard_service.dart`: Dashboard data aggregation
- `localization_service.dart`: App internationalization
- `permission_service.dart`: Device permissions
- `location_service.dart`: Geolocation features

## Main Screens

### Authentication
- `login_screen.dart`: User login with social options
- `signup_screen.dart`: New user registration
- `forgot_password_screen.dart`: Password recovery

### Nutrition Screens
- `ai_scanner_screen.dart`: Camera-based food scanner
- `barcode_scanner_screen.dart`: Barcode scanning screen
  - Live camera preview with tap-to-focus
  - Animated scan zone overlay
  - Tap-to-scan button for instant capture
  - Manual barcode entry dialog
  - Product details view with editable nutrition values
  - OpenFoodFacts data disclaimer
  - Integration with meal selection and custom foods
- `manual_food_entry_screen.dart`: Manual food search/add
- `recipe_details_screen.dart`: Recipe information
- `select_recipe_screen.dart`: Recipe selection

### Sport Screens
- `workout_session_screen.dart`: Active workout tracking
- `cardio_tracking_screen.dart`: Cardio activity monitor
- `manual_cardio_entry_screen.dart`: Manual cardio entry
- `hiit_session_screen.dart`: HIIT workout interface
- `hiit_config_screen.dart`: HIIT configuration

### Progress & Settings
- `weight_evolution_screen.dart`: Weight history charts
- `settings_screen.dart`: App configuration
- `complete_localization_demo.dart`: Language testing

## Code Style Guidelines

### Flutter/Dart Conventions
```dart
// Use null safety
String? nullableString;
String nonNullString = 'value';

// Prefer const constructors
const MyWidget({Key? key}) : super(key: key);

// Use async/await
Future<void> fetchData() async {
  try {
    final result = await apiCall();
    // Handle result
  } catch (e) {
    // Handle error
  }
}

// Meaningful variable names
final userCalorieTarget = 2000; // Good
final ct = 2000; // Bad
```

### File Organization
- One widget per file for screens
- Group related widgets in component files
- Keep services focused and single-purpose
- Use models for data structures

## Detailed Feature Descriptions

### Barcode Scanner (`barcode_scanner_screen.dart`)

The barcode scanner provides a professional scanning experience with multiple entry methods:

#### Features
1. **Camera-based Scanning**
   - Live camera preview with high resolution
   - Tap-to-focus and tap-to-expose functionality
   - Animated scan zone with visual feedback
   - Tap-to-scan button for instant capture

2. **Manual Entry**
   - Manual barcode input dialog for difficult-to-scan products
   - Clean interface without test barcodes in production
   - Real-time validation and search

3. **Product Display**
   - OpenFoodFacts integration for product data
   - Product image with fallback placeholder
   - Brand, quantity, and packaging information
   - Nutritional values (calories, proteins, carbs, fats)

4. **Editable Nutrition Values**
   - Edit button to modify nutritional values per 100g
   - Real-time recalculation based on quantity
   - Validation and formatting

5. **Custom Foods Integration**
   - Auto-save scanned products to user's custom foods
   - Duplicate detection via barcode
   - Optional save with user confirmation
   - Success/error feedback

6. **Data Accuracy**
   - OpenFoodFacts disclaimer displayed
   - User education about community-sourced data
   - Ability to edit incorrect values

#### Technical Details
- **Service**: `barcode_detection_service.dart` for Google Vision API
- **Product Database**: `openfoodfacts_service.dart` for nutrition data
- **Storage**: Custom foods saved to `custom_foods` table with barcode reference
- **Validation**: EAN-13/EAN-8 checksum validation
- **User Flow**: Scan → Display → Edit (optional) → Save to custom foods → Add to meal

#### User Experience
- Smooth transitions between states (scanning, loading, results)
- Loading indicators during API calls
- Error handling with user-friendly messages
- Snackbar notifications for actions
- Integration with meal selection bottom sheet

## Database Schema (Supabase)

### Key Tables
- `users`: User profiles and settings
- `food_entries`: Daily food consumption
- `recipes`: User recipes
- `workout_sessions`: Exercise sessions
- `cardio_sessions`: Cardio activities
- `water_entries`: Water intake logs
- `weight_entries`: Weight tracking
- `user_goals`: Fitness objectives
- `localized_foods`: Multi-language food database
- `localized_exercises`: Multi-language exercise database
- `custom_foods`: User-created custom foods (includes scanned barcodes)
  - `barcode` field: Stores product barcode for duplicate detection
  - `origin` field: Marks source as 'barcode', 'manual', etc.

### CASCADE Delete Configuration

**IMPORTANT**: All user data is automatically deleted when a user account is deleted.

The database uses `ON DELETE CASCADE` constraints to ensure data integrity and GDPR compliance:

- **User Relations (17+ tables)**: All tables with `user_id` have CASCADE delete
  - `food_entries`, `custom_foods`, `workout_sessions`, `cardio_sessions`, etc.
  - When a user is deleted from `auth.users`, all their data is automatically removed

- **Table Relations**: Child records are deleted when parent records are deleted
  - `workout_sessions` → `workout_exercises` → `exercise_sets` (CASCADE)
  - `recipes` → `recipe_ingredients` (CASCADE)
  - `cardio_sessions` → `location_points` (CASCADE)
  - `gps_tracking_sessions` → `gps_tracking_points` (CASCADE)

- **Preserved History**: Some relations use `SET NULL` to keep historical data
  - `food_entries.food_id` (SET NULL if food deleted, preserves nutrition entry)
  - `hiit_sessions.workout_id` (SET NULL to keep session data)
  - `content_reports.reviewed_by` (SET NULL to keep report if reviewer deleted)

**Migrations**:
- `20250130_add_user_cascade_delete.sql`: User → Tables cascade
- `20250130_add_table_relation_cascades.sql`: Table → Table relations
- `verify_cascade.sql`: Verification script for CASCADE constraints
- See `CASCADE_MIGRATION_README.md` for detailed documentation

## Testing Strategy
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/database_service_test.dart

# Run with coverage
flutter test --coverage
```

## Environment Setup

### Prerequisites
- Flutter SDK (stable channel)
- Dart SDK (comes with Flutter)
- Android Studio / Xcode
- VS Code with Flutter extension
- Supabase CLI (for database operations)

### Configuration Files
- `pubspec.yaml`: Dependencies and app metadata
- `lib/config/supabase_config.dart`: Supabase credentials
- `lib/config/gemini_config.dart`: Gemini AI settings
- `lib/config/google_vision_config.dart`: Vision API config

## Git Workflow

### Branch Strategy
- `main`: Production-ready code
- `version_1.0.0_log`: Current development branch
- Feature branches: `feature/description`
- Bug fixes: `fix/description`

### Commit Convention
```bash
# Feature
feat: add water tracking widget

# Bug fix
fix: resolve calorie calculation error

# Refactor
refactor: optimize database queries

# Docs
docs: update API documentation
```

## Common Issues & Solutions

### Camera Permissions
- iOS: Must add NSCameraUsageDescription to Info.plist
- Android: Camera permission in AndroidManifest.xml
- Runtime: Use permission_handler package

### Offline Mode
- Workouts cached locally using workout_cache_service
- Offline queue for pending operations
- Sync on reconnection via offline_queue

### Performance Optimization
- Fast cache service for frequent data
- Lazy loading for large lists
- Image optimization for recipes
- Preload service for critical data

## API Integrations

### Supabase
- Authentication & user management
- Real-time database
- File storage for images
- PostgreSQL for structured data

### External APIs
- Google Vision API: Food image recognition
- Gemini AI: Food analysis and recommendations
- OpenFoodFacts: Product nutrition database
- Geocoding: Location-based features

## Deployment Checklist

### Pre-deployment
- [ ] Run flutter analyze
- [ ] Run all tests
- [ ] Test on physical devices
- [ ] Verify camera permissions
- [ ] Check offline mode
- [ ] Test payment flows (if applicable)
- [ ] Review translations

### Build Commands
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release

# Web (if applicable)
flutter build web --release
```

## Monitoring & Analytics

### Performance Monitoring
- `performance_monitor.dart`: App performance tracking
- `app_logger.dart`: Centralized logging

### Error Handling
- Try-catch blocks for all async operations
- Graceful degradation for offline mode
- User-friendly error messages
- Automatic error reporting to backend

## Security Considerations
- Secure storage for sensitive data
- API key protection
- User data encryption
- HTTPS for all network requests
- Input validation on all forms

## Important Notes
- App supports English and French localization
- Optimistic updates for better UX
- Progressive web app support planned
- Regular database migrations via migration_controller
- Comprehensive offline support for core features