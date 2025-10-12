import 'lib/services/workout_voice_service.dart';

void main() {
  final service = WorkoutVoiceService();
  
  print('=== TEST VOICE PARSING ===\n');
  
  // Test cases
  final tests = [
    // Pattern 1: Standard order
    '10 reps 80 kg',
    '10 repetitions 80 kilos',
    '10 wraps 80 pounds',
    '10 times 20 kg',
    '10 sets 45 lbs',
    '12 fois 75 kilos',
    
    // Pattern 2: Reversed order
    '80 kg 10 reps',
    '180 pounds 10 times',
    '45 lbs 12 wraps',
    '75 kilos 10 fois',
    
    // Pattern 3: Reps only
    '10 reps',
    '12 times',
    '10 wraps',
    '10 repetition',
    '15 fois',
    
    // Pattern 4: Numbers only
    '10 80',
    '12 75',
    
    // Pattern 5: With noise words
    '10 reps and 20 kg',
    '10 repetition and 20 kg',
    '10 wraps and 15 kg',
    '10 of 20 kg',
    '10 times with 80 pounds',
    
    // Edge cases
    '',
    'blabla',
    'do you have a van',
    '10',
    'reps',
    '10 reps and',
    'and 20 kg',
  ];
  
  int passed = 0;
  int failed = 0;
  
  for (final test in tests) {
    final result = service.parseVoiceInput(test);
    if (result != null && result.hasData) {
      passed++;
      print('✅ "$test" → ${result.reps ?? 0} reps, ${result.weight ?? 0.0}');
    } else {
      failed++;
      print('❌ "$test" → NULL');
    }
  }
  
  print('\n=== SUMMARY ===');
  print('Passed: $passed/${tests.length}');
  print('Failed: $failed/${tests.length}');
  print('Success rate: ${(passed / tests.length * 100).toStringAsFixed(1)}%');
}
