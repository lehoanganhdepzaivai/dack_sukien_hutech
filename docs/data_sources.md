# Nguồn dữ liệu và tài nguyên

Cập nhật: 15/10/2026. Tài liệu này ghi nguồn phục vụ bảo trì và báo cáo đồ án. Giao diện không hiển thị nhãn demo theo yêu cầu trực tiếp của người dùng.

## Logo

Người dùng cung cấp hai ảnh tham chiếu: bản wordmark đầy đủ `codex-clipboard-76222370-6105-4e97-ab44-94d8ca2f7902.png` và bản khiên `codex-clipboard-fd8313b8-c334-4d9c-a4d0-d8cd882efe61.png`. Bản bitmap đầy đủ được giữ tại `assets/images/hutech_logo.png` để đối chiếu, nhưng không còn dùng làm logo trong các ô giao diện nhỏ.

Biểu trưng đang hiển thị trong Flutter được vẽ bằng `CustomPainter`, `Path` và `TextPainter` tại `lib/widgets/hutech_logo.dart`, dựa trên bản khiên người dùng cung cấp. Nó có nền trong suốt, gồm khiên xanh, mảng vàng, chữ trắng và ngọn đuốc đỏ. `web/hutech_mark.svg` mô tả cùng hình học để dùng cho trang chờ trước frame Flutter, favicon và manifest PWA. Đây là bản dựng lại phục vụ giao diện đồ án, không phải tệp vector chính thức do HUTECH phát hành. Việc sử dụng biểu trưng không có nghĩa hệ thống được nhà trường phát hành hoặc xác nhận.

## Dữ liệu khởi tạo

Nguồn: yêu cầu trực tiếp của người dùng cho phép tạo tài khoản, hồ sơ, lịch học và nội dung ban đầu để thử giao diện. File: `lib/data/prototype_seed.dart`.

- `HA@gmail.com`, mật khẩu cục bộ `123`: vai trò sinh viên, tên Hoàng Anh, mã sinh viên và thông tin học tập do hệ thống tự tạo theo yêu cầu, có lịch học, sở thích, mục tiêu nghề nghiệp và sự kiện đã đăng ký.
- `admin@gmail.com`, mật khẩu cục bộ `123`: vai trò quản trị.
- Hai địa điểm `HUTECH khu A, B` và `HUTECH khu E` lấy đúng phạm vi tên do người dùng yêu cầu; chưa có địa chỉ bưu chính, tọa độ hoặc dịch vụ bản đồ.
- Tên, thời gian, sức chứa, mô tả của các sự kiện khởi tạo là nội dung giả lập, không phải thông báo sự kiện có thật của HUTECH. Ngày sự kiện ban đầu được tính từ ngày khởi tạo kho cục bộ.
- Tên các nhóm tổ chức trong sự kiện khởi tạo mang tính mô tả, không được coi là đơn vị chính thức do HUTECH xác nhận. Không bịa danh tính diễn giả, số người tham dự hoặc kết quả khảo sát.
- Danh sách kỹ năng và mục tiêu nghề nghiệp là bộ phân loại phục vụ prototype, có thể mở rộng; không tuyên bố đã bao quát mọi kỹ năng hoặc là chuẩn đầu ra chính thức.
- Kỹ năng trong hồ sơ ban đầu là tự khai báo. Không dùng chúng làm chứng cứ điểm danh, năng lực được kiểm định hoặc chứng nhận của nhà trường.
- Kho lưu cục bộ không gửi email và không tạo tài khoản Gmail hoặc Supabase cho những địa chỉ trên.

## Danh mục khoa, viện và trường trực thuộc

Đã tra cứu các trang chính thức của HUTECH ngày 15/10/2026. Danh mục phục vụ lựa chọn trong hồ sơ, không dùng để tự gán một sự kiện giả lập cho một khoa/viện thực tế.

