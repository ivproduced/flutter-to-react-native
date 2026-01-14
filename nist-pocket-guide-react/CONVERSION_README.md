# NIST Pocket Guide - React Conversion

This is a React/TypeScript conversion of the NIST Pocket Guide Flutter application.

## Overview

The NIST Pocket Guide is a comprehensive mobile reference application for NIST security controls and frameworks including:
- NIST SP 800-53 Rev 5 Security Controls
- NIST Cybersecurity Framework (CSF) 2.0
- NIST SP 800-171 Rev 3
- NIST AI Risk Management Framework (AI RMF)
- Secure Software Development Framework (SSDF)
- System Security Plan (SSP) Generator

## Architecture

### Technology Stack
- **React 18** with TypeScript
- **React Router v6** for navigation
- **Dexie.js** (IndexedDB) for local database storage
- **localforage** for key-value storage
- **Material Icons** for UI icons

### Project Structure

```
src/
├── contexts/           # React Context providers (state management)
│   ├── AppDataContext.tsx          # App-wide settings and theme
│   ├── ProjectDataContext.tsx      # Information systems and projects
│   ├── ModulePreferencesContext.tsx # Module visibility preferences
│   └── PurchaseContext.tsx         # Pro features and purchases
├── components/        # Reusable UI components
├── screens/          # Screen/page components
│   └── HomePage.tsx  # Main dashboard with module cards
├── models/           # TypeScript interfaces and data models
│   ├── AppModule.ts
│   └── InformationSystem.ts
├── services/         # Business logic and data services
│   └── DatabaseService.ts  # IndexedDB wrapper using Dexie
├── utils/            # Utility functions
├── config/           # Configuration files
└── hooks/            # Custom React hooks
```

### State Management

The app uses React Context API for state management, replacing Flutter's Provider pattern:

1. **AppDataContext** - Theme settings and app-wide configuration
2. **ProjectDataContext** - Information systems CRUD operations
3. **ModulePreferencesContext** - Module visibility toggles
4. **PurchaseContext** - Pro feature management

### Data Persistence

- **IndexedDB** (via Dexie.js) - Replaces Flutter's sqflite for structured data
- **localforage** - Replaces SharedPreferences for key-value storage

### Conversion Status

#### ✅ Completed
- [x] Project structure setup
- [x] Core models and TypeScript interfaces
- [x] Context providers for state management
- [x] IndexedDB database service
- [x] Main App component with routing
- [x] HomePage/Dashboard screen
- [x] Onboarding flow
- [x] Theme system (light/dark mode)

#### 🚧 In Progress
- [ ] Individual module screens (800-53, CSF, etc.)
- [ ] Settings screen
- [ ] About screen

#### 📋 TODO
- [ ] Control Dashboard (800-53 module)
- [ ] CSF Functions screen
- [ ] SP 800-171 screens
- [ ] AI RMF Playbook screens
- [ ] SSDF screens
- [ ] SSP Generator
- [ ] Search functionality
- [ ] Export/Import features
- [ ] Payment integration (replacing in-app purchases)
- [ ] Comprehensive test suite

## Development

### Prerequisites
- Node.js 16+ and npm

### Installation

```bash
npm install
```

### Running the App

```bash
npm start
```

The app will open at [http://localhost:3000](http://localhost:3000).

### Building for Production

```bash
npm run build
```

### Testing

```bash
npm test
```

## Key Differences from Flutter Version

1. **Navigation**: Flutter Navigator → React Router v6
2. **State Management**: Flutter Provider → React Context API
3. **Database**: sqflite → Dexie.js (IndexedDB)
4. **Storage**: SharedPreferences → localforage
5. **Styling**: Flutter Material widgets → CSS with CSS variables
6. **In-App Purchases**: Flutter in_app_purchase → Web payment APIs (TBD)
7. **Platform Support**: Cross-platform mobile → Web-first (PWA capable)

## Deployment

This React app can be deployed to:
- **Netlify** (recommended)
- **Vercel**
- **GitHub Pages**
- **Firebase Hosting**
- Any static hosting service

The app is designed as a Progressive Web App (PWA) and can be installed on mobile devices through the browser.

## Migration Notes

### From Flutter Provider to React Context

Flutter:
```dart
final appDataManager = Provider.of<AppDataManager>(context);
```

React:
```typescript
const { currentThemeMode, setThemeMode } = useAppData();
```

### Database Operations

Flutter (sqflite):
```dart
await _dbService.createInformationSystem(system);
```

React (Dexie):
```typescript
await db.createInformationSystem(system);
```

## License

[Include original license information]

## Credits

Original Flutter application by [Original Author]
React conversion by [Your Name]
