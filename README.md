# smartspend

SmartSpend is a Flutter application. The project has been configured to
initialize Firebase on application start.

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

Additional Flutter learning resources are available in the
[Flutter online documentation](https://docs.flutter.dev/).
