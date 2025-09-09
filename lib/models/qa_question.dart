enum QuestionStatus {
  pending,
  answered,
  dismissed,
  featured,
}

class QAQuestion {
  final String id;
  final String eventId;
  final String? sessionId;
  final String question;
  final String? answer;
  final String askedBy;
  final String? answeredBy;
  final QuestionStatus status;
  final int upvotes;
  final List<String> upvoterIds;
  final bool isAnonymous;
  final DateTime askedAt;
  final DateTime? answeredAt;
  final DateTime updatedAt;

  QAQuestion({
    required this.id,
    required this.eventId,
    this.sessionId,
    required this.question,
    this.answer,
    required this.askedBy,
    this.answeredBy,
    this.status = QuestionStatus.pending,
    this.upvotes = 0,
    this.upvoterIds = const [],
    this.isAnonymous = false,
    required this.askedAt,
    this.answeredAt,
    required this.updatedAt,
  });

  bool get isAnswered => status == QuestionStatus.answered && answer != null;
  bool get isPending => status == QuestionStatus.pending;

  factory QAQuestion.fromJson(Map<String, dynamic> json) {
    return QAQuestion(
      id: json['id'] ?? '',
      eventId: json['eventId'] ?? '',
      sessionId: json['sessionId'],
      question: json['question'] ?? '',
      answer: json['answer'],
      askedBy: json['askedBy'] ?? '',
      answeredBy: json['answeredBy'],
      status: QuestionStatus.values.firstWhere(
        (e) => e.toString() == 'QuestionStatus.${json['status']}',
        orElse: () => QuestionStatus.pending,
      ),
      upvotes: json['upvotes'] ?? 0,
      upvoterIds: List<String>.from(json['upvoterIds'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
      askedAt: DateTime.parse(json['askedAt'] ?? DateTime.now().toIso8601String()),
      answeredAt: json['answeredAt'] != null ? DateTime.parse(json['answeredAt']) : null,
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'sessionId': sessionId,
      'question': question,
      'answer': answer,
      'askedBy': askedBy,
      'answeredBy': answeredBy,
      'status': status.toString().split('.').last,
      'upvotes': upvotes,
      'upvoterIds': upvoterIds,
      'isAnonymous': isAnonymous,
      'askedAt': askedAt.toIso8601String(),
      'answeredAt': answeredAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  QAQuestion copyWith({
    String? id,
    String? eventId,
    String? sessionId,
    String? question,
    String? answer,
    String? askedBy,
    String? answeredBy,
    QuestionStatus? status,
    int? upvotes,
    List<String>? upvoterIds,
    bool? isAnonymous,
    DateTime? askedAt,
    DateTime? answeredAt,
    DateTime? updatedAt,
  }) {
    return QAQuestion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      sessionId: sessionId ?? this.sessionId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      askedBy: askedBy ?? this.askedBy,
      answeredBy: answeredBy ?? this.answeredBy,
      status: status ?? this.status,
      upvotes: upvotes ?? this.upvotes,
      upvoterIds: upvoterIds ?? this.upvoterIds,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      askedAt: askedAt ?? this.askedAt,
      answeredAt: answeredAt ?? this.answeredAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}