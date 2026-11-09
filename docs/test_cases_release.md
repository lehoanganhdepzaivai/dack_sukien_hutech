# BẢNG KỊCH BẢN KIỂM THỬ ĐỒ ÁN CUỐI KỲ (TEST CASES)
## HỆ THỐNG QUẢN LÝ SỰ KIỆN SINH VIÊN HUTECH (HUTECH EVENT INTELLIGENCE)

### Thông tin chạy kiểm thử

| Mục | Giá trị |
| :--- | :--- |
| **Tên ứng dụng** | HUTECH Event Intelligence (Hệ thống Quản lý Sự kiện Sinh viên) |
| **Nền tảng kiểm thử** | Flutter Web & Flutter Android Release (APK) |
| **Thiết bị thử nghiệm** | Thiết bị di động Android 13/14 + Trình duyệt Google Chrome / Edge |
| **Backend** | Supabase Cloud Database & Storage + Dual-mode Local Persistence (IndexedDB / SQLite) |
| **Tài khoản kiểm thử** | Admin (`admin@hutech.edu.vn`) & Sinh viên (`student@hutech.edu.vn` / Đăng ký mới) |
| **Kết quả tổng thể** | `120/120 Unit/Widget Tests Passed` • Tất cả các kịch bản kiểm thử chức năng đạt `Pass` |

---

### Phân hệ 1: Xác thực, Phân quyền & Quản lý Tài khoản (Auth & Profiles)

| ID | Ưu tiên | Tiền điều kiện | Các bước thực hiện | Kết quả mong đợi | Kết quả |
| :--- | :---: | :--- | :--- | :--- | :---: |
| **AUTH-001** | P0 | Cài đặt ứng dụng / Mở Web | Mở ứng dụng lần đầu | Ứng dụng khởi động mượt mà, không crash; hiển thị trang chủ khám phá sự kiện cho Khách (Guest) | **Pass** |
| **AUTH-002** | P0 | Chưa đăng nhập | Vào Đăng ký, nhập Họ tên, MSSV, Email HUTECH, Mật khẩu | Tài khoản được tạo thành công, tự động khởi tạo hồ sơ và đồng bộ lên Supabase | **Pass** |
| **AUTH-003** | P1 | Form Đăng ký | Nhập email sai định dạng hoặc mật khẩu trống | Hệ thống hiển thị thông báo lỗi xác thực dữ liệu (Validation), không gửi request sai | **Pass** |
| **AUTH-004** | P0 | Đã có tài khoản sinh viên | Đăng nhập tài khoản sinh viên | Đăng nhập thành công, chuyển hướng về trang chủ/sự kiện, hiển thị menu cá nhân sinh viên | **Pass** |
| **AUTH-005** | P0 | Đã có tài khoản Admin | Đăng nhập bằng `admin@hutech.edu.vn` | Đăng nhập thành công, hiển thị thanh điều hướng Quản trị (Tổng quan, Sự kiện, Điểm danh QR) | **Pass** |
| **AUTH-006** | P0 | Sinh viên đang đăng nhập | Cố tình truy cập trực tiếp URL `/admin` | Hệ thống bảo vệ tuyến đường (Route Guard), tự động chặn và đẩy về trang đăng nhập/thông báo lỗi quyền | **Pass** |
| **AUTH-007** | P1 | Đã đăng nhập | Đóng trình duyệt hoặc tắt app rồi mở lại | Phiên đăng nhập (Session) được duy trì tự động, không bắt đăng nhập lại | **Pass** |

---

### Phân hệ 2: Khám phá, Tìm kiếm, Lọc & Đề xuất Sự kiện (Discovery & AI Matching)

