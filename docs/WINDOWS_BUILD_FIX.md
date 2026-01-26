# Fix Windows Build Issues

## Vấn đề
Lỗi LNK1120 khi build Flutter app với Firebase trên Windows.

## Nguyên nhân
Firebase plugins chưa hỗ trợ tốt cho Windows hoặc thiếu dependencies.

## Giải pháp

### Cách 1: Chạy trên Web (Chrome) - Khuyến nghị
```bash
flutter run -d chrome
```
Web build hoạt động tốt với Firebase và không có vấn đề linker.

### Cách 2: Fix Windows Build (Nếu muốn chạy native)

1. **Cập nhật Visual Studio 2022**
   - Đảm bảo có cài "Desktop development with C++"
   - Cài thêm "C++ CMake tools for Windows"

2. **Clean và rebuild**
   ```bash
   flutter clean
   flutter pub get
   flutter build windows --debug
   ```

3. **Nếu vẫn lỗi**, thử downgrade Firebase packages:
   - Mở `pubspec.yaml`
   - Thay đổi:
     ```yaml
     firebase_core: ^2.24.0
     firebase_auth: ^4.15.0
     cloud_firestore: ^4.13.0
     ```
   - Chạy `flutter pub get`

### Cách 3: Sử dụng emulator Android/iOS
```bash
flutter emulators  # Xem danh sách emulators
flutter run -d <device_id>
```

## Khuyến nghị hiện tại
Sử dụng **Chrome** để test nhanh vì:
- Build nhanh hơn
- Firebase hỗ trợ tốt
- Không có lỗi linker
- Hot reload hoạt động tốt

Khi cần release production cho Windows, sẽ cần giải quyết vấn đề build native.
