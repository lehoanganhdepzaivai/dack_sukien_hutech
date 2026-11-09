class EventFeedbackModel {
  const EventFeedbackModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.contentRating,
    required this.speakerRating,
    required this.organizationRating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final int rating; // 1-5
  final int contentRating; // 1-5
  final int speakerRating; // 1-5
  final int organizationRating; // 1-5
  final String comment;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'eventId': eventId,
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'contentRating': contentRating,
    'speakerRating': speakerRating,
    'organizationRating': organizationRating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };

  factory EventFeedbackModel.fromJson(Map<String, dynamic> json) =>
      EventFeedbackModel(
        id: json['id'] as String,
        eventId: json['eventId'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String? ?? 'Sinh viên HUTECH',
        rating: (json['rating'] as num?)?.toInt() ?? 5,
        contentRating: (json['contentRating'] as num?)?.toInt() ?? 5,
        speakerRating: (json['speakerRating'] as num?)?.toInt() ?? 5,
        organizationRating: (json['organizationRating'] as num?)?.toInt() ?? 5,
        comment: json['comment'] as String? ?? '',
        createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
}

class EventCertificateModel {
  const EventCertificateModel({
    required this.certificateCode,
    required this.eventId,
    required this.eventTitle,
    required this.userId,
    required this.userName,
    required this.studentId,
    required this.issuedDate,
    required this.skillsAcquired,
    required this.organizerUnit,
  });

  final String certificateCode;
  final String eventId;
  final String eventTitle;
  final String userId;
  final String userName;
  final String studentId;
  final DateTime issuedDate;
  final List<String> skillsAcquired;
  final String organizerUnit;

  Map<String, dynamic> toJson() => {
    'certificateCode': certificateCode,
    'eventId': eventId,
    'eventTitle': eventTitle,
    'userId': userId,
    'userName': userName,
    'studentId': studentId,
    'issuedDate': issuedDate.toIso8601String(),
    'skillsAcquired': skillsAcquired,
    'organizerUnit': organizerUnit,
  };

  factory EventCertificateModel.fromJson(Map<String, dynamic> json) =>
      EventCertificateModel(
        certificateCode: json['certificateCode'] as String,
        eventId: json['eventId'] as String,
        eventTitle: json['eventTitle'] as String,
        userId: json['userId'] as String,
        userName: json['userName'] as String,
        studentId: json['studentId'] as String? ?? '',
        issuedDate: DateTime.parse(
          json['issuedDate'] as String? ?? DateTime.now().toIso8601String(),
        ),
        skillsAcquired: List<String>.from(json['skillsAcquired'] as List? ?? []),
        organizerUnit: json['organizerUnit'] as String? ?? 'HUTECH',
      );
}
