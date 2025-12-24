// This is a basic Flutter widget test for VoiceVisionApp.
//
// It checks if the HomeScreen loads correctly and shows the welcome text.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voice_vision/main.dart';
import 'package:camera/camera.dart';

void main() {
  // Dummy camera for testing
  final camera = CameraDescription(
    name: 'Test Camera',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 0,
  );

  testWidgets('VoiceVisionApp loads HomeScreen', (WidgetTester tester) async {
    // Build the VoiceVisionApp with the test camera
    await tester.pumpWidget(VoiceVisionApp(camera: camera));

    // Wait for the widget to build
    await tester.pumpAndSettle();

    // Verify that the welcome text is displayed
    expect(
      find.textContaining('VOICE VISION'),
      findsOneWidget,
    );

    // Verify that the initial icon (visibility) is displayed
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
