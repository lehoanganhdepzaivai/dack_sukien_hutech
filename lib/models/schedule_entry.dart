class ScheduleEntry {
  const ScheduleEntry({
    required this.id,
    required this.title,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.venue,
    this.validFrom,
    this.validUntil,
  });

  final String id, title, venue;
  final int weekday, startMinutes, endMinutes;
  final DateTime? validFrom, validUntil;

  bool occursOn(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final from = validFrom;
    final until = validUntil;
    return day.weekday == weekday &&
        (from == null ||
            !date.isBefore(DateTime(from.year, from.month, from.day))) &&
        (until == null ||
            !date.isAfter(DateTime(until.year, until.month, until.day)));
  }

  ScheduleEntry copyWith({
    String? id,
    String? title,
    int? weekday,
    int? startMinutes,
    int? endMinutes,
    String? venue,
    DateTime? validFrom,
    DateTime? validUntil,
  }) => ScheduleEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    weekday: weekday ?? this.weekday,
    startMinutes: startMinutes ?? this.startMinutes,
    endMinutes: endMinutes ?? this.endMinutes,
    venue: venue ?? this.venue,
    validFrom: validFrom ?? this.validFrom,
    validUntil: validUntil ?? this.validUntil,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'weekday': weekday,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'venue': venue,
    'validFrom': validFrom?.toIso8601String(),
    'validUntil': validUntil?.toIso8601String(),
  };

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) => ScheduleEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    weekday: (json['weekday'] as num).toInt(),
    startMinutes: (json['startMinutes'] as num).toInt(),
    endMinutes: (json['endMinutes'] as num).toInt(),
    venue: json['venue'] as String,
    validFrom: json['validFrom'] == null
        ? null
        : DateTime.parse(json['validFrom'] as String),
    validUntil: json['validUntil'] == null
        ? null
        : DateTime.parse(json['validUntil'] as String),
  );
}
