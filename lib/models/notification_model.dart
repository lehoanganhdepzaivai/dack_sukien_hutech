enum NotificationType {
  registration,
  waitlistPromotion,
  eventReminder,
  scheduleChange,
  eventCanceled,
  attendance,
  system;

  String get label => switch (this) {
    registration => 'Đăng ký thành công',
    waitlistPromotion => 'Chuyển danh sách chính thức',
    eventReminder => 'Nhắc nhở sự kiện',
    scheduleChange => 'Thay đổi lịch trình',
    eventCanceled => 'Sự kiện bị hủy',
    attendance => 'Điểm danh thành công',
    system => 'Hệ thống HUTECH',
  };
}

class AppNotificationModel {
  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.eventId,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? eventId;
  final bool isRead;

  AppNotificationModel copyWith({
    bool? isRead,
  }) => AppNotificationModel(
    id: id,
    userId: userId,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    eventId: eventId,
    isRead: isRead ?? this.isRead,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'eventId': eventId,
    'isRead': isRead,
  };

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) =>
      AppNotificationModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        type: NotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NotificationType.system,
        ),
        title: json['title'] as String,
        body: json['body'] as String,
        createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        ),
        eventId: json['eventId'] as String?,
        isRead: json['isRead'] as bool? ?? false,
      );
}
