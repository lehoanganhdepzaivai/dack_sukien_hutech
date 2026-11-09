class CampusModel {
  final String id;
  final String code;
  final String name;
  final String address;
  final String description;
  final String image;
  final String travelInstructions;
  final List<String> matchingVenues;

  const CampusModel({
    required this.id,
    required this.code,
    required this.name,
    required this.address,
    required this.description,
    required this.image,
    required this.travelInstructions,
    required this.matchingVenues,
  });

  static const List<CampusModel> defaults = [
    CampusModel(
      id: 'campus-ab',
      code: 'CAMPUS_AB',
      name: 'Trụ sở Điện Biên Phủ (Khu A & B)',
      address: '475A Điện Biên Phủ, Phường 25, Quận Bình Thạnh, TP.HCM',
      description: 'Trung tâm đào tạo và hành chính chính của trường. Nơi diễn ra các hội thảo quy mô lớn tại Hội trường A-08.20, sảnh sự kiện A và các phòng chức năng.',
      image: 'assets/images/flutter_lab.png',
      travelInstructions: '• Tuyến xe buýt đi qua: 08, 19, 54, 104, 150 (Trạm dừng Ngã tư Hàng Xanh cách cổng trường 100m).\n• Tuyến Metro số 1 Bến Thành - Suối Tiên (Ga Văn Thánh / Cầu Sài Gòn).\n• Bãi giữ xe: Tầng hầm Khu A và bãi xe Khu B.',
      matchingVenues: ['HUTECH khu A, B', 'Hội trường A-08.20'],
    ),
    CampusModel(
      id: 'campus-e',
      code: 'CAMPUS_E',
      name: 'Viện Công nghệ cao HUTECH (Khu E)',
      address: 'Khu Công nghệ cao TP.HCM, Đường D1, P. Long Thạnh Mỹ, TP. Thủ Đức',
      description: 'Không gian nghiên cứu, khởi nghiệp sáng tạo và Maker Space hiện đại. Địa điểm tổ chức các cuộc thi công nghệ, Festival IT và Ngày hội việc làm doanh nghiệp.',
      image: 'assets/images/teamwork_studio.png',
      travelInstructions: '• Tuyến xe buýt đi qua: 55, 56, 141 (dừng ngay trước cổng Khu E).\n• Tuyến Metro số 1 Bến Thành - Suối Tiên (Ga Khu Công nghệ cao).\n• Có tuyến xe buýt trường đưa đón sinh viên giữa Khu A và Khu E định kỳ các ngày trong tuần.',
      matchingVenues: ['HUTECH khu E'],
    ),
  ];
}
