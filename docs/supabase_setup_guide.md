# HƯỚNG DẪN CẤU HÌNH SUPABASE CHO HỆ THỐNG QUẢN LÝ SỰ KIỆN HUTECH

Tài liệu này dành cho người mới bắt đầu làm quen với Supabase, hướng dẫn từng bước từ tạo dự án đến chạy ứng dụng thực tế.

---

## 1. Cách tạo Project Supabase

1. Truy cập [https://supabase.com/](https://supabase.com/) và đăng nhập (hoặc đăng ký bằng GitHub/Google).
2. Tại màn hình Dashboard, bấm **New Project**.
3. Điền các thông tin:
   - **Name**: `HUTECH-Event-Intelligence`
   - **Database Password**: Đặt mật khẩu an toàn và lưu lại cẩn thận (không chia sẻ mật khẩu này).
   - **Region**: Chọn khu vực gần Việt Nam nhất (ví dụ: `Singapore (ap-southeast-1)`).
   - **Pricing Plan**: Chọn gói `Free Plan`.
4. Bấm **Create new project** và chờ khoảng 1–2 phút để máy chủ khởi tạo.

---

## 2. Cách lấy Project URL và Publishable Key (Anon Key)

1. Trong giao diện project Supabase, bấm vào biểu tượng bánh răng **Project Settings** ở menu bên trái.
2. Chọn mục **API** (hoặc **Data API**).
3. Tại phần **Project API keys**:
   - Sao chép **Project URL** (dạng `https://xxxx.supabase.co`).
   - Sao chép khóa **`anon` `public`** (Publishable Key).
4. **Cảnh báo bảo mật quan trọng:**
   - Tuyệt đối **KHÔNG** sao chép hoặc đưa khóa `service_role` (secret key) vào ứng dụng Flutter, Git hoặc bất kỳ nơi nào công khai. Khóa `service_role` có quyền vượt qua mọi Row Level Security và chỉ được dùng ở backend server tin cậy.

---

## 3. Cách chạy Migration (Tạo Bảng, RLS, Trigger & RPC)

Hệ thống đã chuẩn bị sẵn các file SQL migration hoàn chỉnh trong thư mục `supabase/migrations/`:
- `supabase/migrations/20261109000000_initial_schema.sql` (Cấu trúc bảng cốt lõi, RLS, Triggers, Storage).
- `supabase/migrations/20261109010000_organizer_and_attendance.sql` (Ban tổ chức, duyệt sự kiện, điểm danh bảo mật, RPC check_in_ticket).
- `supabase/migrations/20261109020000_surveys_certificates_qa.sql` (Cơ sở HUTECH, khảo sát, chứng nhận, hỏi đáp Realtime).

**Cách chạy trên Web Dashboard (SQL Editor):**
1. Trên thanh menu bên trái của Supabase, bấm chọn **SQL Editor**.
2. Bấm nút **+ New query**.
3. Mở file `20261109000000_initial_schema.sql`, sao chép toàn bộ nội dung và dán vào ô soạn thảo.
4. Bấm nút **Run** (màu xanh lá) ở góc dưới bên phải. Chờ hiển thị `Success. No rows returned`.
5. Tiếp tục lặp lại bước 3 & 4 lần lượt cho các file:
   - `20261109010000_organizer_and_attendance.sql`
   - `20261109020000_surveys_certificates_qa.sql`
6. Vào mục **Table Editor** ở menu bên trái để thấy đầy đủ các bảng đã được tạo.

---

## 4. Cách tạo và kiểm tra Storage Buckets

File migration đã tự động tạo 3 bucket:
- `event-images` (Công khai: Public)
- `avatars` (Công khai: Public)
- `event-documents` (Riêng tư: Private)

**Cách kiểm tra trên giao diện:**
1. Vào mục **Storage** ở menu bên trái.
2. Xác nhận danh sách có 3 bucket trên.
3. Nếu chưa có, bạn có thể bấm **New bucket**, nhập tên `event-images`, bật công tắc `Public bucket` và bấm **Save bucket**.

---

## 5. Cách bật Supabase Realtime

1. Vào mục **Database** ở menu bên trái, chọn tab **Replication**.
2. Tại bảng danh sách các bảng (Source Tables):
   - Bật Realtime cho các bảng cần đồng bộ tức thì: `events`, `registrations`, `waitlist`, `event_questions`, `event_answers`.
3. Bấm **Save** để áp dụng.

---

## 6. Cách tạo tài khoản Admin đầu tiên an toàn

Do hệ thống đã kích hoạt Row Level Security (RLS) để chặn người dùng tự nâng quyền, tài khoản quản trị viên phải được gán quyền thông qua SQL hoặc Dashboard:

1. Đăng ký tài khoản trên ứng dụng hoặc vào mục **Authentication** -> **Users** -> **Add user** -> Nhập email (ví dụ: `admin@hutech.edu.vn`) và mật khẩu.
2. Lấy `User UID` của người dùng vừa tạo (chuỗi UUID).
3. Vào **SQL Editor**, chạy câu lệnh sau:
   ```sql
   INSERT INTO public.user_roles (user_id, role_id)
   SELECT 
       'ĐIỀN_USER_UID_VÀO_ĐÂY'::uuid, 
       id 
   FROM public.roles 
   WHERE code = 'admin'
   ON CONFLICT (user_id, role_id) DO NOTHING;
   ```
4. Bây giờ, khi tài khoản này đăng nhập vào ứng dụng, hệ thống sẽ tự động cấp quyền Admin.

---

## 7. Cấu hình Web Redirect URL

Khi người dùng nhấn liên kết kích hoạt email hoặc đổi mật khẩu từ hộp thư:
1. Vào mục **Authentication** -> **URL Configuration**.
2. Tại **Site URL**, nhập địa chỉ chạy ứng dụng của bạn (ví dụ: `http://localhost:8080` hoặc domain triển khai).
3. Tại **Redirect URLs**, thêm các đường dẫn:
   - `http://localhost:8080/**`
   - `http://127.0.0.1:8080/**`
4. Bấm **Save**.

---

## 8. Cách chạy ứng dụng với Supabase

### 8.1 Chạy trên trình duyệt Chrome (Web):
Mở terminal tại thư mục `dack` và chạy lệnh với cờ `--dart-define`:

```powershell
flutter run -d chrome --web-port 8080 `
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJh...
```

*(Nếu không truyền tham số, ứng dụng sẽ tự động chạy ở chế độ lưu trữ cục bộ Offline/Local Device Storage mà không báo lỗi).*

### 8.2 Chạy trên Android Studio (Máy ảo Pixel hoặc Thiết bị thật):
1. Trong Android Studio, mở menu **Run** -> **Edit Configurations...**
2. Tại mục **Additional run args**, dán vào:
   ```text
   --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=eyJh...
   ```
3. Bấm **OK**, chọn thiết bị Android (Pixel 6 API 34/35) và bấm nút **Run**.

---

## 9. Cách kiểm tra Row Level Security (RLS)

Để chứng minh RLS hoạt động và bảo vệ dữ liệu:
1. Vào **SQL Editor**, thử chạy câu truy vấn giả lập người dùng sinh viên:
   ```sql
   SET LOCAL ROLE authenticated;
   SET LOCAL request.jwt.claims = '{"sub": "user-uuid-sinh-vien"}';
   
   -- Thử sửa sự kiện của Admin:
   UPDATE public.events SET title = 'Bị hack' WHERE id = 'event-id-cua-admin';
   -- Kết quả: UPDATE 0 (RLS tự động chặn không cho sửa)
   ```
2. Thử truy vấn đọc các sự kiện nháp/chờ duyệt với tư cách Khách:
   ```sql
   SET LOCAL ROLE anon;
   SELECT * FROM public.events WHERE status = 'draft';
   -- Kết quả: 0 rows (RLS chặn không trả về bản nháp)
   ```

---

## 10. Cách Backup dữ liệu

1. **Sao lưu tự động**: Gói Free của Supabase tự động sao lưu cấu hình định kỳ.
2. **Xuất file SQL sao lưu**:
   - Vào **Database** -> **Backups**.
   - Hoặc dùng công cụ Supabase CLI trên máy tính:
     ```bash
     supabase db dump -f backup_hutech_event.sql
     ```
   - Trong ứng dụng Flutter, Admin có thể sử dụng chức năng **Xuất bản sao lưu dữ liệu** để tải về file JSON chứa toàn bộ dữ liệu hiện hành.
