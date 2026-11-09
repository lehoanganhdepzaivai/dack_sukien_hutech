# HUTECH EVENT INTELLIGENCE
### HỆ THỐNG QUẢN LÝ SỰ KIỆN SINH VIÊN HUTECH
**Học phần:** Lập trình trên thiết bị di động (CMP177)  
**Nền tảng:** Flutter (Web & Android), Material 3, Provider, Supabase Cloud & Local Persistence

---

## 1. TỔNG QUAN CÔNG NGHỆ THỰC TẾ SỬ DỤNG

| Thành phần | Công nghệ / Thư viện | Mục đích sử dụng thực tế |
|---|---|---|
| **Frontend Framework** | Flutter / Dart (SDK ^3.13) | Xây dựng ứng dụng đa nền tảng Responsive (Web và Mobile Android) |
| **State Management** | Provider (`^6.1.5`) + ChangeNotifier | Quản lý trạng thái toàn cục ứng dụng theo mô hình Reactive Store |
| **Navigation & Routing** | GoRouter (`^18.1.0`) | Điều hướng khai báo (declarative routing), bảo vệ route và phân quyền vai trò |
| **Cloud Backend & Auth** | Supabase Flutter (`^2.18.3`) | Xác thực người dùng bằng Email/Password, quản lý phiên và Row Level Security |
| **Cơ sở dữ liệu** | PostgreSQL (Supabase Cloud) + SQLite/IndexedDB | Lưu trữ bền vững dữ liệu sự kiện, vé, lịch học và đồng bộ ngoại tuyến |
| **Local Storage** | `SharedPreferences`, `idb_shim`, `sqflite` | Lưu trữ cấu hình phiên, giao diện sáng/tối và bộ đệm thiết bị cục bộ |
| **Trình diễn & Đồ họa** | `carousel_slider`, `fl_chart`, `CustomPainter` | Banner sự kiện tự động chuyển/giữ chạm, biểu đồ thống kê và Logo HUTECH vẽ bằng mã |
| **Xử lý tài liệu & Mã hóa**| `qr_flutter`, `pdf`, `printing` | Sinh mã QR vé tham dự, tạo và xem trước hồ sơ hoạt động PDF tiếng Việt |
| **Quốc tế hóa** | `flutter_localizations`, `intl` | Định dạng ngày giờ chuẩn tiếng Việt (`vi_VN`) |

---

## 2. BẢNG TỔNG HỢP TRẠNG THÁI CHỨC NĂNG

> **Nguyên tắc kỹ thuật:** Không tuyên bố một chức năng đã hoàn thành nếu chưa chạy và kiểm thử được trong mã nguồn.

