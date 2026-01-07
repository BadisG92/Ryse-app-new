/// Models for Coach Chat feature
/// Supports multi-conversation chat with AI Coach Ryze

/// Message role enum
enum MessageRole {
  user,
  assistant,
}

/// Coach Conversation model
/// Represents a single chat conversation with the coach
class CoachConversation {
  final String id;
  final String userId;
  final String? title;
  final DateTime startedAt;
  final DateTime lastMessageAt;
  final bool isActive;
  final int messageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CoachConversation({
    required this.id,
    required this.userId,
    this.title,
    required this.startedAt,
    required this.lastMessageAt,
    this.isActive = true,
    this.messageCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Preview text for conversation list
  String get displayTitle => title ?? 'Nouvelle conversation';

  /// Check if conversation was updated today
  bool get isToday {
    final now = DateTime.now();
    return lastMessageAt.year == now.year &&
        lastMessageAt.month == now.month &&
        lastMessageAt.day == now.day;
  }

  /// Format last message time for display
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(lastMessageAt);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inHours < 1) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (isToday) {
      return '${lastMessageAt.hour.toString().padLeft(2, '0')}:${lastMessageAt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[lastMessageAt.weekday - 1];
    } else {
      return '${lastMessageAt.day}/${lastMessageAt.month}';
    }
  }

  /// Factory: Create from JSON (Supabase response)
  factory CoachConversation.fromJson(Map<String, dynamic> json) {
    return CoachConversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      startedAt: DateTime.parse(json['started_at'] as String),
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      messageCount: json['message_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'started_at': startedAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'is_active': isActive,
      'message_count': messageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create insert data (without id, let DB generate)
  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'title': title,
      'is_active': isActive,
    };
  }

  /// Copy with modifications
  CoachConversation copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? startedAt,
    DateTime? lastMessageAt,
    bool? isActive,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      startedAt: startedAt ?? this.startedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      isActive: isActive ?? this.isActive,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Coach Message model
/// Represents a single message in a conversation
class CoachMessage {
  final String id;
  final String conversationId;
  final String userId;
  final MessageRole role;
  final String content;
  final int tokensUsed;
  final DateTime createdAt;

  CoachMessage({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.content,
    this.tokensUsed = 0,
    required this.createdAt,
  });

  /// Check if this is a user message
  bool get isUser => role == MessageRole.user;

  /// Check if this is an assistant (coach) message
  bool get isAssistant => role == MessageRole.assistant;

