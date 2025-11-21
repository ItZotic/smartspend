# SmartSpend

SmartSpend is a personal finance tracker built with Flutter for students, professionals, and anyone who wants a quick overview of day-to-day spending. Log income and expenses with detailed categories, notes, and timestamps, then watch your totals update across a clean, modern interface.

## Features
- Track both income and expenses with categories, accounts, icons, notes, and manual date selection.
- See daily or monthly totals for income, expenses, and remaining balance directly on the Home screen.
- Browse a modern bottom navigation experience spanning Home, Budget, Analytics, Accounts, and Settings views.
- Add, edit, and delete transactions through streamlined forms with numeric keypad entry.
- Access helpful summaries like "Today’s Records" and compact header stats without altering card layouts.

## Tech Stack
- **Framework:** Flutter + Dart
- **Backend:** Firebase Authentication & Cloud Firestore for secure storage and sync
- **State/Data:** StreamBuilder-driven Firestore queries, local filtering for view modes
- **Tooling:** intl for date formatting, Material widgets for UI polish

## Development Timeline
### Phase 1 – Project Foundation
- Bootstrapped the Flutter project structure and added shared resources for Android, iOS, web, and desktop.
- Wired the app to initialize Firebase on launch and documented the configuration steps.

### Phase 2 – Navigation & Core Screens
- Implemented the main menu with a bottom navigation bar linking Home, Budget, Analytics, Accounts, and Settings.
- Added scaffolded layouts for each tab so the UI remains consistent throughout the experience.

### Phase 3 – Transaction Management
- Created the Add Transaction screen with category/account dropdowns, notes, and a custom keypad for entering amounts.
- Hooked the form into Cloud Firestore to persist transactions tied to the authenticated user, including edit/delete actions.

### Phase 4 – Home Screen Summaries
- Built the initial Home dashboard with a large remaining balance header, income/expense summaries, and a styled transaction list.
- Added the "Today’s Records" card to surface same-day spending activity.

### Phase 5 – UI Refresh & Sliding FAB Behavior
- Replaced the large Home header with a compact navy block featuring Expense/Income/Total columns and a hamburger menu.
- Centralized floating action button visibility logic so scrolling any main screen animates the shared "+" button consistently.

### Phase 6 – Display Options & Filtering
- Introduced the "Display Option" bottom sheet accessible from the Home header menu.
- Added Daily vs Monthly view modes plus synchronized month/year/day selectors that control which transactions and totals are shown.
- Removed legacy `<` and `>` chevrons from the header so all period changes now happen inside the menu.

### Phase 7 – Manual Date Selection When Adding Transactions
- Added a calendar picker to the Add Transaction form with intl-based formatting.
- Stored the exact user-selected date in Firestore so entries can be backdated or scheduled ahead of time.

### Phase 8 – Data Accuracy Improvements
- Updated the "Today’s Records" module to always reference the true current date regardless of the selected period.
- Clarified empty-state messaging so users know when no entries exist for the chosen view.

## Planned Features / Next Steps
- Category-level budgeting with progress indicators on the Budget screen.
- Export transactions to CSV or spreadsheet formats for long-term backups.
- Additional analytics views (weekly trends, category pie charts, variance tracking).
- Optional light/dark theme toggle with persisted preference.

## Firebase configuration

1. Create a Firebase project in the [Firebase console](https://console.firebase.google.com/) and add the desired platforms (Android, iOS, Web, macOS, Windows, and/or Linux).
2. Download the generated platform configuration files and place them in the project:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `macos/Runner/GoogleService-Info.plist`
   - `windows/runner/resources/firebase_app_id_file.json`
   - `linux/firebase_config.json`
3. Replace the placeholder values in `lib/firebase_options.dart` with the values from the configuration files, or run `flutterfire configure` to regenerate the file automatically.
4. From the project root run `flutter pub get` to install dependencies.

> **Note**
> The application will throw an error at startup until valid Firebase configuration values are supplied.

## Running the application

Use your preferred Flutter tooling (`flutter run`, Android Studio, VS Code, etc.) to launch the application once Firebase has been configured.

Additional Flutter learning resources are available in the [Flutter online documentation](https://docs.flutter.dev/).