### 2.1 Chức năng đã hoàn thành (100% chạy và có kiểm thử tự động)
| STT | Phân hệ / Module | Chức năng cụ thể | Trạng thái |
|:---:|---|---|:---:|
| 1 | **Giao diện & Trải nghiệm** | Responsive đa nền tảng Web & Mobile, Chế độ sáng/tối (Dark/Light Mode) | **Hoàn thành** |
| 2 | **Nhận diện thương hiệu** | Biểu trưng khiên HUTECH vẽ bằng mã (`CustomPainter`) và SVG Web trong suốt | **Hoàn thành** |
| 3 | **Khám phá sự kiện** | Banner nổi bật tự động chuyển sau 3s, giữ chạm/chuột dừng, chờ 5s tiếp tục | **Hoàn thành** |
| 4 | **Tìm kiếm & Bộ lọc** | Tìm kiếm theo từ khóa tiêu đề/đơn vị/kỹ năng, lọc theo Danh mục và Địa điểm | **Hoàn thành** |
| 5 | **Chi tiết sự kiện** | Xem chi tiết, xem ảnh toàn màn hình với zoom/pan, sao chép liên kết chia sẻ | **Hoàn thành** |
| 6 | **Xác thực & Phân quyền** | Đăng nhập/Đăng xuất, Phân quyền giao diện Admin, Organizer, Sinh viên và Khách | **Hoàn thành** |
| 7 | **Đăng ký tài khoản mới** | Đăng ký sinh viên HUTECH, kiểm tra định dạng email và MSSV hợp lệ | **Hoàn thành** |
| 8 | **Quên mật khẩu** | Màn hình gửi yêu cầu khôi phục mật khẩu qua Email an toàn | **Hoàn thành** |
| 9 | **Hồ sơ sinh viên** | Quản lý sở thích, kỹ năng tự khai báo, mục tiêu nghề nghiệp, cơ sở ưu tiên | **Hoàn thành** |
| 10 | **Thời khóa biểu & Lịch học** | CRUD lịch học cá nhân; chọn nhanh tiết sáng (2-6), tiết chiều (7-11) hoặc giờ tùy biến | **Hoàn thành** |
| 11 | **Cảnh báo thông minh** | Cảnh báo xung đột trùng lịch học, trùng sự kiện đã đăng ký và đệm giờ di chuyển | **Hoàn thành** |
| 12 | **Đăng ký & Danh sách chờ** | Đăng ký sự kiện, kiểm tra sức chứa, tự động xếp hàng đợi FIFO khi hết chỗ | **Hoàn thành** |
| 13 | **Hủy chỗ & Đẩy hàng chờ** | Hủy đăng ký giải phóng chỗ và tự động nâng người đầu danh sách chờ lên chính thức | **Hoàn thành** |
| 14 | **Hệ thống Vé điện tử** | Vé sự kiện có mã QR định danh và thông tin xác nhận tham dự | **Hoàn thành** |
| 15 | **Xuất báo cáo PDF** | Tạo và xem trước hồ sơ hoạt động ngoại khóa PDF tiếng Việt chuẩn font | **Hoàn thành** |
| 16 | **Quản trị sự kiện (Admin)** | Tạo, chỉnh sửa, lưu trữ, chọn ảnh từ máy, quản lý sức chứa và thời hạn | **Hoàn thành** |
| 17 | **Quản lý danh mục & người tham gia** | CRUD danh mục, xem danh sách đăng ký và sao chép danh sách CSV | **Hoàn thành** |
| 18 | **Lưu trữ bền vững (Persistence)** | IndexedDB trên Web, SQLite/JSON an toàn trên Android, tắt/mở không mất dữ liệu | **Hoàn thành** |
| 19 | **Kiến trúc Supabase Backend** | Migration SQL chuẩn cho 18+ bảng, RLS đa vai trò, trigger tạo profile, Storage buckets | **Hoàn thành** |
| 20 | **Chỉ báo kết nối Backend** | Hiển thị trạng thái máy chủ (Cloud/Cục bộ) trong trang quản trị, không dùng nhãn giả | **Hoàn thành** |
| 21 | **Điểm danh QR Camera & Thủ công** | Quét QR vé bằng camera qua `mobile_scanner`, nhập mã thủ công, kiểm tra vé hợp lệ, tỷ lệ có mặt | **Hoàn thành** |
| 22 | **Cơ sở đào tạo HUTECH** | Khám phá 2 cơ sở chính (Khu A & B, Khu E CNC), hướng dẫn di chuyển, lọc sự kiện theo cơ sở | **Hoàn thành** |
| 23 | **Hỏi đáp sự kiện (Event Q&A)** | Đặt câu hỏi thắc mắc, phản hồi từ BTC, tính năng ghim thông báo quan trọng | **Hoàn thành** |

### 2.2 Chức năng đang triển khai (In Progress)
| STT | Chức năng | Chi tiết kỹ thuật |
|:---:|---|---|
| 1 | **Phiên điểm danh bảo mật với RPC** | Kích hoạt transaction `check_in_ticket` trên Supabase với token mã hóa ngắn hạn |
| 2 | **Giao diện phân quyền Ban tổ chức riêng**| Khu vực quản trị giới hạn theo sự kiện được phân công cho Organizer |

### 2.3 Chức năng kế hoạch tương lai (Roadmap)
| STT | Chức năng | Chi tiết kỹ thuật |
|:---:|---|---|
| 1 | **Push Notification từ xa** | Tích hợp Firebase Cloud Messaging (FCM) gửi thông báo đẩy |
| 2 | **Khảo sát & Cấp chứng nhận tự động** | Chấm điểm khảo sát sau sự kiện và ký số mã chứng nhận điện tử |

---

## 3. HƯỚNG DẪN CÀI ĐẶT VÀ CHẠY DỰ ÁN

### 3.1 Yêu cầu môi trường
- Flutter SDK 3.13 trở lên.
- Trình duyệt Google Chrome (ưu tiên kiểm thử Web).
- Android Studio với Android SDK / Máy ảo Pixel 6 (API 34/35).

