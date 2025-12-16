/// Configuration file for API keys and settings
class Config {
  /// Google Cloud Speech-to-Text API Key
  ///
  /// To get your API key:
  /// 1. Go to https://console.cloud.google.com/
  /// 2. Create a new project or select existing project
  /// 3. Enable "Cloud Speech-to-Text API"
  /// 4. Go to "APIs & Services" > "Credentials"
  /// 5. Click "Create Credentials" > "API Key"
  /// 6. Copy the API key and paste it below
  ///
  /// IMPORTANT: For production, use proper authentication with service accounts
  /// and restrict your API key to specific APIs and apps.
  static const String googleCloudApiKey = 'YOUR_GOOGLE_CLOUD_API_KEY_HERE';

  /// Language code for speech recognition
  /// Examples: 'en-US', 'en-GB', 'es-ES', 'fr-FR', etc.
  static const String languageCode = 'en-US';

  /// Sample rate for audio recording (must match recorder settings)
  static const int sampleRateHertz = 16000;

  /// Audio encoding format
  static const String encoding = 'LINEAR16';
}
