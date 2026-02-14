# Add these to your pubspec.yaml

dependencies:
  flutter:
    sdk: flutter
  flutter_inappwebview: ^6.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.2
  uuid: ^4.3.3
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  hive_generator: ^2.0.1
  build_runner: ^2.4.8

# Notes:
# 1) After adding deps, run: flutter pub get
# 2) No code generation is required (this project uses manual JSON storage in Hive).