### 3.2 Các bước chạy trên Web (Chrome)
Mở PowerShell tại thư mục `dack`:
```powershell
flutter pub get
flutter run -d chrome --web-port 8080
```
Địa chỉ chạy ứng dụng: [http://localhost:8080](http://localhost:8080).

### 3.3 Chạy với cấu hình Supabase Cloud (Tùy chọn)
Nếu đã tạo dự án trên Supabase, truyền tham số `--dart-define`:
```powershell
flutter run -d chrome --web-port 8080 `
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJh...
```
*(Nếu không truyền tham số, ứng dụng tự động kích hoạt bộ nhớ cục bộ Offline bền vững mà không bị crash).*

### 3.4 Chạy trên Android Emulator
```powershell
flutter run -d emulator-5554
```

---

## 4. TÀI KHOẢN ĐĂNG NHẬP MẶC ĐỊNH

| Vai trò | Email đăng nhập | Mật khẩu | Phạm vi quyền hạn |
|---|---|---|---|
| **Sinh viên** | `HA@gmail.com` | `123` | Đăng ký sự kiện, quản lý lịch học, xem vé QR, xuất hồ sơ PDF |
| **Quản trị viên (Admin)** | `admin@gmail.com` | `123` | Toàn quyền tạo/sửa sự kiện, tải ảnh, xem dashboard thống kê, quản lý người dùng |

*Người dùng mới cũng có thể bấm **Tạo tài khoản** trên màn hình đăng nhập để tự tạo tài khoản sinh viên mới.*

---

## 5. KỊCH BẢN QUAY VIDEO DEMO BÁO CÁO (DƯỚI 10 PHÚT)
*(Tuân thủ chính xác theo Hướng dẫn quay video đồ án cuối kỳ môn CMP177)*

* **Chuẩn bị:** Cả nhóm cùng vào Google Meet/Zoom, **tất cả thành viên bật camera** suốt video, ăn mặc lịch sự, chia sẻ màn hình máy tính có sẵn ứng dụng đang chạy mượt mà.

### Phân bổ thời gian chi tiết:
* **00:00 – 01:00 (1 phút) | Mở đầu & Giới thiệu nhóm:**
  - Đại diện nhóm chào giảng viên, giới thiệu số nhóm, tên đề tài: *"Hệ thống Quản lý Sự kiện Sinh viên HUTECH"*.
  - Lần lượt từng thành viên trong nhóm nhìn vào camera, nêu rõ Họ tên và Mã số sinh viên (MSSV).
* **01:00 – 02:00 (1 phút) | Giới thiệu Đề tài & Công nghệ:**
  - Nêu ngắn gọn nhu cầu: Giúp sinh viên HUTECH dễ dàng tiếp cận, đăng ký sự kiện, tránh xung đột lịch học và tích lũy kỹ năng nghề nghiệp.
  - Nêu công nghệ chính: **Frontend Flutter/Dart** đa nền tảng, quản lý trạng thái **Provider**, cơ sở dữ liệu **Supabase PostgreSQL** kết hợp lưu trữ cục bộ **IndexedDB/SQLite**, tạo mã **QR** và xuất **PDF**.
* **02:00 – 05:30 (3.5 phút) | Demo Luồng Sinh viên:**
  - **Khám phá sự kiện:** Xem trang chủ với carousel tự chuyển động, tìm kiếm sự kiện theo từ khóa và lọc theo Khoa/Địa điểm.
  - **Cá nhân hóa & Lịch học:** Mở trang Lịch học, thêm 1 môn học vào thời khóa biểu (chọn nhanh tiết sáng 2–6).
  - **Cảnh báo xung đột & Đăng ký:** Vào chi tiết 1 sự kiện trùng giờ học, hệ thống cảnh báo cụ thể môn học bị trùng. Thao tác chọn "Vẫn đăng ký".
  - **Vé điện tử & Xuất PDF:** Vào tab "Sự kiện của tôi", mở thẻ vé có mã QR; sau đó mở tính năng xem trước và xuất hồ sơ hoạt động PDF tiếng Việt.
* **05:30 – 08:30 (3.0 phút) | Demo Luồng Quản trị viên (Admin):**
  - Đăng xuất sinh viên, đăng nhập tài khoản Quản trị viên (`admin@gmail.com`).
  - **Dashboard:** Xem thống kê số lượng sự kiện, trạng thái kết nối backend, biểu đồ phân bố chủ đề sự kiện.
  - **Thêm sự kiện mới:** Vào form "Tạo sự kiện", nhập tên sự kiện, chọn ngày bắt đầu, hạn đăng ký, chọn ảnh minh họa và thiết lập sức chứa. Bấm Lưu.
  - **Kiểm tra tính nhất quán:** Đăng xuất Admin, đăng nhập lại Sinh viên và thấy ngay sự kiện mới tạo hiển thị tại Trang chủ.
* **08:30 – 09:30 (1 phút) | Kiểm tra dữ liệu bền vững (Persistence):**
  - Tắt ứng dụng/Refresh lại trang Web hoặc tắt mở lại máy ảo.
  - Đăng nhập lại, chứng minh tất cả các sự kiện và dữ liệu vé đã thêm **không hề bị mất**.
* **09:30 – 10:00 (30 giây) | Tổng kết & Kết thúc:**
  - Tóm tắt kết quả đạt được của nhóm. Gửi lời cảm ơn chân thành đến Quý Thầy/Cô bộ môn đã hướng dẫn và kết thúc video (đảm bảo thời lượng dưới 10 phút).

---

## 6. KẾT QUẢ KIỂM THỬ MÃ NGUỒN TỰ ĐỘNG

- `flutter analyze --no-pub`: **No issues found!** (Không có lỗi, không có warning).
- `flutter test --no-pub`: **120 / 120 tests passed** (Bao gồm kiểm thử domain logic, hàng đợi FIFO, xung đột lịch học, giao diện responsive, autoplay carousel, Supabase auth và Check-in điểm danh).
- `flutter build web --release --no-pub`: **Build thành công thư mục `build/web`**.
