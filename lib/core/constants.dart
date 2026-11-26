/// App-wide constants shared by every layer.
abstract final class AppConstants {
  static const String appName = 'CaliPlan';

  /// Public wger API. Reading needs no API key.
  static const String wgerBaseUrl = 'https://wger.de/api/v2/';

  /// wger language id for English.
  static const int wgerEnglishLanguageId = 2;
}
