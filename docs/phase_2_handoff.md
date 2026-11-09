# Bàn giao bản Flutter Web cục bộ

Cập nhật: 16/10/2026. Thư mục dự án: `E:\HoangAnh_DACK\dack`. Bản này ưu tiên Chrome, sử dụng biểu trưng khiên HUTECH được vẽ lại bằng mã theo hình người dùng cung cấp và bảng màu xanh dương, vàng, trắng. Giao diện không đặt nhãn demo hay watermark trên ảnh.

## Mở và đăng nhập

Mở [http://127.0.0.1:8080](http://127.0.0.1:8080) khi máy chủ bản build đang chạy. Để tự chạy từ mã nguồn:

```powershell
cd E:\HoangAnh_DACK\dack
flutter pub get
flutter run -d chrome --web-port 8080
```

| Vai trò | Email | Mật khẩu |
|---|---|---|
| Sinh viên | `HA@gmail.com` | `123` |
| Admin | `admin@gmail.com` | `123` |

Đây là tài khoản cục bộ được tạo theo yêu cầu, chưa có tài khoản Supabase tương ứng. Hồ sơ, lịch học, sở thích, mục tiêu và sự kiện khởi tạo đã có để trải nghiệm ngay.

Dữ liệu chỉnh sửa và ảnh tải lên được lưu trong IndexedDB trên web, hoặc trong tệp JSON thuộc thư mục dữ liệu ứng dụng trên Android/desktop. Bản lưu SharedPreferences cũ được tự động nhập vào kho mới. Trên web phải dùng cùng trình duyệt và cùng địa chỉ gồm hostname/cổng; `localhost:8080` và `127.0.0.1:8080` có kho riêng. Dữ liệu không đồng bộ giữa máy, không gửi tới Supabase và có thể mất khi xóa dữ liệu trang hoặc dữ liệu ứng dụng.

## Chức năng đã có

- Khách: trang chủ, carousel nổi bật dùng `carousel_slider`, tìm/lọc/sắp xếp sự kiện và xem chi tiết. Carousel tự chuyển mỗi 3 giây; chạm/giữ hoặc đặt chuột trên banner thì đứng yên, thả tay/rời chuột thì chờ 5 giây mới chuyển tiếp. Không còn nút tạm dừng riêng; vuốt, mũi tên, chấm trang và bàn phím vẫn hoạt động. Chi tiết có xem ảnh toàn màn hình/zoom/kéo ảnh và sao chép liên kết.
- Sinh viên: cập nhật hồ sơ, sở thích, kỹ năng tự khai báo, mục tiêu; quản lý lịch học theo ca tiết 2–6 hoặc 7–11; xem lịch tháng/tuần, đề xuất có giải thích và cảnh báo trùng lịch.
- Đăng ký: kiểm tra thời hạn, trạng thái, sức chứa và đăng ký trùng; khi trùng lịch, hệ thống nêu rõ môn, ngày, tiết, giờ, cơ sở và yêu cầu chọn `Hủy` hoặc `Vẫn đăng ký`; hỗ trợ hủy, hàng đợi FIFO, danh sách cá nhân, yêu thích, mã QR tham chiếu đăng ký và xuất hồ sơ PDF tiếng Việt.
- Admin: có shell và điều hướng riêng theo vai trò; tài khoản admin không hiện nghiệp vụ hồ sơ/lịch học sinh viên. Admin tạo/sửa/hủy/lưu trữ sự kiện, chọn ảnh từ máy hoặc ảnh có sẵn, đổi trạng thái và cờ nổi bật, quản lý chủ đề, xem người dùng/đăng ký, sao chép CSV và biểu đồ phân bố sự kiện. Mục `Thêm sự kiện` mở trực tiếp route `/admin/events/new` ở sidebar desktop và thanh điều hướng mobile.
- Dùng chung: giao diện sáng/tối, điều hướng desktop/mobile, trạng thái trống/lỗi, ghi nhớ email tùy chọn và giữ dữ liệu khi tải lại.

Bổ sung theo học liệu Drive: lịch có dải chọn nhanh 7 ngày và bộ chọn ngày, form lịch có Radio chọn sáng/chiều/tùy chỉnh, vé có TabBar lọc trạng thái, PDF có cửa sổ xem trước với xử lý timeout. Admin xem chi tiết sự kiện có nút sửa và không hiện nút đăng ký của sinh viên. Đối chiếu nguồn tại `docs/drive_curriculum_review.md`.

Biểu trưng trong widget Flutter được dựng bằng `CustomPainter` tại `lib/widgets/hutech_logo.dart`. Trang chờ trước frame Flutter, favicon và manifest dùng `web/hutech_mark.svg` có nền trong suốt; ảnh bitmap wordmark cũ không còn được dùng để hiển thị logo trong luồng chính.

Ảnh tải từ máy chấp nhận PNG/JPEG/WebP tối đa 2 MiB mỗi ảnh; ảnh được lưu dưới dạng dữ liệu trong kho trình duyệt. Hai địa điểm là `HUTECH khu A, B` và `HUTECH khu E`; không tích hợp Google Maps. Khoa/viện, kỹ năng và cơ sở có danh sách lựa chọn, chưa có thao tác quản lý đầy đủ cho tất cả các danh mục.

## Nhóm file tạo hoặc thay đổi

| Nhóm | File/thư mục |
|---|---|
| Khởi động, theme, định tuyến và bố cục | `lib/main.dart`, `lib/app/` |
| Model và dữ liệu ban đầu | `lib/models/`, `lib/data/prototype_seed.dart` |
| Nghiệp vụ và trọng số đề xuất | `lib/services/`, `lib/config/recommendation_config.dart` |
| Trạng thái và lưu dữ liệu | `lib/providers/app_store.dart`, `lib/repositories/local_repository.dart` |
| Màn hình đăng nhập, công khai, sinh viên, admin | `lib/screens/auth/`, `lib/screens/public/`, `lib/screens/student/`, `lib/screens/admin/` |
| Thành phần dùng lại | `lib/widgets/common.dart`, `lib/widgets/event_card.dart`, `lib/widgets/hutech_logo.dart` |
| Ba ảnh minh họa, bản tham chiếu logo, font PDF và giấy phép | `assets/images/`, `assets/fonts/` |
| Package và trang Web | `pubspec.yaml`, `pubspec.lock`, `web/index.html`, `web/manifest.json`, `web/hutech_mark.svg` |
| Kiểm thử | `test/domain_test.dart`, `test/widget_test.dart`, `test/student_widget_test.dart` |
| Thiết kế và hướng dẫn | `README.md`, `docs/phase_1_design.md`, `docs/supabase_setup.md`, `docs/data_sources.md`, `docs/flutter_course_mapping.md`, tài liệu này |
| Bản giữ mã Flutter ban đầu | `backups/initial_flutter/` |

## Kịch bản kiểm tra trên Web

1. Mở trang chủ khi chưa đăng nhập, chuyển banner, tìm/lọc và mở một sự kiện.
2. Đăng nhập sinh viên; mở lịch học để xem ca sáng/chiều, sau đó đăng ký “Từ ý tưởng đến ứng dụng Flutter” để kiểm tra cảnh báo trùng môn và hai lựa chọn xử lý.
3. Đăng ký một sự kiện đang mở, xem Sự kiện của tôi và vé QR; hủy và kiểm tra trạng thái. Mở hồ sơ PDF để kiểm tra tiếng Việt.
4. Đăng xuất rồi đăng nhập admin. Kiểm tra giao diện chỉ còn nhóm chức năng quản trị, chọn `Thêm sự kiện` trực tiếp từ menu, chọn ảnh và thời gian hợp lệ; bật nổi bật để đưa vào carousel. Nhập thử kết thúc trước bắt đầu để kiểm tra lỗi.
5. Đăng nhập lại sinh viên trong cùng trình duyệt; tìm sự kiện vừa tạo. Tải lại trang để kiểm tra dữ liệu được giữ.
6. Chuyển sáng/tối, thu hẹp cửa sổ và kiểm tra menu, form, lịch, thẻ sự kiện. Mở URL admin bằng tài khoản sinh viên để kiểm tra màn hình từ chối.

## Giới hạn và phần việc tiếp theo

Đăng nhập và quyền hiện được kiểm tra tại client. Bản hiện tại không gọi API nghiệp vụ bên ngoài: đăng nhập dùng `LocalAuthService`; dữ liệu lớn dùng IndexedDB trên web và tệp JSON cục bộ trên Android/desktop; SharedPreferences giữ các thiết lập nhỏ. Ảnh ban đầu là asset và ảnh chọn qua file picker; PDF, QR, biểu đồ và lịch được dựng cục bộ. `EventImage` có khả năng đọc URL HTTPS bằng `Image.network`, nhưng không dữ liệu khởi tạo nào dùng URL mạng và form hiện tại không nhận URL ảnh. Supabase Auth/Database/Storage, RLS, SQL migration cuối cùng, tài khoản ban tổ chức và backend nhiều người dùng chưa được triển khai. Đăng ký tài khoản/đặt lại mật khẩu hiện chỉ có màn hình giải thích trạng thái, chưa gửi email.

QR chỉ chứa mã tham chiếu đăng ký; chưa có scanner, token dùng một lần, hạn token hoặc điểm danh máy chủ. Chưa có đánh giá trước/sau, minh chứng năng lực, chứng nhận hay thống kê hiệu quả từ dữ liệu tham dự. PDF là hồ sơ đăng ký, không phải giấy chứng nhận. SQLite và đồng bộ offline chưa có; xem đối chiếu học phần để biết từng mục. Trình đọc PDF.js và font được phục vụ cục bộ, không gửi hồ sơ ra ngoài. Xem bản build bằng `python tool/serve_web.py --port 8080` để bảo đảm MIME `.mjs` đúng trên Windows.

Các sự kiện và thông tin hồ sơ ban đầu được tạo theo yêu cầu; nguồn tài nguyên và giới hạn dữ liệu được ghi trong `docs/data_sources.md`. Sau khi kiểm tra giao diện và ERD, bước tiếp theo là kết nối Supabase, hoàn thiện quyền dữ liệu và nghiệp vụ máy chủ theo `docs/supabase_setup.md`.

## Kiểm tra kỹ thuật

```powershell
flutter analyze --no-pub
flutter test --no-pub
flutter build web --no-pub
```

Kết quả xác minh ngày 16/10/2026:

- Phân tích mã nguồn đạt với `No issues found!`.
- Toàn bộ 100 test đạt.
- Build Flutter Web hoàn tất thành công.
- [http://127.0.0.1:8080](http://127.0.0.1:8080) phản hồi HTTP 200.
- Widget test responsive đạt ở mobile 390 px, desktop 1100/1440 px và giao diện admin mobile.
- Bản build chạy trên Chrome headless đã được kiểm tra trực quan ở 1440 px cho trang chủ, carousel, logo mới, trang đăng nhập và dashboard admin; admin hiển thị menu riêng cùng ô `Thêm sự kiện`.
- Kiểm tra mới: hai ảnh carousel trước/sau tự chuyển, dải lịch tuần, tab vé và PDF tiếng Việt đã render; ảnh lưu trong `qa/`.

Unit/widget test chỉ xác minh phạm vi cục bộ. Chưa xác nhận vận hành trên thiết bị Android thật hoặc phát hành hosting công khai; Supabase chưa được tích hợp.
