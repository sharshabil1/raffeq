class User {
  final String? id;
  final String email;

  User({this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? json['user_id']?.toString(),
      email: json['email'] ?? '',
    );
  }
}

class UserProfile {
  final Map<String, dynamic>? baselineState;
  final dynamic currentFocus;
  final Map<String, dynamic>? onboardingAnswers;

  UserProfile({this.baselineState, this.currentFocus, this.onboardingAnswers});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      baselineState: json['baseline_state'] is Map<String, dynamic>
          ? json['baseline_state']
          : null,
      currentFocus: json['current_focus'],
      onboardingAnswers: json['onboarding_answers'] is Map<String, dynamic>
          ? json['onboarding_answers']
          : (json['onboarding_data'] is Map<String, dynamic>
              ? json['onboarding_data']
              : null),
    );
  }

  bool get hasCompletedOnboarding {
    if (onboardingAnswers == null) return false;
    final map = onboardingAnswers!;
    if (map.isEmpty) return false;
    for (final val in map.values) {
      if (val != null && val.toString().isNotEmpty) {
        if (val is List && val.isEmpty) continue;
        if (val is Map && val.isEmpty) continue;
        return true;
      }
    }
    return false;
  }

  List<String> get focusTags {
    final tags = <String>[];
    final focus = currentFocus ?? baselineState;
    if (focus == null) return tags;

    if (focus is List) {
      for (final item in focus) {
        if (item != null) tags.add(item.toString());
      }
    } else if (focus is Map) {
      for (final val in focus.values) {
        if (val is List) {
          for (final sub in val) {
            if (sub != null) tags.add(sub.toString());
          }
        } else if (val != null) {
          tags.add(val.toString());
        }
      }
    } else {
      tags.add(focus.toString());
    }
    return tags;
  }
}

class OnboardingQuestion {
  final String key;
  final String question;
  final bool isMulti;
  final List<String> options;

  OnboardingQuestion({
    required this.key,
    required this.question,
    required this.isMulti,
    required this.options,
  });
}

class JobResultModel {
  final String id;
  final String jobType;
  final String status;
  final String? textPrompt;
  final String? transcription;
  final String summary;
  final String sentiment;
  final List<String> keywords;
  final String createdAt;
  final String? completedAt;

  JobResultModel({
    required this.id,
    required this.jobType,
    required this.status,
    this.textPrompt,
    this.transcription,
    required this.summary,
    required this.sentiment,
    required this.keywords,
    required this.createdAt,
    this.completedAt,
  });

  factory JobResultModel.fromJson(dynamic json) {
    if (json is String) {
      return JobResultModel(
        id: '',
        jobType: 'text',
        status: 'completed',
        summary: json,
        sentiment: 'neutral',
        keywords: [],
        createdAt: '',
      );
    }

    if (json is Map<String, dynamic>) {
      final rawId = json['id'] ?? json['job_id'] ?? '';
      final rawType = json['job_type'] ?? 'text';
      final rawStatus = json['status'] ?? 'completed';
      final textPrompt = json['text_prompt']?.toString();
      final transcription = json['transcription']?.toString();
      final createdAt = json['created_at']?.toString() ?? '';
      final completedAt = json['completed_at']?.toString();

      String summaryText = '';
      String sentimentVal = 'neutral';
      List<String> keywordsList = [];

      final insights = json['insights'];
      if (insights is Map<String, dynamic>) {
        summaryText = insights['summary']?.toString() ?? '';
        sentimentVal = insights['sentiment']?.toString() ?? 'neutral';
        if (insights['keywords'] is List) {
          keywordsList = (insights['keywords'] as List)
              .map((e) => e.toString())
              .toList();
        }
      }

      if (summaryText.isEmpty) {
        summaryText = json['summary']?.toString() ??
            transcription ??
            textPrompt ??
            'Analysis complete.';
      }

      return JobResultModel(
        id: rawId.toString(),
        jobType: rawType.toString(),
        status: rawStatus.toString(),
        textPrompt: textPrompt,
        transcription: transcription,
        summary: summaryText,
        sentiment: sentimentVal.toLowerCase(),
        keywords: keywordsList,
        createdAt: createdAt,
        completedAt: completedAt,
      );
    }

    return JobResultModel(
      id: '',
      jobType: 'text',
      status: 'completed',
      summary: json.toString(),
      sentiment: 'neutral',
      keywords: [],
      createdAt: '',
    );
  }
}

