# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is DocNeX Care Desktop - a comprehensive healthcare management desktop application built with Flutter. The app serves multiple user roles in a healthcare ecosystem including doctors, nurses, receptionists, administrators, lab technicians, and pharmacy staff.

## Development Commands

### Setup & Dependencies

```bash
flutter pub get              # Install dependencies
flutter pub upgrade          # Upgrade dependencies
```

### Running the Application

```bash
flutter run -d windows      # Run on Windows
flutter run -d macos        # Run on macOS
flutter run -d linux        # Run on Linux
```

### Building for Production

```bash
flutter build windows       # Build Windows executable
flutter build macos         # Build macOS application
flutter build linux         # Build Linux application
```

### Testing & Quality Assurance

```bash
flutter test                 # Run unit tests
flutter analyze             # Run static analysis (uses flutter_lints)
```

## Architecture Overview

### State Management

- **Primary**: Flutter Riverpod for application state
- **Authentication**: Token-based JWT authentication with SharedPreferences storage
- **AuthController**: Centralized authentication state management

### Project Structure

```
lib/
├── Admin/           # Hospital administration features
├── Doctor/          # Doctor consultation, prescriptions, diagnoses
├── Nurse/           # Ward management, medication administration
├── reception/       # Patient registration (OPD/IPD), billing
├── Lab/             # Laboratory test management
├── pharmacy/        # Inventory, sales, prescription fulfillment
├── External/        # External doctor appointments
├── Insurance/       # Insurance claim processing
├── Patient/         # Patient data management
├── constants/       # App-wide constants, themes, URLs
├── model/           # Data models for API responses
├── repositories/    # Data access layer with repository pattern
├── services/        # Utility services (API, network, UI)
├── authProvider/    # Authentication state management
└── utils/           # Helper utilities and responsive design
```

### Repository Pattern Implementation

Core repositories handle data access:

- `auth_repository.dart` - User authentication
- `doctor_repository.dart` - Doctor operations
- `lab_repository.dart` - Laboratory data
- `appointment_repository.dart` - Appointment scheduling
- `investigation_repository.dart` - Medical investigations
- `history_repository.dart` - Patient history

### API Configuration

- **Development Base URL**: `http://localhost:5001` (configured in `lib/constants/Url.dart`)
- **Authentication**: JWT tokens with automatic refresh
- **HTTP Client**: Uses both `http` package and `dio` for different API calls

## Key Technologies & Dependencies

### Core Flutter Packages

- `flutter_riverpod ^2.6.1` - State management
- `flutter_screenutil ^5.9.3` - Responsive design (design size: 1920x1080)
- `shared_preferences ^2.3.3` - Local data persistence

### UI Components

- `google_fonts ^6.2.1` - Poppins font family
- `fl_chart ^0.70.2` - Data visualization charts
- `lottie ^3.3.1` - Animated graphics
- `glassmorphism ^3.0.0` - Modern UI effects

### Healthcare-Specific Features

- `syncfusion_flutter_pdfviewer ^29.1.38` - Medical report viewing
- `printing ^5.14.2` - PDF generation for prescriptions
- `record ^6.0.0` - Speech-to-text for medical notes
- `video_player ^2.9.5` - Patient consultation videos

### Desktop Support

- `window_size ^0.1.0` - Window management (minimum size: 1200x800)
- Supports Windows, macOS, and Linux platforms

## Development Guidelines

### Code Style

- Uses `flutter_lints ^3.0.0` for code quality
- Follow existing naming conventions (PascalCase for screens, camelCase for variables)
- Maintain consistent folder structure per user role

### Responsive Design

- Base design size: 1920x1080 pixels
- Use `flutter_screenutil` for responsive scaling
- Test on different desktop screen sizes

### Authentication Flow

1. Check for stored JWT token in SharedPreferences
2. Validate token with backend
3. Route to appropriate dashboard based on user role
4. Handle token refresh automatically

### API Integration

- All API endpoints are configured in `lib/constants/Url.dart`
- Use repository pattern for data access
- Handle network connectivity with `connectivity_plus`
- Implement proper error handling and user feedback

### Assets Management

- Images: `assets/images/` directory
- Fonts: Custom Poppins font variants in `assets/fonts/`
- Videos: Stored in `assets/videos/` for UI demonstrations

## Role-Based Architecture

Each user role has dedicated functionality:

- **Admin**: Bed management, billing oversight, patient management, master data configuration
- **Doctor**: Patient consultations, diagnosis, prescriptions, medical records, discharge summaries
- **Reception**: Patient registration, appointment scheduling, billing, discharge processing
- **Nurse**: Ward management, medication tracking, patient attendance, emergency medications
- **Lab**: Test assignment, sample processing, report generation
- **Pharmacy**: Inventory management, sales tracking, prescription fulfillment

## Installers & Distribution

Windows installers are pre-configured in the `installers/` directory using Inno Setup (.iss files). The application can be packaged as standalone executables for distribution.
