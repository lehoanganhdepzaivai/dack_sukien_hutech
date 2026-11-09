# Chạy HUTECH Events trên điện thoại Android

## 1. Mở đúng thư mục dự án

Trong Android Studio, chọn **File > Open** rồi mở đúng thư mục:

```text
E:\HoangAnh_DACK\dack
```

Thư mục này phải hiện trực tiếp các mục `lib`, `android`, `pubspec.yaml`. Không mở riêng thư mục `android` và không mở thư mục cha `E:\HoangAnh_DACK`.

Sau khi mở dự án, chờ Android Studio chạy xong **Indexing** và tải các gói. Nếu IDE hỏi Dart SDK hoặc Flutter SDK, đặt Flutter SDK là:

```text
C:\src\flutter
```

## 2. Hiện máy ảo ở bên phải Android Studio

Vào **File > Settings > Tools > Emulator** và bật:

```text
Launch in the Running Devices tool window
```

Sau đó mở **Tools > Device Manager**, tìm Pixel 6 và bấm nút tam giác ở dòng thiết bị. Khi điện thoại khởi động xong, cửa sổ **Running Devices** sẽ xuất hiện ở bên phải.

Điện thoại hiện ở bên phải chỉ là cách Android Studio đặt cửa sổ máy ảo. Ứng dụng vẫn là ứng dụng Android Flutter, không phải giao diện web.

## 3. Chạy bằng nút tam giác

Trên thanh công cụ phía trên:

1. Ở ô thiết bị, chọn **Pixel 6 (mobile)** hoặc tên Pixel đang chạy.
2. Ở ô cấu hình, chọn **HUTECH Android**.
3. Bấm nút tam giác **Run** hoặc nhấn `Shift + F10`.

Cấu hình **HUTECH Android** đã được đặt để chạy đúng tệp:

```text
E:\HoangAnh_DACK\dack\lib\main.dart
```

Cấu hình cũng đã có tham số `--no-pub`, vì vậy nút Run dùng ngay các gói đã được cài và không gọi lại `flutter pub get`. Cách này tránh lỗi tạo symbolic link khi Windows Developer Mode đang tắt.

Lần chạy đầu có thể mất vài phút vì Gradle cần biên dịch và cài ứng dụng. Khi thấy `Installing build\app\outputs\flutter-apk\app-debug.apk` thì tiếp tục chờ; ứng dụng sẽ tự mở trên Pixel.

Nếu sau này bạn thêm, xóa hoặc đổi phiên bản thư viện trong `pubspec.yaml`, hãy bật **Windows Developer Mode** rồi chạy riêng lệnh sau trong Terminal của Android Studio trước khi bấm Run:

```powershell
flutter pub get
```

Bạn có thể mở Developer Mode từ **Settings > System > For developers > Developer Mode**. Sau khi tải gói xong, cấu hình **HUTECH Android** tiếp tục chạy bình thường với `--no-pub`.

## 4. Nếu nút tam giác bị tối

Kiểm tra lần lượt:

1. Pixel 6 đã bật và đã vào màn hình chính.
2. Ô thiết bị phía trên đã chọn Pixel 6, không chọn Chrome.
3. Ô cấu hình đã chọn **HUTECH Android**.
4. Android Studio không còn hiển thị **Indexing** ở thanh trạng thái.
5. Tệp `lib/main.dart` đang có trong dự án.

Nếu chưa thấy cấu hình, đóng rồi mở lại Android Studio bằng đúng thư mục `E:\HoangAnh_DACK\dack`.

## 5. Nếu máy ảo đứng ở logo hoặc ứng dụng không hiện

Vào **Tools > Device Manager**, bấm menu ba chấm của Pixel 6 và chọn **Cold Boot Now**. Chờ Pixel vào màn hình chính rồi chọn lại **HUTECH Android** và bấm Run.

Nếu Run vẫn đang chạy dở, bấm nút vuông đỏ **Stop** một lần, chờ vài giây rồi bấm Run lại. Không mở đồng thời hai lần chạy cùng một ứng dụng.

## 6. Các dòng đỏ nào có thể chỉ là cảnh báo

Những dòng có chữ `WARNING`, cảnh báo Java 8 hoặc cảnh báo SDK XML có thể được Android Studio tô đỏ nhưng không đồng nghĩa ứng dụng bị lỗi. Hãy nhìn dòng cuối của cửa sổ Run:

- `Built ... app-debug.apk`, `Installing...` hoặc `Syncing files to device` nghĩa là tiến trình đang tiếp tục.
- `BUILD FAILED`, `Error launching application` hoặc `Gradle task assembleDebug failed` mới là lỗi làm ứng dụng không chạy.

