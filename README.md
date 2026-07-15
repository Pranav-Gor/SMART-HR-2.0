# 🏢 SMART HR 2.0

> An end-to-end HR Management solution built with Flutter — designed to eliminate the need for traditional biometric systems.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey)
![Version](https://img.shields.io/badge/Version-1.0.0-green)
![License](https://img.shields.io/badge/License-Private-red)

---

## 📖 About

**SMART HR 2.0** is a modern, cross-platform HR management application built with Flutter. It replaces conventional biometric attendance systems with a smarter, software-driven solution — making HR operations faster, more accessible, and hardware-independent.

Whether it's tracking employee attendance, managing payroll, generating reports, or handling leave requests, SMART HR 2.0 brings everything into one unified platform.

---

## ✨ Features

- 📍 **Location-based Attendance** — GPS-powered check-in/check-out replacing physical biometric devices
- 📊 **HR Analytics Dashboard** — Visual charts and insights for HR managers via `fl_chart`
- 📄 **PDF Report Generation** — Export employee records and reports as PDFs
- 📷 **QR Code Scanning** — Employee identification and check-in via QR codes (`mobile_scanner`, `qr_flutter`)
- 🖼️ **Profile Image Management** — Upload and manage employee photos (`image_picker`)
- 📁 **Excel Export** — Export data to `.xlsx` spreadsheets for payroll or records
- 🔔 **OTP Authentication** — Secure login with OTP verification
- 🎉 **Confetti & Animations** — Smooth Lottie animations and celebration effects for a polished UX
- 📂 **File Picker & Open** — Attach and open documents within the app
- 🌐 **Cross-Platform** — Runs on Android, iOS, Web, Windows, macOS, and Linux

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (SDK ≥ 3.3.1) |
| Language | Dart |
| State / Storage | `shared_preferences` |
| Networking | `http` |
| Charts | `fl_chart` |
| Location | `geolocator`, `geocoding`, `location` |
| PDF | `pdf`, `path_provider` |
| QR | `qr_flutter`, `mobile_scanner` |
| Excel | `excel` |
| Animations | `lottie`, `confetti` |
| Icons | `font_awesome_flutter`, `cupertino_icons` |
| Fonts | Nexa Bold, Nexa Regular |

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.3.1)
- Dart SDK (≥ 3.3.1, comes bundled with Flutter)
- Android Studio / Xcode (for mobile builds)
- A connected device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Pranav-Gor/SMART-HR-2.0.git
   cd SMART-HR-2.0
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build for specific platforms

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web

# Windows
flutter build windows
```

---

## 📁 Project Structure

```
SMART-HR-2.0/
├── lib/                  # Main Dart source code
├── assets/
│   ├── images/           # App images & icons
│   └── fonts/            # Custom fonts (NexaBold, NexaRegular)
├── android/              # Android-specific config
├── ios/                  # iOS-specific config
├── web/                  # Web-specific config
├── windows/              # Windows-specific config
├── linux/                # Linux-specific config
├── macos/                # macOS-specific config
├── test/                 # Unit & widget tests
├── pubspec.yaml          # Project dependencies
└── README.md
```

---

## 📦 Key Dependencies

```yaml
geolocator: ^13.0.4          # GPS-based attendance
fl_chart: ^0.70.2            # Analytics charts
qr_flutter: ^4.1.0           # QR code generation
mobile_scanner: ^5.1.1       # QR code scanning
pdf: ^3.10.8                 # PDF generation
excel: ^2.1.0                # Excel export
lottie: ^3.3.0               # Animations
image_picker: ^1.1.1         # Profile photo upload
flutter_otp_text_field: ^1.0.0  # OTP login
```

---

## 📋 Requirements

- Flutter `>=3.3.1 <4.0.0`
- Android: API level 21+
- iOS: 12.0+
- Location & Camera permissions must be granted at runtime

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 👤 Author

**Pranav Gor**
- GitHub: [@Pranav-Gor](https://github.com/Pranav-Gor)

---

## 📄 License



This project is private and not published to pub.dev. All rights reserved © Pranav Gor.

---

> *Smarter HR. No hardware. No hassle.*
<img width="1103" height="679" alt="image" src="https://github.com/user-attachments/assets/ed0af7d4-cd57-4c7c-a55b-11269d792701" />
<img width="1112" height="781" alt="image" src="https://github.com/user-attachments/assets/31dc8eb6-8000-49c7-88aa-bbdff848ecf1" />
<img width="1123" height="673" alt="image" src="https://github.com/user-attachments/assets/7f68e1f3-f326-42e8-8f54-28cbe42d792e" />
<img width="1123" height="677" alt="image" src="https://github.com/user-attachments/assets/a6ad26f2-6607-4120-a884-eee0e7f5f479" />
<img width="1142" height="677" alt="image" src="https://github.com/user-attachments/assets/f4e20c60-9467-4894-ac3c-130c7ef15bd5" />
<img width="490" height="980" alt="image" src="https://github.com/user-attachments/assets/ad9b3f4e-2bcd-4f3f-8688-e031ad5b0ead" />
<img width="487" height="979" alt="image" src="https://github.com/user-attachments/assets/c2586c15-b594-4a90-b882-55a8846d0c11" />
<img width="1105" height="979" alt="image" src="https://github.com/user-attachments/assets/fa39a249-b507-4c5c-862f-d1598ecbda92" />
<img width="1105" height="979" alt="image" src="https://github.com/user-attachments/assets/2561d45b-c309-4ea3-88c1-ce2376255cea" />
<img width="1118" height="979" alt="image" src="https://github.com/user-attachments/assets/4c8cf86f-da3c-4266-91bc-4cacd7eb8bb9" />
<img width="1123" height="979" alt="image" src="https://github.com/user-attachments/assets/6e8e314a-ab87-4f64-b691-51a78be21564" />


<img width="1123" height="979" alt="image" src="https://github.com/user-attachments/assets/8afbcc3b-c462-46f9-98fc-a8277313fe9c" />
<img width="1130" height="675" alt="image" src="https://github.com/user-attachments/assets/e19acbac-8f0a-434a-a479-75b41b0735ce" />






