/// Base URL of the Python backend.
///
/// Override at run time without editing code:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

/// How often the chat screens refresh from the server.
const Duration pollInterval = Duration(seconds: 4);