| Nguồn chính thức | Cách sử dụng |
|---|---|
| [Trang chủ HUTECH](https://www.hutech.edu.vn/) | Menu Trường – Khoa – Viện và Đào tạo Quốc tế; nguồn chính cho tên danh mục |
| [Tuyển sinh đại học](https://www.hutech.edu.vn/tuyensinh/daihoc) | Đối chiếu tên đơn vị trong menu hiện hành |
| [Thành lập Trường Kỹ thuật HUTECH, 08/09/2026](https://www.hutech.edu.vn/qlcntt/thong-tin-su-kien/14635243-hutech-thanh-lap-truong-ky-thuat-hutech-tang-cuong-lien-ket-cac-linh-vuc-ky-thuat-cong-nghe) | Đối chiếu việc tổ chức lại Viện Kỹ thuật và bốn khoa thuộc khối kỹ thuật |
| [Khoa Kiến trúc – Xây dựng](https://www.hutech.edu.vn/khoaktxd) | Kiểm tra tên hiện hành thay cho hai tên cũ riêng biệt |
| [Tổng quan về trường](https://www.hutech.edu.vn/homepage/gioi-thieu-hutech) | Nguồn đối chiếu lịch sử; một số tên khác menu hiện hành nên không gộp cơ học thành danh mục trùng |

Danh sách khoa đã đối chiếu:

| STT | Tên |
|---|---|
| 1 | Khoa Công nghệ thông tin |
| 2 | Khoa Luật |
| 3 | Khoa Quản trị kinh doanh |
| 4 | Khoa Tiếng Anh |
| 5 | Khoa Thẩm mỹ và Khoa học sự sống |
| 6 | Khoa Truyền thông và Thiết kế |
| 7 | Khoa Hệ thống thông tin quản lý |
| 8 | Khoa Tài chính - Thương mại |
| 9 | Khoa Nhật Bản học |
| 10 | Khoa Điều dưỡng - Kỹ thuật y học |
| 11 | Khoa Trung Quốc học |
| 12 | Khoa Kiến trúc - Xây dựng |
| 13 | Khoa Hàn Quốc học |
| 14 | Khoa Thú y |
| 15 | Khoa Quản trị Du lịch - Nhà hàng - Khách sạn |
| 16 | Khoa Dược |
| 17 | Khoa Khoa học Xã hội và Quan hệ Công chúng |
| 18 | Khoa Y |
| 19 | Khoa Marketing - Kinh doanh quốc tế |
| 20 | Khoa Điện - Điện tử |
| 21 | Khoa Cơ khí - Tự động hóa |
| 22 | Khoa Công nghệ Ô tô |

Danh sách viện và trường trực thuộc tham khảo:

| STT | Tên |
|---|---|
| 1 | Viện Văn hóa - Nghệ thuật - Thể thao |
| 2 | Viện Đào tạo Sau Đại học |
| 3 | Viện Công nghệ CIRTECH |
| 4 | Viện Đại học Mở HUTECH |
| 5 | Viện Công nghệ cao HUTECH |
| 6 | Viện Đào tạo Quốc tế |
| 7 | Viện Công nghệ Việt - Nhật |
| 8 | Viện Công nghệ Việt - Hàn |
| 9 | Trường Kỹ thuật HUTECH |
| 10 | Trường Y và Khoa học Sức khỏe |

Các trang chính thức chưa đồng nhất hoàn toàn: menu còn tên Viện Kỹ thuật trong khi thông báo tháng 9/2026 dùng Trường Kỹ thuật; trang Tổng quan còn một số tên cũ. Danh mục hiện tại ưu tiên thông báo mới và tên khoa đang được sử dụng. Không khẳng định đây là toàn bộ sơ đồ tổ chức pháp lý của trường. Khi nhập dữ liệu thật cần cho người quản trị đối chiếu lần nữa.

Đối chiếu mã nguồn ngày 16/10/2026: `PrototypeSeed.faculties` chứa 22 khoa và 8 viện ở trên. Hai trường trực thuộc được giữ trong tài liệu nguồn để giải thích cơ cấu, chưa được thêm thành lựa chọn riêng trong hồ sơ; hiện chọn đơn vị khoa hoặc viện cụ thể.

## Ảnh tạo riêng

Công cụ: built-in `image_gen`, chế độ tạo mới; không dùng CLI/API key. Ngày tạo: 15/10/2026. Ảnh là minh họa nghệ thuật, không phải ảnh tư liệu của trường hoặc sự kiện có thật. Cả ba ảnh đều được kiểm tra trực quan: bảng màu xanh/vàng/trắng, không chữ, không logo, không watermark.

| File | Kích thước | Nơi sử dụng |
|---|---|---|
| `assets/images/technology.png` | 1672 × 941 | Sự kiện học thuật, công nghệ và nghề nghiệp |
| `assets/images/community.png` | 1672 × 941 | Banner đăng nhập; kỹ năng, cộng đồng và hoạt động sinh viên |
| `assets/images/music.png` | 1672 × 941 | Sự kiện âm nhạc và banner nổi bật |

Prompt cuối cùng cho `technology.png`:

```text
Use case: stylized-concept. Asset type: wide editorial illustration for a university student events website hero and event card, landscape 16:9. Create a polished artistic 3D paper-and-clay-style scene of a Vietnamese university technology workshop: three adult university students collaboratively building a small robot and experimenting with a laptop, geometric glass UI panels without writing, rounded architectural learning space, thoughtful warm expressions. Sophisticated cobalt blue, sunflower yellow and soft white palette, subtle midnight navy and cyan shadows, tactile matte materials, beautiful soft white light, detailed premium composition. Main focus in the middle-right, elegant airy space at left for HTML title overlay. Must read as designed illustration, not documentary photography. No text, no letters, no numbers, no logos, no badges, no watermark. No real institution architecture or branding.
```

Prompt cuối cùng cho `community.png`:

```text
Use case: stylized-concept. Asset type: wide editorial illustration for a university student events website and login banner, landscape 16:9. Create a polished artistic 3D paper-and-clay-style scene of six diverse Vietnamese adult university students in a bright modern generic campus courtyard, talking, carrying notebooks, exchanging ideas around a round collaboration table. One student draws simple geometric ideas, one plays a guitar casually, generous greenery and sculptural rounded campus architecture. Cheerful but refined, premium editorial craftsmanship, inviting beautiful soft white sunlight. Cobalt blue, sunflower yellow and luminous white palette with restrained green plants. Centre-weighted group usable in wide hero and portrait crops, layered depth, warm confident sense of belonging. Designed illustration, not documentary photography. No text, no letters, no numbers, no logos, no badges, no watermark, no real institution architecture or branding.
```

Prompt cuối cùng cho `music.png`:

```text
Use case: stylized-concept. Asset type: landscape 16:9 event card and hero illustration for a university student music night. Create a premium polished artistic 3D paper-and-clay-style illustration of a music stage, small student band of adults with vocalist, guitar and drums, joyous student audience silhouettes from behind in the foreground, sweeping ribbons of golden light, sculptural speaker stacks and circular light arches. Cobalt blue and midnight navy scene with vivid sunflower yellow lights and soft luminous white beams, tasteful energetic composition with dimensional depth and matte tactile materials. Wide composition, avoid overly cluttered instruments or harsh saturated rainbow colors. This is an original symbolic illustration not a photograph of an actual event. No text, no letters, no numbers, no logos, no badges, no watermark.
```

## Font tiếng Việt

Noto Sans của The Noto Project Authors, bản TTF tĩnh, tải từ kho chính thức đã được lưu trữ ở trạng thái chỉ đọc. Font được lưu cùng ứng dụng để xuất PDF không cần tải font qua mạng:

- `assets/fonts/NotoSans-Regular.ttf`: [file nguồn](https://raw.githubusercontent.com/notofonts/noto-fonts/main/hinted/ttf/NotoSans/NotoSans-Regular.ttf).
- `assets/fonts/NotoSans-Bold.ttf`: [file nguồn](https://raw.githubusercontent.com/notofonts/noto-fonts/main/hinted/ttf/NotoSans/NotoSans-Bold.ttf).
- `assets/fonts/OFL.txt`: bản giấy phép SIL Open Font License 1.1 được giữ nguyên từ [giấy phép nguồn](https://github.com/notofonts/noto-fonts/blob/main/LICENSE).

Không chỉnh sửa hoặc đổi tên nội bộ font. Giữ file giấy phép khi phân phối tài nguyên font cùng mã nguồn ứng dụng.

SHA-256 khi tải:

```text
NotoSans-Regular.ttf  B85C38ECEA8A7CFB39C24E395A4007474FA5A4FC864F6EE33309EB4948D232D5
NotoSans-Bold.ttf     C976E4B1B99EDC88775377FCC21692CA4BFA46B6D6CA6522BFDA505B28FF9D6A
```
