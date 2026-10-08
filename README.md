🚗 Drive Safe

An AI-Powered Driver Monitoring & Telemetry App built with Flutter

Detecting fatigue before it becomes a danger. Protecting journeys in real-time.

💡 About The Project

Driver fatigue and distraction are among the leading causes of road accidents worldwide. Drive Safe tackles this problem head-on by transforming a standard smartphone into an intelligent dashcam and driver-monitoring system.

By analyzing live camera feeds through on-device Machine Learning (ML) and cross-referencing it with real-time GPS telemetry, the app actively monitors the driver's state and intervenes when it detects drowsiness or unsafe driving patterns.

🔥 Core Features (Under the Hood)

🧠 AI-Powered Alertness Tracking

Facial Landmark Detection: Utilizes Google ML Kit to map the driver's face in real-time, functioning entirely on-device for zero latency.

Micro-Sleep Detection: Continuously calculates the "Eye Open Probability." If the driver's eyes remain closed beyond a safe threshold (e.g., 1.5 seconds), the system flags a critical micro-sleep event.

Distraction Monitoring: Tracks head pose angles (Euler Y and Z) to ensure the driver's attention remains on the road.

📍 Telemetry & Speed Analysis

Hyper-Accurate GPS: Integrates the Geolocator plugin to pull high-frequency location data.

Velocity Tracking: Monitors vehicle speed to adjust the severity and timing of alerts (e.g., faster speeds trigger faster interventions).

🚨 Active Intervention System

Escalating Alarms: Triggers high-visibility screen flashes and loud audio cues to snap the driver back to attention.

Emergency Protocols: In the event of prolonged unresponsiveness, the app can utilize saved user data to initiate emergency workflows.

☁️ Cloud-Synced Dashboard

Firebase Authentication: Secure, encrypted login flow ensuring personal data stays private.

Cloud Firestore: A live-updating dashboard that stores trip history, driver metrics, and custom emergency contact configurations.

🛠 Technical Architecture

| Category | Technology Stack |
| Frontend UI/UX | Flutter (Dart), Material Design 3 |
| Backend & Auth | Firebase Authentication, Cloud Firestore |
| Computer Vision | Google ML Kit (Vision API), Camera Plugin |
| Hardware APIs | Geolocator, Audio Players |

🚀 Getting Started

Follow these instructions to set up the project locally on your machine.

1. Prerequisites

Ensure you have the following installed and configured:

Flutter SDK: Version 3.47.0 (or stable compatible).

Java JDK: Java 17 or 21 is highly recommended. (Note: Java 25 may cause Gradle build failures).

Android Studio / Android SDK: API Level 34 configured.

Physical Device: A physical Android or iOS device is required. Emulators do not support the real-time camera passthrough needed for ML Kit.

2. Installation & Setup

Clone the repository and navigate to the working directory:

git clone https://github.com/your-username/Drive_Safe.git
cd "Drive_Safe/Drive Safe"



Fetch the Dart dependencies:

flutter pub get



3. Firebase Configuration

This project requires a live Firebase connection to function.

Create a new project in the Firebase Console.

Enable Email/Password Authentication.

Create a Firestore Database and set the security rules to allow authenticated read/writes.

Register your Android app and download the google-services.json file.

Place google-services.json inside the android/app/ directory.

4. Build and Run

Connect your physical phone (enable USB Debugging) and compile the app:

flutter run



(If you are testing experimental features located in secondary files, you can target them directly using flutter run -t lib/main1.dart).

🛑 Known Issues & Troubleshooting

Infinite Loading Spinner on Dashboard:
If the app launches but hangs on a loading screen, your Firestore Security Rules have likely expired (Test Mode expires after 30 days), or your Firebase Auth returned a null user. Check your Firebase console.

App Freezes / Crashes on Startup:
The app requires intensive hardware access. If the Android permission pop-ups fail to show, manually go to Settings > Apps > Drive Safe > Permissions and grant Camera and Location access.

Gradle Compatibility Error:
If you get an error regarding Java 25.0.1 being incompatible with Gradle, point Flutter to your Android Studio bundled JDK:
flutter config --jdk-dir="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

🤝 Contributing

We welcome contributions to make roads safer! To contribute:

Fork the Project

Create your Feature Branch (git checkout -b feature/AmazingFeature)

Commit your Changes (`git commit -
