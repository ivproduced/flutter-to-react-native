# NIST Pocket Guide

A cross-platform Flutter app for navigating, understanding, and implementing NIST SP 800-53 controls, the NIST AI Risk Management Framework (AI RMF), and related standards. Designed for compliance professionals, system owners, and security practitioners.

---

## Features

- **NIST 800-53 Controls**
  - Browse all controls and enhancements by family
  - View control details, guidance, and notes
  - Mark favorites and add personal notes
  - Quick access to recent controls

- **AI RMF Playbook**
  - Explore AI RMF entries by type or topic
  - Detailed views with sections, references, and actors

- **NISTBot Chat (Beta)**
  - AI-powered chatbot for guidance on NIST controls and frameworks
  - Daily usage tracking and limits

- **System & SSP Management (Alpha)**
  - Create and manage information systems
  - Generate and edit System Security Plan (SSP) statements
  - Track control implementations and evidence

- **Personalization**
  - Light, dark, and system theme modes
  - User preferences and settings

- **Cross-Platform**
  - Runs on Android, iOS, Web, Windows, macOS, and Linux

---

## Architecture

- **Flutter & Dart**: Modern, reactive UI with Material Design
- **State Management**: Provider pattern with ChangeNotifier
- **Data Storage**: sqflite (with FFI for desktop), SharedPreferences
- **AI Integration**: HTTP-based backend for NISTBot chat
- **Modular Structure**: Organized by features and screens

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Dart 3.x

### Install Dependencies
```
flutter pub get
```

### Run the App
```
flutter run
```

### Build for Web
```
flutter build web
```

---

## Project Structure

- `lib/` - Main app code
  - `main.dart` - App entry point
  - `about_screen.dart`, `settings_screen.dart` - Info and settings
  - `app_data_manager.dart` - App-wide data and preferences
  - `models/` - Data models (controls, systems, AI RMF, etc.)
  - `services/` - Database, purchase, and utility services
  - `ai_chat/` - NISTBot chat UI and logic
  - `ai_rmf_screens/` - AI RMF playbook screens
  - `ssp_generator_screens/` - SSP management screens
  - `800-53_screens/` - Control browsing and detail screens
  - `widgets/` - Reusable UI components
- `assets/` - JSON data, icons, and resources
- `web/` - Web build output and static files

---

## Contributing

Contributions are welcome! Please open issues or submit pull requests for bug fixes, new features, or improvements.

---

## License

This project is licensed under the MIT License.

---

## Acknowledgments

- NIST for the SP 800-53 and AI RMF frameworks
- Flutter and Dart teams

---

## Contact

For questions or support, please contact the project maintainer.