class ChatMessage {
  final String? id;
  final String role; // 'user' or 'assistant'
  final String content;
  final bool isCrisis;
  final Map<String, dynamic>? emergencyResources;
  final String? createdAt;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.isCrisis = false,
    this.emergencyResources,
    this.createdAt,
  });

  factory ChatMessage.fromJson(dynamic json) {
    if (json is String) {
      return ChatMessage(role: 'assistant', content: json);
    }

    if (json is Map<String, dynamic>) {
      final id = json['id']?.toString();
      final role =
          json['role']?.toString() ?? (json['is_user'] == true ? 'user' : 'assistant');
      
      // Extract content string directly
      String content = '';
      if (json['content'] != null) {
        content = json['content'].toString();
      } else if (json['coaching_message'] != null) {
        content = json['coaching_message'].toString();
      } else if (json['message'] != null) {
        content = json['message'].toString();
      } else if (json['response'] != null) {
        content = json['response'].toString();
      } else if (json['reply'] != null) {
        content = json['reply'].toString();
      }

      final isCrisis = json['is_crisis'] == true;
      final emergencyResources = json['emergency_resources'] is Map<String, dynamic>
          ? json['emergency_resources'] as Map<String, dynamic>
          : null;
      final createdAt = json['created_at']?.toString();

      return ChatMessage(
        id: id,
        role: role,
        content: content,
        isCrisis: isCrisis,
        emergencyResources: emergencyResources,
        createdAt: createdAt,
      );
    }

    return ChatMessage(role: 'assistant', content: json.toString());
  }
}

class JournalEntry {
  final String id;
  final String jobType;
  final String status;
  final String summary;
  final String? sentiment;
  final String date;

  JournalEntry({
    required this.id,
    required this.jobType,
    required this.status,
    required this.summary,
    this.sentiment,
    required this.date,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['job_id'] ?? '';
    final rawType = json['job_type'] ?? 'text';
    final rawStatus = json['status'] ?? 'completed';
    final rawDate = json['created_at'] ?? json['date'] ?? '';

    String summaryText = '';
    if (json['summary'] != null && json['summary'].toString().isNotEmpty) {
      summaryText = json['summary'].toString();
    } else if (json['text_prompt'] != null) {
      summaryText = json['text_prompt'].toString();
    } else if (json['transcription'] != null) {
      summaryText = json['transcription'].toString();
    } else {
      summaryText = 'Reflection entry';
    }

    final sentiment = json['sentiment']?.toString();

    return JournalEntry(
      id: rawId.toString(),
      jobType: rawType.toString(),
      status: rawStatus.toString(),
      summary: summaryText,
      sentiment: sentiment,
      date: rawDate.toString(),
    );
  }
}

class SupportContact {
  final String name;
  final String phone;
  final String description;
  final String category;
  final String country;
  final String availableHours;

  SupportContact({
    required this.name,
    required this.phone,
    required this.description,
    required this.category,
    required this.country,
    required this.availableHours,
  });

  factory SupportContact.fromJson(Map<String, dynamic> json) {
    return SupportContact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      country: json['country'] ?? '',
      availableHours: json['available_hours'] ?? '',
    );
  }
}

class CopingStrategy {
  final String title;
  final String description;
  final String category;

  CopingStrategy({
    required this.title,
    required this.description,
    required this.category,
  });

  factory CopingStrategy.fromJson(Map<String, dynamic> json) {
    return CopingStrategy(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
    );
  }
}

class SupportResource {
  final List<SupportContact> contacts;
  final List<CopingStrategy> copingStrategies;
  final String disclaimer;

  SupportResource({
    required this.contacts,
    required this.copingStrategies,
    required this.disclaimer,
  });

  factory SupportResource.fromJson(Map<String, dynamic> json) {
    final contactsList = (json['contacts'] as List?)
            ?.map((e) => SupportContact.fromJson(e))
            .toList() ??
        [];
    final strategiesList = (json['coping_strategies'] as List?)
            ?.map((e) => CopingStrategy.fromJson(e))
            .toList() ??
        [];
    return SupportResource(
      contacts: contactsList,
      copingStrategies: strategiesList,
      disclaimer: json['disclaimer'] ?? '',
    );
  }
}

class MoodPoint {
  final String label;
  final double score;

  MoodPoint({required this.label, required this.score});
}
