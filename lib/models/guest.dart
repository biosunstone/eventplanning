enum RSVPStatus {
  pending,
  attending,
  notAttending,
  maybe,
}

class Guest {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final RSVPStatus rsvpStatus;
  final String? dietaryRestrictions;
  final int? plusOnes;
  final String? notes;
  final DateTime invitedAt;
  final DateTime? respondedAt;

  Guest({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.rsvpStatus = RSVPStatus.pending,
    this.dietaryRestrictions,
    this.plusOnes = 0,
    this.notes,
    required this.invitedAt,
    this.respondedAt,
  });

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      rsvpStatus: RSVPStatus.values.firstWhere(
        (e) => e.toString() == 'RSVPStatus.${json['rsvpStatus']}',
        orElse: () => RSVPStatus.pending,
      ),
      dietaryRestrictions: json['dietaryRestrictions'],
      plusOnes: json['plusOnes'] ?? 0,
      notes: json['notes'],
      invitedAt: DateTime.parse(json['invitedAt'] ?? DateTime.now().toIso8601String()),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'rsvpStatus': rsvpStatus.toString().split('.').last,
      'dietaryRestrictions': dietaryRestrictions,
      'plusOnes': plusOnes,
      'notes': notes,
      'invitedAt': invitedAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
    };
  }

  Guest copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    RSVPStatus? rsvpStatus,
    String? dietaryRestrictions,
    int? plusOnes,
    String? notes,
    DateTime? invitedAt,
    DateTime? respondedAt,
  }) {
    return Guest(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      rsvpStatus: rsvpStatus ?? this.rsvpStatus,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      plusOnes: plusOnes ?? this.plusOnes,
      notes: notes ?? this.notes,
      invitedAt: invitedAt ?? this.invitedAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}