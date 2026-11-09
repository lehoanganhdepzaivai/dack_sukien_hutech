enum RegistrationStatus {
  confirmed,
  waitlisted,
  canceled,
  attended;

  String get label => switch (this) {
    confirmed => 'Đã đăng ký',
    waitlisted => 'Đang chờ chỗ',
    canceled => 'Đã hủy',
    attended => 'Đã tham gia',
  };
}

class RegistrationModel {
  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  final String id, eventId, userId;
  final RegistrationStatus status;
  final DateTime createdAt;
  bool get occupiesSeat =>
      status == RegistrationStatus.confirmed ||
      status == RegistrationStatus.attended;

  RegistrationModel copyWith({
    RegistrationStatus? status,
    DateTime? createdAt,
  }) => RegistrationModel(
    id: id,
    eventId: eventId,
    userId: userId,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'userId': userId,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RegistrationModel.fromJson(Map<String, dynamic> json) =>
      RegistrationModel(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        userId: json['userId'] as String,
        status: RegistrationStatus.values.byName(json['status'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
