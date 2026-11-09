class RecommendationConfig {
  const RecommendationConfig({
    this.interestWeight = .30,
    this.skillGapWeight = .25,
    this.availabilityWeight = .20,
    this.historyWeight = .15,
    this.venueWeight = .10,
    this.travelBufferMinutes = 45,
  });

  final double interestWeight,
      skillGapWeight,
      availabilityWeight,
      historyWeight,
      venueWeight;

  /// Configurable planning buffer, not measured traffic or a Maps estimate.
  final int travelBufferMinutes;

  double get weightSum =>
      interestWeight +
      skillGapWeight +
      availabilityWeight +
      historyWeight +
      venueWeight;
  Map<String, double> get weights => {
    'Sở thích': interestWeight,
    'Kỹ năng cần phát triển': skillGapWeight,
    'Lịch trống': availabilityWeight,
    'Lịch sử tương tác': historyWeight,
    'Địa điểm': venueWeight,
  };

  static const Map<String, List<String>> careerSkills = {
    'Flutter Developer': [
      'Dart',
      'Flutter',
      'REST API',
      'Git',
      'Làm việc nhóm',
    ],
    'Kỹ sư phần mềm': [
      'Lập trình',
      'Git',
      'Tư duy phản biện',
      'Giải quyết vấn đề',
      'Làm việc nhóm',
    ],
    'Chuyên viên Marketing': [
      'Marketing',
      'Sáng tạo',
      'Truyền thông',
      'Phân tích dữ liệu',
      'Thuyết trình',
    ],
    'Chuyên viên kinh doanh': [
      'Giao tiếp',
      'Đàm phán',
      'Làm việc nhóm',
      'Quản lý thời gian',
      'Thuyết trình',
    ],
    'Nhà thiết kế': [
      'Thiết kế',
      'Sáng tạo',
      'Tư duy phản biện',
      'Truyền thông',
      'Làm việc nhóm',
    ],
    'Quản lý sự kiện': [
      'Tổ chức sự kiện',
      'Lãnh đạo',
      'Giao tiếp',
      'Quản lý thời gian',
      'Làm việc nhóm',
    ],
  };
}
