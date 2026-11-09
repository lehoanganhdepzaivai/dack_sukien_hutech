# Supabase cho người mới — kế hoạch bước tiếp theo

Bản hiện tại **chưa kết nối Supabase** và không gọi API nghiệp vụ bên ngoài. Đăng nhập dùng `LocalAuthService`; dữ liệu sự kiện lưu bằng IndexedDB trên web hoặc tệp JSON cục bộ trên Android/desktop; ảnh dùng asset hoặc file người dùng chọn; PDF, QR, biểu đồ và lịch được dựng tại client. `EventImage` có nhánh hỗ trợ `Image.network`, nhưng seed và form hiện tại không dùng URL ảnh mạng. Tài liệu này giải thích bước tiếp theo; không phải bằng chứng Authentication, Database, Storage hoặc RLS đã chạy.

## Supabase sẽ làm gì?

Supabase cung cấp PostgreSQL để lưu sự kiện và hồ sơ trực tuyến, Auth để đăng nhập, Storage để lưu ảnh và các chính sách RLS để hạn chế dữ liệu theo người dùng. Flutter sẽ gọi repository/service thay vì truy vấn trực tiếp rải rác trong widget. Xem [hướng dẫn Flutter chính thức](https://supabase.com/docs/guides/getting-started/quickstarts/flutter).

## Chuẩn bị dự án

1. Kiểm tra và duyệt ERD trong `docs/phase_1_design.md` trước khi tạo migration.
2. Tạo tài khoản của bạn tại [Supabase Dashboard](https://supabase.com/dashboard), tạo tổ chức và dự án cho đồ án. Giữ mật khẩu cơ sở dữ liệu trong trình quản lý mật khẩu; không dán mật khẩu vào source hoặc chat.
3. Lấy Project URL và publishable key từ bảng Connect của dự án. Đây là thông tin cần cho Flutter sau khi triển khai adapter Supabase.
4. Chọn xác thực email/mật khẩu; cấu hình địa chỉ web phát triển và địa chỉ web triển khai làm URL chuyển hướng phù hợp.
5. Sau khi ERD được duyệt, tạo migration có khóa, ràng buộc, index, RLS và transaction nghiệp vụ. Dữ liệu giả lập phải nằm trong seed riêng, không nhập lẫn vào dữ liệu chính thức.

Chưa có thao tác tạo dự án, chạy SQL hay đổi cấu hình Supabase nào được thực hiện trong lần triển khai prototype này.

## Tài khoản và mật khẩu

Hai tài khoản `HA@gmail.com / 123` và `admin@gmail.com / 123` chỉ được kiểm tra trong ứng dụng cục bộ. Chúng chưa tồn tại trong Supabase. Khi dùng backend thật, người dùng cần email mà mình kiểm soát và mật khẩu đáp ứng cấu hình Auth; không giữ mật khẩu ba ký tự `123`. Supabase khuyến nghị tối thiểu tám ký tự trở lên và hỗ trợ chính sách độ mạnh mật khẩu. Không tạo bảng mật khẩu trong public schema; Supabase Auth quản lý thông tin xác thực. Xem [Password security](https://supabase.com/docs/guides/auth/password-security).

Admin đầu tiên phải được gán vai trò bằng thao tác tin cậy trên máy chủ hoặc quản trị dự án. Không cho sinh viên tự chọn quyền admin lúc đăng ký, và không tin cờ admin gửi từ trình duyệt.

## Khóa và cấu hình môi trường

Flutter chỉ dùng **publishable key** phù hợp cho client (hoặc anon key cũ khi dự án dùng định dạng cũ). `service_role`, secret key, mật khẩu PostgreSQL và khóa ký token không được đưa vào Dart, asset, file web build hoặc Git. Publishable key không thay thế RLS: dữ liệu người dùng vẫn cần chính sách quyền tại máy chủ. Xem [API keys](https://supabase.com/docs/guides/getting-started/api-keys).

Đề xuất hai tên cấu hình build cho giai đoạn tích hợp: `SUPABASE_URL` và `SUPABASE_PUBLISHABLE_KEY`. Chưa có adapter Supabase đọc hai biến này trong bản cục bộ; truyền cờ `--dart-define` lúc này không tự kết nối backend. Khi bổ sung adapter, dùng file cấu hình riêng bị Git bỏ qua và cơ chế `--dart-define-from-file`; file mẫu trong Git chỉ chứa giá trị trống. Build web luôn để người dùng đọc được cấu hình client, nên tuyệt đối không truyền khóa bí mật bằng cách này.

## Quyền dữ liệu cần kiểm thử

RLS phải được bật trên các bảng được mở qua Data API. Policy đọc sự kiện công khai khác policy đọc hồ sơ/lịch học. Sinh viên chỉ đọc/ghi dữ liệu cá nhân theo `auth.uid()`, người tổ chức chỉ quản lý sự kiện được phân công, admin được cấp quyền rõ ràng. Chặn tự nâng vai trò. Xem [Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security).

Các thao tác tranh chấp chỗ đăng ký, đẩy hàng đợi, tiêu thụ token điểm danh một lần cần transaction/RPC ở máy chủ. RLS và route guard phía Flutter không đủ thay thế các kiểm tra này.

## Ảnh và Storage

Thiết kế bucket ảnh sự kiện và ảnh đại diện riêng. Quyền ghi ảnh sự kiện thuộc admin hoặc người tổ chức được phân công; ảnh hồ sơ thuộc chủ tài khoản. Đường dẫn object cần gắn với UUID có thể kiểm tra quyền. Cần kiểm tra MIME thực, giới hạn dung lượng, quyền thay/xóa, ảnh dự phòng khi tải lỗi. Bản hiện tại chỉ xem trước/lưu ảnh chọn trong trình duyệt, chưa upload Storage. Xem [Storage access control](https://supabase.com/docs/guides/storage/security/access-control).

## Thứ tự tích hợp

1. Auth, khôi phục phiên, đăng ký, đăng xuất và đặt lại mật khẩu thật.
2. Danh mục và sự kiện; Storage cho ảnh.
3. Hồ sơ, lịch học, sở thích và mục tiêu.
4. Đăng ký/hủy/hàng đợi bằng transaction và kiểm thử hai tài khoản đồng thời.
5. QR ngắn hạn dùng một lần, điểm danh theo đồng hồ máy chủ, camera và nhập mã dự phòng.
6. Đánh giá trước/sau, minh chứng kỹ năng, chứng nhận và thống kê từ dữ liệu thật.

Trước khi coi backend hoàn thành, kiểm tra trực tiếp cả quyền API và giao diện với khách, hai sinh viên, hai người tổ chức và admin; kiểm tra cả hành vi bị từ chối. Không triển khai công khai bản đăng nhập cục bộ như một hệ thống đăng ký sự kiện thực tế.
