# Google Cloud Speech-to-Text API Setup Guide

This guide will help you set up Google Cloud Speech-to-Text API for real-time transcription in the Cracked app.

## Prerequisites

- Google Account
- Credit/Debit card (for Google Cloud - though there's a free tier)

## Step-by-Step Setup

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click on the project dropdown at the top
3. Click **"New Project"**
4. Enter a project name (e.g., "cracked-transcription")
5. Click **"Create"**

### 2. Enable Speech-to-Text API

1. In the Google Cloud Console, make sure your new project is selected
2. Go to **"APIs & Services"** > **"Library"**
3. Search for **"Cloud Speech-to-Text API"**
4. Click on it and press **"Enable"**

### 3. Create an API Key

1. Go to **"APIs & Services"** > **"Credentials"**
2. Click **"Create Credentials"** at the top
3. Select **"API Key"**
4. Your API key will be generated and displayed
5. **Copy the API key** - you'll need it in the next step

### 4. (Recommended) Restrict Your API Key

To prevent unauthorized use:

1. In the API key dialog, click **"Edit API key"** (or click the pencil icon next to your key)
2. Under **"API restrictions"**, select **"Restrict key"**
3. Choose **"Cloud Speech-to-Text API"** from the dropdown
4. Under **"Application restrictions"**, you can:
   - Add your app's package name (for Android)
   - Add your bundle ID (for iOS)
   - Add authorized domains (for web)
5. Click **"Save"**

### 5. Add API Key to Your App

1. Open the file: **`lib/config.dart`**
2. Replace `'YOUR_GOOGLE_CLOUD_API_KEY_HERE'` with your actual API key:

```dart
static const String googleCloudApiKey = 'AIzaSyAbc123...'; // Your actual API key
```

3. Save the file

### 6. Enable Billing (Optional but Recommended)

Google Cloud provides a **free tier** with:
- **60 minutes of audio transcription per month** (for standard models)
- No credit card required for free tier

To use beyond the free tier:
1. Go to **"Billing"** in Google Cloud Console
2. Set up a billing account
3. Link it to your project

**Pricing:**
- First 60 minutes/month: **FREE**
- After that: ~$0.006 per 15 seconds (~$1.44 per hour)

## Testing

1. Run your Flutter app
2. Grant microphone permission when prompted
3. Tap the **"Start"** button to begin recording
4. Switch to the **"Transcription"** tab
5. You should see text appearing in real-time as you speak

## Troubleshooting

### "Google Cloud API key not configured"
- Make sure you've replaced `YOUR_GOOGLE_CLOUD_API_KEY_HERE` in `lib/config.dart`

### "API Error: API key not valid"
- Verify your API key is correct
- Make sure Speech-to-Text API is enabled
- Check if API restrictions allow your app

### "API Error: PROJECT_INVALID"
- Make sure billing is enabled for your project
- Verify the Speech-to-Text API is enabled

### No transcription appearing
- Check your internet connection (API requires network)
- Make sure you granted microphone permission
- Check the error message in the Transcription screen

### "Quota exceeded"
- You've used more than 60 minutes this month
- Enable billing or wait until next month

## Security Best Practices

⚠️ **IMPORTANT**: The current implementation uses API keys, which is simple but less secure.

For **production apps**, you should:

1. **Use Service Account Authentication** instead of API keys
2. **Never commit API keys** to version control
3. **Use environment variables** or secure key storage
4. **Implement server-side proxy** to hide credentials
5. **Set up API quotas** to prevent abuse

### Better Authentication (Advanced)

Instead of API keys, use Service Account with OAuth 2.0:

1. Create a service account in Google Cloud Console
2. Download the JSON key file
3. Use `googleapis_auth` package for authentication
4. Never include the JSON key in your app - use a backend server

## Additional Configuration

### Change Language

Edit `lib/config.dart`:

```dart
static const String languageCode = 'es-ES'; // For Spanish
// Other options: 'en-GB', 'fr-FR', 'de-DE', 'ja-JP', etc.
```

### Adjust Transcription Frequency

Edit `lib/transcription_provider.dart`, line 70:

```dart
_sendTimer = Timer.periodic(const Duration(milliseconds: 500), ...);
// Change 500 to adjust how often audio is sent (lower = more frequent, higher latency)
```

### Change Audio Quality

Edit `lib/config.dart`:

```dart
static const int sampleRateHertz = 16000; // Standard quality
// Options: 8000 (phone), 16000 (default), 44100 (high quality)
```

## Resources

- [Google Cloud Speech-to-Text Documentation](https://cloud.google.com/speech-to-text/docs)
- [API Reference](https://cloud.google.com/speech-to-text/docs/reference/rest)
- [Pricing Details](https://cloud.google.com/speech-to-text/pricing)
- [Supported Languages](https://cloud.google.com/speech-to-text/docs/languages)

## Support

If you encounter issues:
1. Check the error message in the Transcription tab
2. Verify your API key in `lib/config.dart`
3. Ensure Speech-to-Text API is enabled in Google Cloud Console
4. Check the Troubleshooting section above
