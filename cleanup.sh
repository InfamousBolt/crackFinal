#!/bin/bash

echo "🧹 Starting cleanup..."

# Delete native iOS code
echo "Removing native iOS code..."
rm -f ios/Runner/AudioAnalysisPlugin.swift

# Delete voice/speech services
echo "Removing voice/speech services..."
rm -f lib/services/audio_analysis_channel.dart
rm -f lib/services/voice_classifier.dart
rm -f lib/services/voice_profile_service.dart
rm -f lib/services/cloud_speech_service.dart
rm -f lib/services/streaming_interview_service.dart
rm -f lib/services/vlm_service.dart

# Delete models and screens
echo "Removing voice models and screens..."
rm -f lib/models/voice_profile.dart
rm -f lib/screens/voice_enrollment_screen.dart
rm -f lib/start_screen_with_vlm.dart

# Delete question-related
echo "Removing question-related files..."
rm -f lib/question_provider.dart
rm -f lib/questions_screen.dart

# Replace main files (if clean versions exist)
if [ -f "lib/main_clean.dart" ]; then
    echo "Replacing main.dart..."
    cp lib/main_clean.dart lib/main.dart
fi

if [ -f "lib/start_screen_clean.dart" ]; then
    echo "Replacing start_screen.dart..."
    cp lib/start_screen_clean.dart lib/start_screen.dart
fi

if [ -f "ios/Runner/AppDelegate_clean.swift" ]; then
    echo "Replacing AppDelegate.swift..."
    cp ios/Runner/AppDelegate_clean.swift ios/Runner/AppDelegate.swift
fi

if [ -f "pubspec_clean.yaml" ]; then
    echo "Replacing pubspec.yaml..."
    cp pubspec_clean.yaml pubspec.yaml
fi

# Clean build
echo "Cleaning build..."
flutter clean

echo "Getting dependencies..."
flutter pub get

# Clean iOS build
if [ -d "ios" ]; then
    echo "Cleaning iOS build..."
    cd ios
    rm -rf Pods Podfile.lock build
    pod install
    cd ..
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "1. Run: flutter run"
echo "2. Test the app"
echo "3. Enjoy your clean, simple recorder!"