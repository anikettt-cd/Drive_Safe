import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Auth
import 'package:firebase_core/firebase_core.dart'; // Core
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

// ----------------------------------------------------------------------
// 1. APP CONFIGURATION & CONSTANTS
// ----------------------------------------------------------------------
class AppConstants {
  static const double EAR_THRESHOLD = 0.25; 
  static const double PROB_THRESHOLD = 0.5; 
  static const int MICROSLEEP_MS = 500;        
  static const int DROWSINESS_MS = 1000;       
  static const int EMERGENCY_ALERT_MS = 5000;  
  static const String ALERT_SOUND = "alarm.mp3";
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // <--- Initialize Firebase
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DriverSafetyApp());
}

class DriverSafetyApp extends StatelessWidget {
  const DriverSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Drive Safe',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0D47A1), 
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        fontFamily: 'Roboto', 
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0D47A1),
          elevation: 1,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Color(0xFF0D47A1), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      // Check if user is logged in
      home: const AuthGate(),
    );
  }
}

// ----------------------------------------------------------------------
// 2. AUTH GATE (The Gatekeeper)
// ----------------------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If logged in, go to Driver Setup
        if (snapshot.hasData) {
          return const DriverSetupPage();
        }
        // If not logged in, go to Login Page
        return const LoginPage();
      },
    );
  }
}

// ----------------------------------------------------------------------
// 3. LOGIN PAGE
// ----------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // AuthGate handles navigation automatically
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Login Failed"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: Color(0xFF0D47A1)),
                const SizedBox(height: 20),
                const Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                const Text("Login to access SafeDrive", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),
                
                _buildAuthInput(_emailController, "Email", Icons.email),
                const SizedBox(height: 15),
                _buildAuthInput(_passwordController, "Password", Icons.lock, isPassword: true),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage())),
                  child: const Text("New User? Create Account", style: TextStyle(color: Color(0xFF0D47A1))),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthInput(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }
}

// ----------------------------------------------------------------------
// 4. SIGN UP PAGE
// ----------------------------------------------------------------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Pop back to login/auth gate
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Sign Up Failed"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account"), elevation: 0, backgroundColor: const Color(0xFFF5F7FB)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Join Drive Safe", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email, color: Color(0xFF0D47A1)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.contains('@') ? null : "Enter valid email",
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password (Min 6 chars)",
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF0D47A1)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value!.length < 6 ? "Password too short" : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 5. DRIVER SETUP (Updated with Logout)
// ----------------------------------------------------------------------
class DriverSetupPage extends StatefulWidget {
  const DriverSetupPage({super.key});
  @override
  State<DriverSetupPage> createState() => _DriverSetupPageState();
}

class _DriverSetupPageState extends State<DriverSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _carController = TextEditingController();
  final _bloodController = TextEditingController();
  final _emergencyController = TextEditingController(); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("CONFIGURATION"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(), // <--- LOGOUT BUTTON
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.security, size: 64, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(height: 24),
                const Text("Safety First", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                const SizedBox(height: 40),

                _buildProfessionalInput(_nameController, "Driver Name", Icons.person),
                const SizedBox(height: 16),
                _buildProfessionalInput(_carController, "Vehicle Number", Icons.directions_car),
                const SizedBox(height: 16),
                _buildProfessionalInput(_bloodController, "Blood Group", Icons.bloodtype),
                const SizedBox(height: 16),
                _buildProfessionalInput(_emergencyController, "Telegram Chat ID", Icons.send, isNumber: true, hint: "e.g., 123456789"),
                
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Color(0xFF1565C0)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Color(0xFF1565C0), fontSize: 12),
                            children: [
                              TextSpan(text: "How to find ID: ", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: "Search "),
                              TextSpan(text: "@userinfobot ", style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: "on Telegram, click Start, and copy the 'Id' number."),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _startMonitoring,
                    child: const Text("START MONITORING", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startMonitoring() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => DrowsinessDetectionPage(
            driverName: _nameController.text,
            carNumber: _carController.text,
            bloodType: _bloodController.text,
            emergencyContact: _emergencyController.text,
      )));
    }
  }

  Widget _buildProfessionalInput(TextEditingController controller, String label, IconData icon, {bool isNumber = false, String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        filled: true,
        fillColor: const Color(0xFFF5F7FB),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }
}

// ----------------------------------------------------------------------
// 6. MAIN DETECTION DASHBOARD (Kept Exact Same Logic)
// ----------------------------------------------------------------------
class DrowsinessDetectionPage extends StatefulWidget {
  final String driverName;
  final String carNumber;
  final String bloodType;
  final String emergencyContact;

  const DrowsinessDetectionPage({super.key, required this.driverName, required this.carNumber, required this.bloodType, required this.emergencyContact});

  @override
  State<DrowsinessDetectionPage> createState() => _DrowsinessDetectionPageState();
}

