enum EventStatus {
  draft,
  pending,
  published,
  registrationOpen,
  full,
  registrationClosed,
  ongoing,
  completed,
  canceled,
  archived;

  String get label => switch (this) {
    draft => 'Bản nháp',
    pending => 'Chờ duyệt',
    published => 'Đã công bố',
    registrationOpen => 'Đang mở đăng ký',
    full => 'Danh sách chờ',
    registrationClosed => 'Đã đóng đăng ký',
    ongoing => 'Đang diễn ra',
    completed => 'Đã kết thúc',
    canceled => 'Đã hủy',
    archived => 'Đã lưu trữ',
  };

  String get value => switch (this) {
    registrationOpen => 'registration_open',
    registrationClosed => 'registration_closed',
    _ => name,
  };

  static EventStatus parse(String? value) => EventStatus.values.firstWhere(
    (item) => item.value == value || item.name == value,
    orElse: () => EventStatus.draft,
  );
}

class EventModel {
  const EventModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.organization,
    required this.venue,
    required this.image,
    required this.start,
    required this.end,
    required this.deadline,
    required this.capacity,
    required this.status,
    required this.skills,
    this.featured = false,
  });

  final String id,
      title,
      subtitle,
      description,
      category,
      organization,
      venue,
      image;
  final DateTime start, end, deadline;
  final int capacity;
  final EventStatus status;
  final List<String> skills;
  final bool featured;

  bool get isPublic => ![
    EventStatus.draft,
    EventStatus.pending,
    EventStatus.archived,
  ].contains(status);
  bool get isRegistrationOpen =>
      [EventStatus.registrationOpen, EventStatus.full].contains(status);

  EventModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? category,
    String? organization,
    String? venue,
    String? image,
    DateTime? start,
    DateTime? end,
    DateTime? deadline,
    int? capacity,
    EventStatus? status,
    List<String>? skills,
    bool? featured,
  }) => EventModel(
    id: id ?? this.id,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    description: description ?? this.description,
    category: category ?? this.category,
    organization: organization ?? this.organization,
    venue: venue ?? this.venue,
    image: image ?? this.image,
    start: start ?? this.start,
    end: end ?? this.end,
    deadline: deadline ?? this.deadline,
    capacity: capacity ?? this.capacity,
    status: status ?? this.status,
    skills: skills ?? this.skills,
    featured: featured ?? this.featured,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'category': category,
    'organization': organization,
    'venue': venue,
    'image': image,
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
    'deadline': deadline.toIso8601String(),
    'capacity': capacity,
    'status': status.value,
    'skills': skills,
    'featured': featured,
  };

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
    id: json['id'] as String,
    title: json['title'] as String,
    subtitle: json['subtitle'] as String? ?? '',
    description: json['description'] as String? ?? '',
    category: json['category'] as String,
    organization: json['organization'] as String? ?? '',
    venue: json['venue'] as String,
    image: json['image'] as String? ?? '',
    start: DateTime.parse(json['start'] as String),
    end: DateTime.parse(json['end'] as String),
    deadline: DateTime.parse(json['deadline'] as String),
    capacity: (json['capacity'] as num).toInt(),
    status: EventStatus.parse(json['status'] as String?),
    skills: List<String>.from(json['skills'] as List? ?? []),
    featured: json['featured'] as bool? ?? false,
  );
}
