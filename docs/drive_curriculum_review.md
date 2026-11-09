# Đối chiếu tài liệu môn học trong Google Drive

Ngày rà soát: 16/10/2026. Nguồn: [thư mục người dùng cung cấp](https://drive.google.com/drive/folders/11w6FFCWgCsZVkApaNhaDGWXEk-R8zlBi).

Tài liệu gồm bài giảng, bài tập minh họa và danh sách chủ đề thư viện để thuyết trình. Đây không phải đặc tả buộc ứng dụng quản lý sự kiện phải cài đồng thời mọi thư viện, mọi cơ sở dữ liệu hay mọi dịch vụ bên ngoài. Các thư viện cùng nhóm thường là lựa chọn thay thế. Những ví dụ như bài viết REST, chat Firebase hoặc Mini Trello giúp học kỹ thuật; không cần đưa nguyên ứng dụng mẫu vào sản phẩm sự kiện.

## Tài liệu đã đối chiếu

| Nguồn | Nội dung liên quan |
|---|---|
| [Bài 1 – Tổng quan lập trình thiết bị di động](https://drive.google.com/file/d/1WVLsoKchNqCAfWKal1XViHsciwA6ac9m/view) | Nền tảng, thiết bị, lập trình native/đa nền tảng; chủ yếu là kiến thức nền. |
| [Bài 2 – Ngôn ngữ Dart](https://drive.google.com/file/d/115n5kp5CoojO79salK34DYeseRdkb-xy/view) | Kiểu dữ liệu, null safety, List/Map/Set, hàm, OOP, xử lý lỗi, Future/Stream và async/await. |
| [Bài 3 – Flutter và Widgets cơ bản](https://drive.google.com/file/d/1IYxDmRAmcXB6b8kVOAh9ODYsGbUSinjG/view) | Stateful/Stateless, layout, widget, asset/media, quản lý trạng thái và điều hướng. |
| [Bài 4 – Thiết kế giao diện người dùng](https://drive.google.com/file/d/1xMNe401TC1OMurN2Fj4x4VxJJVkwXG9k/view) | Theme, TabBar/TabBarView, Drawer, BottomNavigationBar, form/input, indicator, dialog/Snackbar và tương tác. |
| [Bài 5 – Thư viện Flutter](https://drive.google.com/file/d/11x97pQVN1iYRo3z_Lio2j2iUrJMkd81N/view) | Tìm/cài package trên pub.dev; các nhóm thư viện giao diện, dữ liệu, mạng và thiết bị. |
| [Bài 6 P1 – Giao tiếp mạng và CSDL](https://drive.google.com/file/d/1b9xc3MT2KEHQ1d1IBYsPdVp1QEUYRD9P/view) | JSON, REST với http/dio, FutureBuilder, SharedPreferences và CRUD SQLite/sqflite. |
| [Bài 6 P2 – Firebase](https://drive.google.com/file/d/1_dBFiczyG0Do5TKOTZ5GBh-DF0hNcA35/view) | Realtime Database, Firestore, CRUD, stream và ví dụ chat; mở rộng Auth/thông báo/tệp đính kèm. |
| [Bài 6 P3 – Supabase](https://drive.google.com/file/d/1iwtLv7AW5rsFnx5TBOIbmZLu9ptBfdQh/view) | Supabase Database, Authentication, Storage; ví dụ Mini Trello có profiles/projects/tasks và cập nhật thời gian thực. |
| [Bài 7 – Quản lý trạng thái](https://drive.google.com/file/d/1HJ4UEI4v5US16KOVDyTB13XJ9DzwPoBB/view) | State cục bộ/toàn cục; Provider, BLoC và GetX. |
| [Bài 8 – Xuất bản và phân phối](https://drive.google.com/file/d/1_k3N_72DnWOhbJn7EkOoPLX7AAfMJ29_/view) | Version trong pubspec, build APK/App Bundle/IPA và quy trình phân phối ứng dụng. |
| [Danh sách chủ đề thuyết trình thư viện](https://drive.google.com/file/d/1XjHoNYK76ycjMuACkvGfcwH7KmCDlWmh/view) | 12 nhóm, 62 chủ đề; có Carousel Slider, Table Calendar, Easy Date Timeline, Image Picker, Easy Image Viewer, PDF Viewer cùng các nhóm hệ thống, media, thông báo, thanh toán, bản đồ, scanner, bảo mật và AI. |
| [Giáo trình tổng hợp](https://drive.google.com/file/d/1_ay-Rr8BXnn-JC24L8NJ8dI1erjyyij1/view) | Đối chiếu mục lục và các phần giao diện, animation/accessibility, thư viện, REST và lưu trữ với các bài giảng. |

## Mã nguồn đã có trước lần bổ sung này

| Kiến thức/chức năng | Minh chứng trong dự án | Giới hạn |
|---|---|---|
| Dart, OOP, collection, enum và null safety | `lib/models/`, `lib/services/` | Là kỹ thuật xây dựng sản phẩm, không cần tạo màn hình riêng cho từng khái niệm. |
| Future, async/await, try/catch, JSON | `lib/repositories/local_repository.dart`, `lib/providers/app_store.dart`, `lib/models/` | JSON đang phục vụ kho cục bộ; chưa chứng minh có REST API. |
| Stateful/Stateless, Material, form và validation | `lib/screens/auth/`, `lib/screens/student/`, `lib/screens/admin/event_editor_screen.dart` | Cần kiểm tra từng tương tác thực tế, không chỉ liệt kê tên widget. |
| Responsive, Drawer/sidebar và BottomNavigationBar | `lib/app/app_shell.dart` | Admin và sinh viên dùng menu theo vai trò. |
| Routing và tham số | `lib/app/hutech_app.dart` | Guard hiện ở client; không thay thế quyền trên máy chủ. |
| Provider/ChangeNotifier, state cục bộ | `lib/providers/app_store.dart`, các màn hình Stateful | Đã chọn Provider; không cần thêm BLoC/GetX/Riverpod để quản lý trùng một trạng thái. |
| Theme sáng/tối, ngày giờ tiếng Việt | `lib/app/app_theme.dart`, `lib/app/hutech_app.dart`, `intl` | Chưa có bộ bản dịch Anh–Việt toàn bộ ứng dụng. |
| Carousel Slider | `lib/screens/public/home_screen.dart` | Đã có package và điều khiển; người dùng báo tự chuyển chưa rõ, cần sửa hành vi autoplay. |
| Table Calendar | `lib/screens/student/calendar_screen.dart` | Lịch tháng/tuần với sự kiện và lịch học. |
| Image Picker và ảnh dự phòng | `lib/screens/admin/event_editor_screen.dart`, `lib/widgets/common.dart` | Chọn ảnh từ máy; chưa upload Storage hoặc dùng ảnh đại diện. |
| PDF, QR và biểu đồ | `lib/screens/student/activity_report.dart`, `ticket_screen.dart`, `lib/screens/admin/admin_dashboard.dart` | PDF và QR tạo tại client; QR chỉ là mã tham chiếu đăng ký, chưa là hệ thống điểm danh máy chủ. |
| SharedPreferences | `lib/providers/app_store.dart`, `lib/screens/auth/login_screen.dart` | Lưu phiên và thiết lập nhỏ; không lưu mật khẩu. |
| IndexedDB và tệp JSON cục bộ | `lib/repositories/local_repository.dart` cùng các backend theo nền tảng | Giữ sự kiện và ảnh sau khi đóng/mở lại; chưa đồng bộ giữa thiết bị. |
| Unit/widget tests và Web build | `test/`, `README.md` | Không suy ra kiểm thử Android hoặc backend từ kiểm thử Web. |

## Các phần đã bổ sung trong lượt làm việc này

Các mục dưới đây đã được tích hợp và kiểm thử theo đề tài quản lý sự kiện. Bộ kiểm thử có 100 test đạt; phân tích mã không báo lỗi và Web build thành công. Kiểm tra Chrome xác nhận autoplay và bản PDF tiếng Việt thực sự hiển thị.

- Carousel tự chuyển sau khoảng ba giây; chạm/giữ hoặc đặt chuột trên banner làm ảnh đứng yên, kết thúc tương tác thì chờ khoảng năm giây rồi chuyển tiếp. Nút phát/tạm dừng riêng được bỏ theo yêu cầu giao diện mới nhất.
- Dải chọn ngày trong tuần và bộ chọn ngày gắn với lịch học/sự kiện hiện có.
- Tab lọc vé/đăng ký để sinh viên chuyển nhanh giữa các trạng thái.
- Radio chọn ca học sáng/chiều theo khung giờ người dùng đã yêu cầu.
- Xem trước hồ sơ PDF ngay trong ứng dụng bằng package `printing` đã có.
- Mở ảnh sự kiện toàn màn hình, phóng to/di chuyển bằng `InteractiveViewer` và sao chép đường dẫn sự kiện.
- Trang chi tiết sự kiện có thao tác quản trị phù hợp khi người đang xem là admin.

Mã bổ sung: `lib/widgets/week_date_timeline.dart`, `lib/widgets/event_image_viewer.dart`, `lib/services/event_link.dart`, `lib/screens/student/activity_pdf_preview.dart` cùng các màn hình home/calendar/schedule/my_events/event_detail. PDF dùng `FutureBuilder` cho trạng thái tải/lỗi và runtime PDF.js đóng gói cục bộ trong `web/pdfjs/`; không gửi nội dung hồ sơ tới CDN. Máy chủ kiểm tra ở `tool/serve_web.py` bảo đảm MIME đúng cho JavaScript module trên Windows.

Việc dùng widget Flutter sẵn có để đáp ứng tương tác là có chủ đích. Ví dụ, `InteractiveViewer` đáp ứng nhu cầu phóng to ảnh mà không bắt buộc cài thêm `easy_image_viewer`; dải ngày có thể được xây bằng widget chuẩn mà không cần thêm một thư viện lịch thứ hai.

## Phần chưa có và điều kiện để triển khai đúng

1. **REST/backend dùng chung:** chưa có request CRUD sự kiện tới API, `http`/`dio`, Supabase Auth/Database/Storage/Realtime hoặc Firebase. Bài 6 minh họa các lựa chọn này. Tích hợp thật cần một dự án backend, URL và khóa client phù hợp, schema/quyền và kiểm thử nhiều tài khoản. Kế hoạch nằm trong `docs/supabase_setup.md`.
2. **SQLite và đồng bộ offline:** chưa có sqflite/Hive hoặc hàng đợi đồng bộ. IndexedDB/tệp JSON cục bộ không được gọi là SQLite hay cơ chế đồng bộ.
3. **Thông báo hệ điều hành, camera/QR scanner và điểm danh:** thông báo trong giao diện và QR tạo cục bộ chưa tương đương push notification, cấp quyền camera hay điểm danh có xác minh máy chủ.
4. **Tích hợp ngoài phạm vi đề tài:** thanh toán, AI, video/audio, GPS và xuất bản cửa hàng là các nhóm lựa chọn trong học liệu. Chỉ thêm khi có nghiệp vụ và cấu hình tương ứng. Google Maps được bỏ theo yêu cầu trực tiếp của người dùng.
5. **Phát hành:** Web build cục bộ không đồng nghĩa đã publish hosting, Google Play hoặc App Store.

Chi tiết đối chiếu prompt ban đầu với mã nguồn nằm trong `docs/flutter_course_mapping.md`. Tài liệu này chỉ bổ sung việc truy vết tới học liệu Google Drive và phạm vi lựa chọn cho lượt thay đổi hiện tại.
