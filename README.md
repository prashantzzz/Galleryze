# workspace

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## About the app
photo gallery application called "Galleryze" with the following key components:

Core Application Files (lib/):
main.dart: Entry point of the application
app.dart: Main app configuration with theme and providers setup
Contains organized subdirectories:
models/: Data structures
providers/: State management (using Provider package)
screens/: UI screens/pages
services/: Backend services
utils/: Helper functions
widgets/: Reusable UI components
Platform-Specific Directories:
android/: Android platform code
ios/: iOS platform code
web/: Web platform files (index.html, manifest.json)
windows/, linux/, macos/: Desktop platform specific code
Configuration Files:
pubspec.yaml: Flutter dependencies and project configuration
Key packages:
provider: State management
cached_network_image: Image caching
flutter_staggered_grid_view: Grid layout
http: Network requests
Backend Integration:
package.json: Node.js dependencies including Supabase
.env: Environment variables (for API keys etc.)
supabase_client.js: Supabase database integration
Development Tools:
test/: Contains widget tests
analysis_options.yaml: Dart code analysis rules
.dart_tool/: Dart development tools
Assets:
attached_assets/: Contains UI design files and wireframes
web/icons/: App icons for web
Features (based on the codebase structure):

Photo Gallery Management
Custom Categories for Photos
Grid View Layout
Image Caching
Cross-platform Support (Web, Mobile, Desktop)
Backend Database Integration (Supabase)
Material Design Theme
State Management using Provider
The project is set up to run on port 5000 for web development 