import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  CameraDescription? firstCamera;

  if (!kIsWeb) {
    final cameras = await availableCameras();
    firstCamera = cameras.isNotEmpty ? cameras.first : null;
  }

  runApp(VoiceVisionApp(camera: firstCamera));
}

class VoiceVisionApp extends StatelessWidget {
  final CameraDescription? camera;
  const VoiceVisionApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomeScreen(camera: camera),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final CameraDescription? camera;
  const HomeScreen({super.key, required this.camera});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  FlutterTts? flutterTts;
  bool isCameraInitialized = false;

  String lastSpokenText =
      "Welcome to Voice Vision. Double tap anywhere to start the camera.";

  late final String apiKey;

  @override
  void initState() {
    super.initState();

    // Initialize API key from environment variable
    apiKey = dotenv.env['GOOGLE_GENERATIVE_AI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('Warning: API key not configured. Check .env file.');
    }

    if (!kIsWeb) {
      flutterTts = FlutterTts();
      _setupTts();
      _speak(lastSpokenText);
    }
  }

  void _setupTts() async {
    if (flutterTts != null) {
      try {
        await flutterTts!.setLanguage("en-US");
        await flutterTts!.setSpeechRate(0.5);
      } catch (e, stackTrace) {
        debugPrint('TTS setup error: $e\n$stackTrace');
      }
    }
  }

  Future<bool> _requestCameraPermissions() async {
    if (kIsWeb) return true; // Permissions not needed on web

    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isDenied || micStatus.isDenied) {
      _speak("Camera and microphone permissions are required.");
      return false;
    }

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      _speak(
        "Permissions are permanently denied. Please enable them in settings.",
      );
      openAppSettings();
      return false;
    }

    return true;
  }

  Future<void> _speak(String text) async {
    if (flutterTts != null) {
      await flutterTts!.stop();
      lastSpokenText = text;
      await flutterTts!.speak(text);
    }
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) return; // No camera on web

    if (widget.camera == null) {
      _speak("Camera not available on this device.");
      return;
    }

    // Request permissions before initializing camera
    final hasPermissions = await _requestCameraPermissions();
    if (!hasPermissions) {
      return;
    }

    _controller = CameraController(
      widget.camera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          isCameraInitialized = true;
        });
        _speak(
          "Camera is now active. Tap once to describe what is in front of you.",
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Camera initialization failed: $e\n$stackTrace');
      _speak("Error opening camera.");
    }
  }

  Future<void> _describeScene() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Camera is not supported on Web. Please try on Mobile.",
          ),
        ),
      );
      return;
    }

    if (!isCameraInitialized) {
      _speak("Please double tap to start the camera first.");
      return;
    }

    try {
      await _speak("Looking...");
      if (_controller == null) {
        _speak("Camera is not initialized.");
        return;
      }
      final image = await _controller!.takePicture();
      final bytes = await image.readAsBytes();

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

      final content = [
        Content.multi([
          TextPart(
            "Describe this image for a blind person in one short sentence.",
          ),
          DataPart('image/jpeg', Uint8List.fromList(bytes)),
        ]),
      ];

      final response = await model.generateContent(content);
      await _speak(response.text ?? "I could not understand the image.");
    } catch (e, stackTrace) {
      debugPrint('Image description failed: $e\n$stackTrace');
      _speak("Please check your internet connection.");
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && isCameraInitialized) {
      _controller?.dispose();
      flutterTts?.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onDoubleTap: () {
          if (!isCameraInitialized && !kIsWeb) {
            _initializeCamera();
          }
        },
        onTap: () {
          if (isCameraInitialized && !kIsWeb) {
            _describeScene();
          }
        },
        child: Stack(
          children: [
            if (isCameraInitialized && !kIsWeb)
              Center(child: CameraPreview(_controller!)),
            Container(
              color: isCameraInitialized
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      (isCameraInitialized && !kIsWeb)
                          ? Icons.camera_alt
                          : Icons.visibility,
                      size: 150,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 40),
                    Text(
                      kIsWeb
                          ? "VOICE VISION\n\nCamera is not supported on Web."
                          : isCameraInitialized
                          ? "TAP ONCE TO SCAN"
                          : "VOICE VISION\n\nDOUBLE TAP TO START",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
