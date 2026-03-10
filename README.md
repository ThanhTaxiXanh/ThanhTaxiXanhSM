# 🚕 Thanh Taxi Xanh SM

> **Ứng dụng quản lý thu chi miễn phí dành riêng cho tài xế công nghệ Việt Nam**  
> Offline-first • Bảo mật tuyệt đối • Nhanh dưới 10 giây mỗi thao tác

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](https://flutter.dev)

---

## 📱 Giới Thiệu

**Thanh Taxi Xanh SM** là ứng dụng quản lý tài chính cá nhân được thiết kế riêng cho tài xế công nghệ Việt Nam, đặc biệt là tài xế Xanh SM. App hoạt động hoàn toàn offline, không quảng cáo, không thu thập dữ liệu cá nhân, và miễn phí vĩnh viễn.

### 🎯 Dành Cho Ai?
- Tài xế Xanh SM (mặc định phí nền tảng 18%)
- Tài xế Grab, Be, Gojek (tự cấu hình ví và phí)
- Bất kỳ ai cần quản lý thu chi hàng ngày đơn giản

---

## ✨ Tính Năng Chính

### 💚 Quản Lý Ví
- Tạo mặc định 3 ví khi cài đặt: **Xanh SM** (Tiền Mặt + Thẻ/Ví), **APP Hương Giang**, **Khác**
- Thêm tối đa 10 ví, mỗi ví có nhiều loại tiền riêng
- Cấu hình phí nền tảng theo ví (mặc định 18% cho Xanh SM)

### 💰 Tính Phí Nền Tảng (Xanh SM)
- Chọn khoảng thời gian → tự động tính phí
- Preview chi tiết trước khi xác nhận
- Trừ ưu tiên Thẻ/Ví trước, thiếu mới trừ Tiền Mặt
- Lịch sử đóng phí rõ ràng

### ⚡ Thêm Giao Dịch Siêu Nhanh (<10 giây)
- Bàn phím số lớn, thao tác 1 tay
- Chọn ví, loại tiền, danh mục bằng chip
- Rung + thông báo xác nhận ngay lập tức

### 📅 Lịch Sử & Calendar
- Lịch tháng: hiển thị thu xanh/chi đỏ từng ngày
- Nhấp vào ngày xem chi tiết
- Tổng kết theo ngày, tuần, tháng

### 📊 Thống Kê Trực Quan
- Pie chart theo danh mục và ví (fl_chart)
- So sánh tuần/tháng/năm
- Tổng thu, chi, số dư, số cuốc

### 🤖 AI Insights (Offline)
- So sánh hôm nay vs hôm qua
- Cảnh báo chi vượt 50% thu ngày ⚠️
- Emoji thân thiện: 🚀 🏆 ⚠️ 💡
- Tùy chọn: kết nối Gemini API để phân tích sâu hơn

### 🔐 Bảo Mật
- PIN 4-6 số (lưu an toàn, không plaintext)
- Vân tay / Face ID (tự nhận diện thiết bị hỗ trợ)
- Tất cả dữ liệu lưu local, không lên server

### ☁️ Backup & Xuất Dữ Liệu
- Backup/Restore Google Drive (file JSON mã hóa AES-256)
- Xuất CSV, Excel, JSON — chia sẻ qua bất kỳ app nào

---

## 🚀 Cài Đặt & Chạy

### Yêu Cầu
- Flutter SDK >= 3.22.0 (chạy `flutter --version` để kiểm tra)
- Android SDK / Xcode (cho iOS)
- Dart >= 3.3.0

### Các Bước

```bash
# 1. Clone repo
git clone https://github.com/YOUR_USERNAME/ThanhTaxiXanhSM.git
cd ThanhTaxiXanhSM

# 2. Cài dependencies
flutter pub get

# 3. Generate code (Drift schema + Riverpod providers)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Chạy app
flutter run

# 5. Build APK (Android)
flutter build apk --release
```

### Chạy Tests
```bash
flutter test
flutter test test/unit/
flutter test test/widget/
```

---

## 📁 Cấu Trúc Dự Án

```
lib/
├── core/           # Theme, constants, extensions, utils
├── data/           # Drift database, DAOs, schema
├── features/
│   ├── wallet/     # Quản lý ví
│   ├── transaction/# Thêm & lịch sử giao dịch
│   ├── stats/      # Thống kê & biểu đồ
│   ├── insights/   # AI insights
│   └── settings/   # PIN, backup, danh mục
└── main.dart
```

---

## 📸 Screenshots

> *(Chụp màn hình sau khi chạy app và thêm vào đây)*

| Tổng Quan | Thêm Giao Dịch | Thống Kê | Tính Phí |
|-----------|----------------|----------|----------|
| ![home]() | ![add]()       | ![stats]()|![fee]()  |

---

## 🎨 Design System

| Thuộc Tính | Giá Trị |
|------------|---------|
| Primary | `#00C853` (Xanh SM) |
| Thu nhập | `#00C853` (xanh) |
| Chi tiêu | `#FF5252` (đỏ) |
| Accent | `#FFD600` (vàng) |
| Font min | 16sp |
| Button min | 48dp |
| Currency | VND format `1.000.000đ` |
| Date | `dd/MM/yyyy` + Thứ tiếng Việt |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.22+ |
| State Management | Riverpod 2.x |
| Database | Drift (SQLite) |
| Security | flutter_secure_storage + local_auth |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| Backup | Google Drive API |
| Export | csv + excel + share_plus |

---

## 🤝 Đóng Góp

Đây là dự án cộng đồng dành cho tài xế Việt Nam. Mọi đóng góp đều được chào đón!

1. Fork repo
2. Tạo branch: `git checkout -b feature/ten-tinh-nang`
3. Commit: `git commit -m "feat: mô tả thay đổi"`
4. Push và tạo Pull Request

### Bug Report / Góp Ý
Mở [GitHub Issue](https://github.com/YOUR_USERNAME/ThanhTaxiXanhSM/issues) với mô tả chi tiết.

---

## 📄 License

MIT License - xem file [LICENSE](LICENSE).

**Miễn phí vĩnh viễn cho cộng đồng tài xế Việt Nam** 🇻🇳

---

## ⚠️ Lưu Ý

- **Phí nền tảng Xanh SM**: Mặc định 18% (dựa trên chính sách 2026, tài xế nhận ~82%). User có thể điều chỉnh trong phần cài đặt ví.
- **Không phải app chính thức**: Đây là app bên thứ ba, không liên kết với Xanh SM/VinFast.
- **Privacy**: Không có server backend, mọi dữ liệu lưu trên thiết bị của bạn.

---

*Made with 💚 for Vietnamese Drivers*
