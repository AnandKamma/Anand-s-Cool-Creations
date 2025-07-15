import 'package:flutter/material.dart';
import 'package:cube_transition_plus/cube_transition_plus.dart';
import 'package:lock/components/Animations.dart';
import 'package:lock/screens/Home%20Screen.dart';

class CalibrationPage extends StatefulWidget {
  static const String id = 'calibration_page';
  const CalibrationPage({Key? key}) : super(key: key);

  @override
  State<CalibrationPage> createState() => _CalibrationPageState();
}

class _CalibrationPageState extends State<CalibrationPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _currentIndex = _controller.page?.round() ?? 0;
      });
    });
  }
  Future<bool> saveUnlockedPosition() async {
    try {
      // TODO: Replace with your actual logic (e.g. Bluetooth call)
      print("Unlocked position saved!");
      return true;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }
  Future<bool> saveLockedPosition() async {
    try {
      // Replace this with actual logic (e.g. call to encoder, Firestore, BLE)
      print("Locked position saved.");
      return true;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }
  Future<bool> finalizeCalibration() async {
    try {
      // Replace with actual save logic to Firestore / ESP32
      print("Calibration data saved.");
      return true;
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }




  Widget _buildStep(String title, IconData icon, String buttonLabel, VoidCallback onPressed) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF27302B),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Color(0xFFcbc7bc)),
          SizedBox(height: 30),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lato',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFcbc7bc),
              height: 1.4,
            ),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFcbc7bc),
              foregroundColor: Color(0xFF27302B),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonLabel,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Lato',
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
            (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 30),
          width: _currentIndex == index ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index ? Color(0xFFcbc7bc) : Colors.grey.shade700,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> calibrationSteps = [
      _buildStep(
        "Mount Your Device Onto Your Lock In Unlocked State",
        Icons.build_circle,
        "Set as Unlocked",
            () async {
          // ✅ Perform your async logic here
          bool success = await saveUnlockedPosition(); // this should return true/false

          if (success) {
            _controller.nextPage(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            // Optional: show error or snackbar
            print("❌ Failed to save unlocked position");
          }
        },),
      _buildStep(
        "Rotate the knob to calibrate the lock",
        Icons.lock,
        "Set as Locked",
            () async {
          bool success = await saveLockedPosition();

          if (success) {
            _controller.nextPage(
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          } else {
            print("❌ Failed to save locked position");
          }
        },
      ),
      _buildStep(
        "Calibration complete. You're all set!",
        Icons.check_circle_outline,
        "Save Calibration",
            () async {
          bool success = await finalizeCalibration();

          if (success) {
            Navigator.of(context).pushReplacement(
              FadeToCalibrationRoute(page: HomeScreen()),
            );
          } else {
            print("❌ Failed to save calibration data.");
            // Optionally show a snackbar or dialog
          }
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Color(0xFF27302B),
      body: Column(
        children: [
          Expanded(
            child: CubePageView(
              controller: _controller,
              children: calibrationSteps,
            ),
          ),
          _buildDots(),
        ],
      ),
    );
  }
}