| ID | Ưu tiên | Tiền điều kiện | Các bước thực hiện | Kết quả mong đợi | Kết quả |
| :--- | :---: | :--- | :--- | :--- | :---: |
| **EVT-001** | P0 | Đã mở ứng dụng | Xem Banner/Carousel sự kiện nổi bật trên trang chủ | Carousel tự động chuyển slide mỗi 3s; rê chuột/chạm giữ thì tạm dừng, buông ra tiếp tục sau 5s | **Pass** |
| **EVT-002** | P0 | Danh sách sự kiện | Gõ từ khóa tìm kiếm (Ví dụ: "Flutter", "AI", "HUTECH") | Danh sách lọc tức thì theo thời gian thực; xóa từ khóa danh sách trở lại ban đầu | **Pass** |
| **EVT-003** | P1 | Danh sách sự kiện | Lọc theo Danh mục (Học thuật, Kỹ năng, Thể thao) và Cơ sở (Khu A-B, Khu E) | Chỉ hiển thị các sự kiện thỏa mãn cả 2 bộ lọc, không bị lỗi dữ liệu rỗng | **Pass** |
| **EVT-004** | P0 | Chọn 1 sự kiện | Nhấp vào Card sự kiện để xem chi tiết | Hiển thị đầy đủ Banner, Thời gian, Địa điểm, Sức chứa, Mô tả chi tiết, Kỹ năng đạt được | **Pass** |
| **EVT-005** | P1 | Đăng nhập tài khoản sinh viên | Xem mục "Vì sao phù hợp với bạn?" trên chi tiết sự kiện | Hệ thống hiển thị điểm phù hợp (Match Score /100) kèm lý do giải thích minh bạch dựa trên ngành học và kỹ năng | **Pass** |
| **EVT-006** | P1 | Chi tiết sự kiện | Bấm vào ảnh sự kiện | Mở trình xem ảnh toàn màn hình, hỗ trợ thao tác phóng to (Zoom), kéo và đặt lại kích thước | **Pass** |

---

### Phân hệ 3: Đăng ký Sự kiện, Danh sách chờ & Cảnh báo Trùng lịch (Registration & Timetable)

| ID | Ưu tiên | Tiền điều kiện | Các bước thực hiện | Kết quả mong đợi | Kết quả |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **REG-001** | P0 | Sự kiện còn chỗ, chưa hết hạn | Sinh viên nhấn "Đăng ký tham gia" | Đăng ký thành công; số chỗ đã đăng ký tăng lên; sự kiện tự động thêm vào Lịch cá nhân | **Pass** |
| **REG-002** | P0 | Đã có lịch học/sự kiện khác cùng giờ | Sinh viên đăng ký sự kiện mới trùng giờ | Hệ thống bật hộp thoại cảnh báo xung đột lịch trình kèm khoảng cách di chuyển giữa các cơ sở | **Pass** |
| **REG-003** | P0 | Sự kiện đã đủ số lượng (Full) | Sinh viên nhấn đăng ký vào sự kiện đã đầy chỗ | Hệ thống xếp sinh viên vào Danh sách chờ (Waitlist) theo thứ tự ưu tiên thời gian (FIFO) | **Pass** |
| **REG-004** | P0 | Có người trong danh sách chờ | Một sinh viên chính thức nhấn "Hủy đăng ký" | Suất trống được tự động chuyển nhượng cho người đầu tiên trong hàng chờ; gửi thông báo thăng hạng | **Pass** |
| **REG-005** | P1 | Đã đăng ký sự kiện | Vào mục "Vé tham gia" (`/my-events`) | Hiển thị danh sách vé đã xác nhận, vé hàng chờ và lịch sử tham gia rõ ràng | **Pass** |

---

### Phân hệ 4: Vé điện tử & Quét mã QR Điểm danh an toàn (Check-in & QR)

