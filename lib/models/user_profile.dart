class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.faculty,
    required this.major,
    required this.cohort,
    required this.phone,
    required this.careerGoal,
    required this.interests,
    required this.skills,
    this.preferredVenue = 'HUTECH khu E',
    this.availableStartMinutes = 420,
    this.availableEndMinutes = 1320,
  });

  final String id,
      name,
      email,
      studentId,
      faculty,
      major,
      cohort,
      phone,
      careerGoal;

  /// Self-declared skills, never attendance evidence or earned certificates.
  final List<String> interests, skills;
  final String preferredVenue;
  final int availableStartMinutes, availableEndMinutes;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? faculty,
    String? major,
    String? cohort,
    String? phone,
    String? careerGoal,
    List<String>? interests,
    List<String>? skills,
    String? preferredVenue,
    int? availableStartMinutes,
    int? availableEndMinutes,
  }) => UserProfile(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    studentId: studentId ?? this.studentId,
    faculty: faculty ?? this.faculty,
    major: major ?? this.major,
    cohort: cohort ?? this.cohort,
    phone: phone ?? this.phone,
    careerGoal: careerGoal ?? this.careerGoal,
    interests: interests ?? this.interests,
    skills: skills ?? this.skills,
    preferredVenue: preferredVenue ?? this.preferredVenue,
    availableStartMinutes: availableStartMinutes ?? this.availableStartMinutes,
    availableEndMinutes: availableEndMinutes ?? this.availableEndMinutes,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'studentId': studentId,
    'faculty': faculty,
    'major': major,
    'cohort': cohort,
    'phone': phone,
    'careerGoal': careerGoal,
    'interests': interests,
    'skills': skills,
    'preferredVenue': preferredVenue,
    'availableStartMinutes': availableStartMinutes,
    'availableEndMinutes': availableEndMinutes,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    studentId: json['studentId'] as String? ?? '',
    faculty: json['faculty'] as String? ?? '',
    major: json['major'] as String? ?? '',
    cohort: json['cohort'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    careerGoal: json['careerGoal'] as String? ?? '',
    interests: List<String>.from(json['interests'] as List? ?? []),
    skills: List<String>.from(json['skills'] as List? ?? []),
    preferredVenue: json['preferredVenue'] as String? ?? 'HUTECH khu E',
    availableStartMinutes:
        (json['availableStartMinutes'] as num?)?.toInt() ?? 420,
    availableEndMinutes: (json['availableEndMinutes'] as num?)?.toInt() ?? 1320,
  );
}