class _DrowsinessDetectionPageState extends State<DrowsinessDetectionPage> {
  CameraController? _cameraController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String telegramBotToken = "7609570341:AAFI0FnPF8kxU9iU5Q7pF_3ok298vQiHESI"; 
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions(enableClassification: true, enableContours: true, enableTracking: true));

  bool _isBusy = false;
  bool _isDrowsy = false; 
  bool _telegramAlertSent = false; 
  String _statusMessage = "Initializing System...";
  Color _statusColor = const Color(0xFF4CAF50); 
  IconData _statusIcon = Icons.check_circle;
  DateTime? _closureStartTime; 

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    await [Permission.camera, Permission.location].request();
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);

    _cameraController = CameraController(frontCamera, ResolutionPreset.low, enableAudio: false);
    await _cameraController!.initialize();
    if (!mounted) return;

    _cameraController!.startImageStream(_processCameraImage);
    setState(() { _statusMessage = "Active Monitoring"; _statusColor = const Color(0xFF4CAF50); });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          _checkForDrowsiness(faces.first);
        } else {
           if(!_isDrowsy) setState(() { _statusMessage = "FACE NOT DETECTED"; _statusColor = Colors.orange; _statusIcon = Icons.warning_amber_rounded; });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      _isBusy = false;
    }
  }

  void _checkForDrowsiness(Face face) {
    final leftEAR = _calculateEAR(face.contours[FaceContourType.leftEye]);
    final rightEAR = _calculateEAR(face.contours[FaceContourType.rightEye]);
    final double leftProb = face.leftEyeOpenProbability ?? 1.0;
    final double rightProb = face.rightEyeOpenProbability ?? 1.0;

    final bool isClosed = (leftEAR != null && leftEAR < AppConstants.EAR_THRESHOLD) || 
                          (rightEAR != null && rightEAR < AppConstants.EAR_THRESHOLD) ||
                          (leftProb < AppConstants.PROB_THRESHOLD && rightProb < AppConstants.PROB_THRESHOLD);

    if (isClosed) {
      _closureStartTime ??= DateTime.now();
      final duration = DateTime.now().difference(_closureStartTime!).inMilliseconds;
      if (duration > AppConstants.MICROSLEEP_MS && duration < AppConstants.DROWSINESS_MS) {
         setState(() { _statusMessage = "⚠️ WAKE UP!"; _statusColor = Colors.amber.shade700; _statusIcon = Icons.access_time_filled; });
      }
      if (duration > AppConstants.DROWSINESS_MS) {
        if (!_isDrowsy) {
          setState(() { _isDrowsy = true; _statusMessage = "🚨 DROWSINESS DETECTED!"; _statusColor = Colors.red.shade700; _statusIcon = Icons.campaign; });
          _audioPlayer.play(AssetSource(AppConstants.ALERT_SOUND));
          _audioPlayer.setReleaseMode(ReleaseMode.loop); 
        }
      }
      if (duration > AppConstants.EMERGENCY_ALERT_MS) {
        if (!_telegramAlertSent) {
          _sendTelegramAlertWithLocation(); 
          setState(() { _telegramAlertSent = true; _statusMessage = "📤 CONTACTING EMERGENCY..."; });
        }
      }
    } else {
      if (_isDrowsy) { setState(() => _isDrowsy = false); _audioPlayer.stop(); }
      _closureStartTime = null;
      _telegramAlertSent = false; 
      setState(() { _statusMessage = "Active Monitoring"; _statusColor = const Color(0xFF4CAF50); _statusIcon = Icons.remove_red_eye; });
    }
  }

  Future<void> _sendTelegramAlertWithLocation() async {
    String locationText = "Locating...";
    String mapsLink = "";
    String hospitalList = "Searching...";
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      locationText = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
      mapsLink = "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
      hospitalList = await _getNearbyHospitals(position.latitude, position.longitude);
    } catch (e) {
      locationText = "GPS Signal Lost";
      hospitalList = "Network Unavailable";
    }
    final String message = "🚨 *EMERGENCY: DROWSINESS ALERT* 🚨\n\n👤 *Driver:* ${widget.driverName}\n🚗 *Vehicle:* ${widget.carNumber}\n🩸 *Blood:* ${widget.bloodType}\n\n📍 *Live Location:*\n$locationText\n\n🏥 *Nearby Hospitals:*\n$hospitalList\n\n🔗 *Click to View Map:*\n$mapsLink";
    final String url = "https://api.telegram.org/bot$telegramBotToken/sendMessage";
    try {
      await http.post(Uri.parse(url), body: {'chat_id': widget.emergencyContact, 'text': message, 'parse_mode': 'Markdown'});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emergency Alert Sent!"), backgroundColor: Colors.green));
    } catch (e) { print("Telegram Error: $e"); }
  }

  Future<String> _getNearbyHospitals(double lat, double lon) async {
    final String query = '[out:json];node(around:3000,$lat,$lon)[amenity=hospital];out;';
    final String url = "https://overpass-api.de/api/interpreter?data=$query";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;
        if (elements.isEmpty) return "No hospitals found within 3km.";
        List<String> hospitals = [];
        for (var i = 0; i < math.min(elements.length, 3); i++) {
          var tags = elements[i]['tags'];
          if (tags != null && tags['name'] != null) hospitals.add("• ${tags['name']}");
        }
        return hospitals.isEmpty ? "Medical Centers nearby" : hospitals.join("\n");
      }
    } catch (e) { return "Error fetching data"; }
    return "Unknown";
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) { rotationCompensation = (sensorOrientation + rotationCompensation) % 360; } 
      else { rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360; }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    } else { rotation = InputImageRotationValue.fromRawValue(sensorOrientation); }
    if (rotation == null) return null;
    final yPlane = image.planes[0]; final uPlane = image.planes[1]; final vPlane = image.planes[2];
    final int width = image.width; final int height = image.height;
    final int imgSize = (width * height * 1.5).toInt();
    final Uint8List nv21Bytes = Uint8List(imgSize);
    int id = 0; int yIndex = 0;
    for (int y = 0; y < height; y++) { for (int x = 0; x < width; x++) { nv21Bytes[id++] = yPlane.bytes[yIndex + x]; } yIndex += yPlane.bytesPerRow; }
    final int uvRowStride = uPlane.bytesPerRow; final int uvPixelStride = uPlane.bytesPerPixel!;
    for (int y = 0; y < height / 2; y++) { for (int x = 0; x < width / 2; x++) { final int index = (y * uvRowStride) + (x * uvPixelStride); nv21Bytes[id++] = vPlane.bytes[index]; nv21Bytes[id++] = uPlane.bytes[index]; } }
    final metadata = InputImageMetadata(size: Size(width.toDouble(), height.toDouble()), rotation: rotation, format: InputImageFormat.nv21, bytesPerRow: width);
    return InputImage.fromBytes(bytes: nv21Bytes, metadata: metadata);
  }

  static final _orientations = { DeviceOrientation.portraitUp: 0, DeviceOrientation.landscapeLeft: 90, DeviceOrientation.portraitDown: 180, DeviceOrientation.landscapeRight: 270 };
  double? _calculateEAR(FaceContour? eyeContour) {
    if (eyeContour == null) return null;
    final points = eyeContour.points;
    if (points.isEmpty) return null;
    math.Point<int> left = points.first, right = points.first, top = points.first, bottom = points.first;
    for (var point in points) { if (point.x < left.x) left = point; if (point.x > right.x) right = point; if (point.y < top.y) top = point; if (point.y > bottom.y) bottom = point; }
    final double width = _euclideanDistance(left, right); final double height = _euclideanDistance(top, bottom);
    return width == 0 ? 0.0 : height / width;
  }
  double _euclideanDistance(math.Point<int> p1, math.Point<int> p2) { return math.sqrt(math.pow(p2.x - p1.x, 2) + math.pow(p2.y - p1.y, 2)); }
  @override
  void dispose() { _cameraController?.dispose(); _faceDetector.close(); _audioPlayer.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("SAFETY MONITOR")),
      body: Column(
        children: [
          Expanded(flex: 6, child: Container(margin: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)]), child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(fit: StackFit.expand, children: [_cameraController != null && _cameraController!.value.isInitialized ? CameraPreview(_cameraController!) : const Center(child: CircularProgressIndicator()), Positioned(top: 20, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(_statusIcon, color: Colors.white), const SizedBox(width: 8), Text(_statusMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]))))])))),
          Expanded(flex: 3, child: Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFFF5F7FB), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))), child: Column(children: [Row(children: [_buildInfoCard(Icons.person, "Driver", widget.driverName), const SizedBox(width: 12), _buildInfoCard(Icons.directions_car, "Vehicle", widget.carNumber)]), const SizedBox(height: 12), Row(children: [_buildInfoCard(Icons.bloodtype, "Blood Grp", widget.bloodType), const SizedBox(width: 12), _buildInfoCard(Icons.local_hospital, "Status", _isDrowsy ? "DANGER" : "SAFE", isAlert: _isDrowsy)])])))
        ],
      ),
    );
  }
  Widget _buildInfoCard(IconData icon, String label, String value, {bool isAlert = false}) {
    return Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isAlert ? Colors.red.shade50 : Colors.white, borderRadius: BorderRadius.circular(16), border: isAlert ? Border.all(color: Colors.red) : null, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 18, color: isAlert ? Colors.red : Colors.grey), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500))]), const SizedBox(height: 8), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isAlert ? Colors.red : const Color(0xFF0D47A1)), overflow: TextOverflow.ellipsis)])));
  }
}