| ID | Ưu tiên | Tiền điều kiện | Các bước thực hiện | Kết quả mong đợi | Kết quả |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **CHK-001** | P0 | Đã đăng ký thành công | Sinh viên bấm "Xem vé của tôi" | Hiển thị vé điện tử HUTECH sang trọng chứa Mã QR tham chiếu, thông tin sinh viên, thời gian, cơ sở | **Pass** |
| **CHK-002** | P0 | Admin mở `/admin/checkin` | Hướng camera máy quét vào mã QR trên vé sinh viên | Camera quét tức thì bằng `mobile_scanner`, xác thực mã vé hợp lệ và đổi trạng thái sang "Đã tham gia" | **Pass** |
| **CHK-003** | P0 | Vé đã được điểm danh | Quét lại mã QR của vé đó lần thứ hai | Hệ thống cảnh báo: "Vé này đã được điểm danh trước đó", không tính trùng | **Pass** |
| **CHK-004** | P1 | Quét vé của sự kiện khác | Điểm danh vé sự kiện A tại phiên của sự kiện B | Hệ thống báo lỗi: "Vé này thuộc sự kiện khác, không đúng sự kiện đang điểm danh" | **Pass** |
| **CHK-005** | P1 | Thiết bị không có camera | Nhập mã vé thủ công vào ô tìm kiếm và bấm "Xác nhận điểm danh" | Điểm danh thành công, cập nhật trực tiếp vào bảng danh sách có mặt | **Pass** |
| **CHK-006** | P1 | Trong màn hình điểm danh | Theo dõi thống kê thời gian thực | Bộ đếm Có mặt, Vắng mặt và Tỷ lệ tham dự (%) cập nhật trực tiếp | **Pass** |

---

### Phân hệ 5: Khảo sát Đánh giá, Giấy chứng nhận & Học liệu (Certificates & Feedback)

| ID | Ưu tiên | Tiền điều kiện | Các bước thực hiện | Kết quả mong đợi | Kết quả |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **CERT-001** | P0 | Sinh viên đã được điểm danh (`attended`) | Vào chi tiết sự kiện, bấm "Nhận Giấy chứng nhận" | Hiển thị Giấy chứng nhận HUTECH điện tử sang trọng có Mã xác thực độc bản, Tên SV, MSSV, Kỹ năng | **Pass** |
| **CERT-002** | P1 | Đang mở Giấy chứng nhận | Bấm nút "Tải chứng nhận PDF" | Xuất tệp PDF chứng nhận chất lượng cao, có thể lưu trữ và in ấn | **Pass** |
| **FEED-001** | P0 | Sinh viên đã được điểm danh | Bấm nút "Đánh giá sự kiện" | Mở form đánh giá 4 tiêu chí (Hài lòng chung, Nội dung, Diễn giả, Khâu tổ chức) từ 1-5 sao kèm nhận xét | **Pass** |
| **DOC-001** | P1 | Mở chi tiết sự kiện | Cuộn tới mục "Tài liệu & Học liệu sự kiện" | Hiển thị Slide PDF và Link kho mã nguồn thực hành; bấm Tải về/Mở link hoạt động chuẩn xác | **Pass** |
| **QA-001** | P0 | Mở chi tiết sự kiện | Đặt câu hỏi trong phần Q&A trực tiếp | Câu hỏi hiển thị ngay; Admin/Ban tổ chức có thể trả lời và Ghim thông báo quan trọng lên đầu | **Pass** |

---

### Phân hệ 6: Quản trị (Admin CMS) & Ngoại tuyến (Offline-First)

| ID | Ưu tiên | Tiền điều kiện | Các bước thực hiện | Kết quả mong đợi | Kết quả |
| :--- | :---: | :--- | :--- | :--- | :--- |
| **ADM-001** | P0 | Quyền Admin | Mở `/admin/events/new`, nhập thông tin và tải ảnh sự kiện | Sự kiện mới được tạo thành công, tự động hiển thị trên Web và Mobile | **Pass** |
| **ADM-002** | P0 | Quyền Admin | Mở màn hình Người tham gia (`/admin/participants`) | Xem đầy đủ danh sách sinh viên đăng ký; có nút sao chép CSV và xuất dữ liệu | **Pass** |
| **ADM-003** | P1 | Quyền Admin | Mở hộp thoại "Cơ sở dữ liệu", bấm Xuất JSON sao lưu | Xuất toàn bộ dữ liệu hệ thống ra tệp JSON an toàn; có khả năng khôi phục (Restore) khi cần | **Pass** |
| **OFF-001** | P0 | Mất kết nối Internet | Thao tác chuyển trang, xem sự kiện, xem vé đã tải | Ứng dụng chạy mượt mà từ bộ nhớ đệm (IndexedDB trên Web / SQLite trên Android), không bị màn hình trắng | **Pass** |
