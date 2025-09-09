enum PollType {
  multipleChoice,
  singleChoice,
  yesNo,
  rating,
  openText,
  wordCloud,
}

enum PollStatus {
  draft,
  active,
  closed,
  archived,
}

class PollOption {
  final String id;
  final String text;
  final int votes;
  final List<String> voterIds;

  PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
    this.voterIds = const [],
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      votes: json['votes'] ?? 0,
      voterIds: List<String>.from(json['voterIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'votes': votes,
      'voterIds': voterIds,
    };
  }

  PollOption copyWith({
    String? id,
    String? text,
    int? votes,
    List<String>? voterIds,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
      voterIds: voterIds ?? this.voterIds,
    );
  }
}

class Poll {
  final String id;
  final String eventId;
  final String? sessionId;
  final String question;
  final String description;
  final PollType type;
  final PollStatus status;
  final List<PollOption> options;
  final bool allowMultipleAnswers;
  final bool isAnonymous;
  final bool showResults;
  final DateTime? startTime;
  final DateTime? endTime;
  final String createdBy;
  final int totalVotes;
  final List<String> voterIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Poll({
    required this.id,
    required this.eventId,
    this.sessionId,
    required this.question,
    this.description = '',
    required this.type,
    this.status = PollStatus.draft,
    this.options = const [],
    this.allowMultipleAnswers = false,
    this.isAnonymous = true,
    this.showResults = true,
    this.startTime,
    this.endTime,
    required this.createdBy,
    this.totalVotes = 0,
    this.voterIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == PollStatus.active;
  bool get isExpired => endTime != null && DateTime.now().isAfter(endTime!);
  bool get canVote => isActive && !isExpired;

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      sessionId: json['sessionId'],
      question: json['question'] ?? '',
      description: json['description'] ?? '',
      type: PollType.values.firstWhere(
        (e) => e.toString() == 'PollType.${json['type']}',
        orElse: () => PollType.multipleChoice,
      ),
      status: PollStatus.values.firstWhere(
        (e) => e.toString() == 'PollStatus.${json['status']}',
        orElse: () => PollStatus.draft,
      ),
      options: (json['options'] as List<dynamic>? ?? [])
          .map((e) => PollOption.fromJson(e))
          .toList(),
      allowMultipleAnswers: json['allowMultipleAnswers'] ?? false,
      isAnonymous: json['isAnonymous'] ?? true,
      showResults: json['showResults'] ?? true,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      createdBy: json['createdBy'] ?? '',
      totalVotes: json['totalVotes'] ?? 0,
      voterIds: List<String>.from(json['voterIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'sessionId': sessionId,
      'question': question,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'options': options.map((e) => e.toJson()).toList(),
      'allowMultipleAnswers': allowMultipleAnswers,
      'isAnonymous': isAnonymous,
      'showResults': showResults,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'createdBy': createdBy,
      'totalVotes': totalVotes,
      'voterIds': voterIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Poll copyWith({
    String? id,
    String? eventId,
    String? sessionId,
    String? question,
    String? description,
    PollType? type,
    PollStatus? status,
    List<PollOption>? options,
    bool? allowMultipleAnswers,
    bool? isAnonymous,
    bool? showResults,
    DateTime? startTime,
    DateTime? endTime,
    String? createdBy,
    int? totalVotes,
    List<String>? voterIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Poll(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      sessionId: sessionId ?? this.sessionId,
      question: question ?? this.question,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      options: options ?? this.options,
      allowMultipleAnswers: allowMultipleAnswers ?? this.allowMultipleAnswers,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      showResults: showResults ?? this.showResults,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdBy: createdBy ?? this.createdBy,
      totalVotes: totalVotes ?? this.totalVotes,
      voterIds: voterIds ?? this.voterIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}