  /// Format time for display
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Factory: Create from JSON (Supabase response)
  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      tokensUsed: json['tokens_used'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role.name,
      'content': content,
      'tokens_used': tokensUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create insert data (without id, let DB generate)
  Map<String, dynamic> toInsertJson() {
    return {
      'conversation_id': conversationId,
      'user_id': userId,
      'role': role.name,
      'content': content,
      'tokens_used': tokensUsed,
    };
  }

  /// Copy with modifications
  CoachMessage copyWith({
    String? id,
    String? conversationId,
    String? userId,
    MessageRole? role,
    String? content,
    int? tokensUsed,
    DateTime? createdAt,
  }) {
    return CoachMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      content: content ?? this.content,
      tokensUsed: tokensUsed ?? this.tokensUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Factory: Create a temporary user message (before sending)
  factory CoachMessage.temporary({
    required String conversationId,
    required String userId,
    required String content,
  }) {
    return CoachMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      userId: userId,
      role: MessageRole.user,
      content: content,
      tokensUsed: 0,
      createdAt: DateTime.now(),
    );
  }

  /// Factory: Create a streaming assistant message (during response)
  factory CoachMessage.streaming({
    required String conversationId,
    required String userId,
    String content = '',
  }) {
    return CoachMessage(
      id: 'streaming_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      userId: userId,
      role: MessageRole.assistant,
      content: content,
      tokensUsed: 0,
      createdAt: DateTime.now(),
    );
  }
}

/// User Coach Preferences model
/// Stores learned preferences from conversations
class UserCoachPreferences {
  final String id;
  final String userId;
  final List<String> allergies;
  final List<String> dietaryRestrictions;
  final List<String> foodPreferences;
  final List<String> fitnessConstraints;
  final List<String> preferredWorkoutTimes;
  final List<String> customNotes;
  final String? onboardingInsights; // Insights from onboarding chat
  final DateTime? lastExtractionAt;
  final int extractionCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserCoachPreferences({
    required this.id,
    required this.userId,
    this.allergies = const [],
    this.dietaryRestrictions = const [],
    this.foodPreferences = const [],
    this.fitnessConstraints = const [],
    this.preferredWorkoutTimes = const [],
    this.customNotes = const [],
    this.onboardingInsights,
    this.lastExtractionAt,
    this.extractionCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if preferences are empty
  bool get isEmpty =>
      allergies.isEmpty &&
      dietaryRestrictions.isEmpty &&
      foodPreferences.isEmpty &&
      fitnessConstraints.isEmpty &&
      preferredWorkoutTimes.isEmpty &&
      customNotes.isEmpty &&
      (onboardingInsights == null || onboardingInsights!.isEmpty);

  /// Get all preferences as a formatted string for prompt injection
  String toPromptString() {
    final parts = <String>[];

    // Onboarding insights are prioritized (motivation, objectives, etc.)
    if (onboardingInsights != null && onboardingInsights!.isNotEmpty) {
      parts.add('=== CONTEXTE UTILISATEUR (onboarding) ===\n$onboardingInsights');
    }
    if (allergies.isNotEmpty) {
      parts.add('Allergies: ${allergies.join(", ")}');
    }
    if (dietaryRestrictions.isNotEmpty) {
      parts.add('Restrictions alimentaires: ${dietaryRestrictions.join(", ")}');
    }
    if (foodPreferences.isNotEmpty) {
      parts.add('Préférences alimentaires: ${foodPreferences.join(", ")}');
    }
    if (fitnessConstraints.isNotEmpty) {
      parts.add('Contraintes fitness: ${fitnessConstraints.join(", ")}');
    }
    if (preferredWorkoutTimes.isNotEmpty) {
      parts.add('Horaires préférés: ${preferredWorkoutTimes.join(", ")}');
    }
    if (customNotes.isNotEmpty) {
      parts.add('Notes: ${customNotes.join(", ")}');
    }

    return parts.isEmpty ? 'Aucune préférence enregistrée' : parts.join('\n');
  }

  /// Factory: Create from JSON (Supabase response)
  factory UserCoachPreferences.fromJson(Map<String, dynamic> json) {
    final prefs = json['preferences'] as Map<String, dynamic>? ?? {};

    return UserCoachPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      allergies: List<String>.from(prefs['allergies'] ?? []),
      dietaryRestrictions: List<String>.from(prefs['dietary_restrictions'] ?? []),
      foodPreferences: List<String>.from(prefs['food_preferences'] ?? []),
      fitnessConstraints: List<String>.from(prefs['fitness_constraints'] ?? []),
      preferredWorkoutTimes: List<String>.from(prefs['preferred_workout_times'] ?? []),
      customNotes: List<String>.from(prefs['custom_notes'] ?? []),
      onboardingInsights: prefs['onboarding_insights'] as String?,
      lastExtractionAt: json['last_extraction_at'] != null
          ? DateTime.parse(json['last_extraction_at'] as String)
          : null,
      extractionCount: json['extraction_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'preferences': {
        'allergies': allergies,
        'dietary_restrictions': dietaryRestrictions,
        'food_preferences': foodPreferences,
        'fitness_constraints': fitnessConstraints,
        'preferred_workout_times': preferredWorkoutTimes,
        'custom_notes': customNotes,
      },
      'last_extraction_at': lastExtractionAt?.toIso8601String(),
      'extraction_count': extractionCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Factory: Create empty preferences for a user
  factory UserCoachPreferences.empty({required String userId}) {
    return UserCoachPreferences(
      id: '',
      userId: userId,
      createdAt: DateTime.now(),
    );
  }

  /// Copy with modifications
  UserCoachPreferences copyWith({
    String? id,
    String? userId,
    List<String>? allergies,
    List<String>? dietaryRestrictions,
    List<String>? foodPreferences,
    List<String>? fitnessConstraints,
    List<String>? preferredWorkoutTimes,
    List<String>? customNotes,
    DateTime? lastExtractionAt,
    int? extractionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCoachPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      allergies: allergies ?? this.allergies,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      fitnessConstraints: fitnessConstraints ?? this.fitnessConstraints,
      preferredWorkoutTimes: preferredWorkoutTimes ?? this.preferredWorkoutTimes,
      customNotes: customNotes ?? this.customNotes,
      lastExtractionAt: lastExtractionAt ?? this.lastExtractionAt,
      extractionCount: extractionCount ?? this.extractionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Coach Daily Usage model
/// Tracks daily message count for rate limiting
class CoachDailyUsage {
  final String id;
  final String userId;
  final DateTime usageDate;
  final int messageCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CoachDailyUsage({
    required this.id,
    required this.userId,
    required this.usageDate,
    this.messageCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if this is today's usage
  bool get isToday {
    final now = DateTime.now();
    return usageDate.year == now.year &&
        usageDate.month == now.month &&
        usageDate.day == now.day;
  }

  /// Factory: Create from JSON (Supabase response)
  factory CoachDailyUsage.fromJson(Map<String, dynamic> json) {
    return CoachDailyUsage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      usageDate: DateTime.parse(json['usage_date'] as String),
      messageCount: json['message_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'usage_date': usageDate.toIso8601String().substring(0, 10),
      'message_count': messageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Copy with modifications
  CoachDailyUsage copyWith({
    String? id,
    String? userId,
    DateTime? usageDate,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachDailyUsage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      usageDate: usageDate ?? this.usageDate,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Rate limit status for coach chat
class CoachRateLimitStatus {
  final int messagesUsed;
  final int messagesLimit;
  final bool isPremium;
  final bool canSendMessage;

  CoachRateLimitStatus({
    required this.messagesUsed,
    required this.messagesLimit,
    required this.isPremium,
    required this.canSendMessage,
  });

  /// Remaining messages
  int get remaining => isPremium ? -1 : (messagesLimit - messagesUsed).clamp(0, messagesLimit);

  /// Usage percentage (0-100)
  double get usagePercentage => isPremium ? 0 : (messagesUsed / messagesLimit * 100).clamp(0, 100);

  /// Display text for UI
  String get displayText {
    if (isPremium) return 'Illimité';
    return '$messagesUsed/$messagesLimit';
  }

  /// Factory: Create for premium user
  factory CoachRateLimitStatus.premium() {
    return CoachRateLimitStatus(
      messagesUsed: 0,
      messagesLimit: -1,
      isPremium: true,
      canSendMessage: true,
    );
  }

  /// Factory: Create for free user
  factory CoachRateLimitStatus.free({
    required int messagesUsed,
    int messagesLimit = 5,
  }) {
    return CoachRateLimitStatus(
      messagesUsed: messagesUsed,
      messagesLimit: messagesLimit,
      isPremium: false,
      canSendMessage: messagesUsed < messagesLimit,
    );
  }
}
