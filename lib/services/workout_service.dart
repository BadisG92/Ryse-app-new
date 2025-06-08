import '../models/sport_models.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  final List<WorkoutProgram> _customPrograms = [];
  final List<Function(WorkoutProgram)> _listeners = [];

  List<WorkoutProgram> get customPrograms => List.unmodifiable(_customPrograms);

  void addProgram(WorkoutProgram program) {
    _customPrograms.add(program);
    _notifyListeners(program);
  }

  void addListener(Function(WorkoutProgram) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(WorkoutProgram) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(WorkoutProgram program) {
    for (final listener in _listeners) {
      listener(program);
    }
  }
} 