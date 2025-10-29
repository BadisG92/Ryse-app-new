# Network Error Handling - Ryze App

## Problem
The app was experiencing `ClientException: Failed to fetch` errors when making Supabase API calls. These errors occur when:
- Network connection is lost or weak
- User is in airplane mode
- CORS issues (on web)
- Connection timeouts
- Server temporarily unavailable

## Solution Implemented

### 1. Centralized Error Handler (`lib/services/supabase_error_handler.dart`)

Created a robust error handling service that:

- **Detects network errors**: Identifies `ClientException`, timeouts, and connection failures
- **Automatic retry mechanism**: Retries failed network requests up to 2 times with 500ms delay
- **Fallback values**: Returns safe default values when network is unavailable
- **User-friendly messages**: Converts technical errors into understandable messages
- **Comprehensive logging**: Detailed logs for debugging

#### Key Features:

```dart
SupabaseErrorHandler.executeWithRetry(
  operation: () async {
    // Your Supabase call
  },
  operationName: 'operationName',
  fallbackValue: defaultValue, // Returned if all retries fail
  maxRetries: 2,
  retryDelay: Duration(milliseconds: 500),
)
```

### 2. Updated Services

Applied the error handler to critical services:

#### SportDashboardService
- `_getDailyActivitiesData`: Returns empty lists on network failure
- `_getRecentWorkoutsData`: Returns empty workout history on failure

#### WeightService
- `getWeightProgress`: Returns default 70kg weight profile on network failure

#### WaterService
- `getDailyWaterProgress`: Returns null on network failure
- `getTodayWaterEntries`: Returns empty list on network failure
- `getWaterHistory`: Returns empty history on network failure

### 3. Error Types Handled

The handler detects and manages:
- `ClientException` (HTTP client errors)
- Network timeouts
- Connection refused/closed
- "Failed to fetch" errors (browser)
- Temporary server unavailability

### 4. Retry Strategy

**When retries happen:**
- Network-related errors only
- Temporary failures
- Connection timeouts

**When retries DON'T happen:**
- Authentication errors (401, 403)
- Not found errors (404)
- Server errors (500) - could be retried but might indicate bigger issues
- Data validation errors

**Retry configuration:**
- **Max attempts**: 3 (initial + 2 retries)
- **Delay between retries**: 500ms
- **Exponential backoff**: Not implemented (could be added if needed)

## Usage Examples

### Example 1: Simple query with fallback
```dart
final data = await SupabaseErrorHandler.executeWithRetry(
  operation: () async {
    return await _client.from('table').select();
  },
  operationName: 'fetchData',
  fallbackValue: [], // Empty list if network fails
);
```

### Example 2: Complex operation with retry
```dart
final result = await SupabaseErrorHandler.executeWithRetry(
  operation: () async {
    final response = await _client
        .from('users')
        .select('weight, target_weight')
        .eq('user_id', userId)
        .single();

    return processData(response);
  },
  operationName: 'getUserWeight',
  fallbackValue: defaultWeightData,
  maxRetries: 3, // Custom retry count
);
```

## Benefits

1. **Better UX**: App doesn't crash when network fails
2. **Automatic recovery**: Transient network issues are handled automatically
3. **Graceful degradation**: App shows cached/default data instead of errors
4. **Debugging**: Detailed logs help identify network issues
5. **Maintainability**: Centralized error handling logic

## Testing

To test network error handling:

1. **Airplane mode**: Enable airplane mode and navigate through the app
2. **Weak connection**: Use network throttling tools (Chrome DevTools)
3. **Offline mode**: Disconnect from internet completely
4. **Timeout simulation**: Add delays to Supabase functions

Expected behavior:
- No crashes or unhandled exceptions
- Fallback data displayed
- Clear log messages indicating retry attempts
- User-friendly error messages (if needed)

## Future Improvements

Potential enhancements:
1. **Exponential backoff**: Increase delay between retries
2. **Circuit breaker**: Stop retrying if server is consistently down
3. **Offline queue**: Queue operations for later when network returns
4. **Network status monitoring**: Detect connectivity changes
5. **User notifications**: Inform users about network issues
6. **Metrics**: Track error rates and retry success rates

## Related Files

- `lib/services/supabase_error_handler.dart` - Main error handler
- `lib/services/sport_dashboard_service.dart` - Sport data with error handling
- `lib/services/weight_service.dart` - Weight tracking with error handling
- `lib/services/water_service.dart` - Water tracking with error handling
- `lib/services/database_service.dart` - General database operations (consider updating)
- `lib/services/offline_workout_service.dart` - Existing offline support

## Notes

- The app already has some offline support via `offline_workout_service.dart`
- Consider extending error handling to other services that make Supabase calls
- Monitor logs to identify patterns in network failures
- Adjust retry parameters based on real-world usage

## Error Messages

User-friendly error messages by error type:

| Error Type | User Message |
|------------|--------------|
| Network/timeout | "Impossible de se connecter au serveur. Vérifiez votre connexion internet." |
| 401/unauthorized | "Session expirée. Veuillez vous reconnecter." |
| 403/forbidden | "Accès refusé. Vous n'avez pas les permissions nécessaires." |
| 404/not found | "Ressource introuvable." |
| 500/server error | "Erreur serveur temporaire. Réessayez dans quelques instants." |
| Other | "Une erreur est survenue. Veuillez réessayer." |

## Debugging

When debugging network issues, check logs for:

```
🔄 [operationName] Tentative 1/3
🌐 [operationName] Erreur réseau détectée: ClientException...
⏳ [operationName] Nouvelle tentative dans 500 ms...
✅ [operationName] Succès après 2 tentatives
```

Or:

```
❌ [operationName] Échec définitif après 3 tentatives
⚠️ [operationName] Utilisation de la valeur de fallback
```
