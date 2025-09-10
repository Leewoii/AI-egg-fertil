import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'screens/login.dart';
import 'screens/gradients.dart';
import 'screens/egg_tray_screen.dart';
import 'firebase_options.dart';
import 'notification_service.dart'; // Update path if necessary


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

await NotificationService().initializeNotifications();

  // Initialize SharedPreferences
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedEmail = prefs.getString('userEmail');

  runApp(MyApp(savedEmail: savedEmail)); // Pass saved email to MyApp
}

class MyApp extends StatelessWidget {
  final String? savedEmail; // Field for the saved email

  const MyApp({super.key, required this.savedEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove the debug banner
      title: 'Chick-N-Bator',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Determine home based on savedEmail
      home: savedEmail != null
          ? DashboardScreen(userEmail: savedEmail) // Pass savedEmail safely
          : const LoginPage(), // Show LoginPage if email is null
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          final userEmail =
              args?['email'] ?? ''; // Ensure userEmail is non-null
          return DashboardScreen(
              userEmail: userEmail); // Pass email to DashboardScreen
        },
        '/egg_tray': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>?;
          final macAddress = args?['macAddress'] ?? ''; // Get macAddress
          return EggTrayScreen(macAddress: macAddress);
        },
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final String? userEmail; // Accept nullable userEmail

  const DashboardScreen({super.key, required this.userEmail});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _selectedIncubator;
  List<Map<String, String>> incubators = [];

  // Initialize temperature and humidity values
  double temperaturehatchery = 0;
  double humidityhatchery = 0;
  double temperaturesetter = 0;
  double humiditysetter = 0;
  double waterLevel = 0;

  
@override
void initState() {
  super.initState();

  // Initialize notifications asynchronously
  _initializeNotifications();
  _loadSelectedIncubator();
  _fetchIncubators();
}

Future<void> _initializeNotifications() async {
  // Initialize FCM
  NotificationService notificationService = NotificationService();
  await notificationService.initializeFcm();

  // After FCM setup, show a welcome notification
  await notificationService.showNotification(
    'Welcome', // Title of the notification
    'Dashboard loaded successfully!' // Body of the notification
  );

  // Start Firestore monitoring after FCM initialization
  notificationService.startMonitoring();
}


Future<void> _clearPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('userEmail'); // Clear only the saved email
}

Future<void> restorePreferences(String userEmail) async {
  final prefs = await SharedPreferences.getInstance();

  // Fetch data from Firebase
  final QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('Detection')
      .where('access', isEqualTo: userEmail)
      .get();

  if (snapshot.docs.isNotEmpty) {
    // Assume first incubator as the default for simplicity
    final Map<String, dynamic> incubatorData = snapshot.docs.first.data() as Map<String, dynamic>;

    // Save relevant data to SharedPreferences
    prefs.setString('selectedIncubator', incubatorData['incubatorName']);
  }
}


  Future<void> _loadSelectedIncubator() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedIncubator = prefs.getString('selectedIncubator');
    });
  }

  Future<void> _saveSelectedIncubator(String? incubatorName) async {
    final prefs = await SharedPreferences.getInstance();
    if (incubatorName != null) {
      await prefs.setString('selectedIncubator', incubatorName);
    }
  }

  Future<void> _fetchIncubators() async {
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('Detection')
        .where('access', isEqualTo: widget.userEmail) // Filter by user email or access
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        incubators = snapshot.docs.map((doc) {
          final incubatorName = doc['incubatorName'] as String?;
          final macAddress = doc['macAddress'] as String?;
          if (incubatorName != null && macAddress != null) {
            return {
              'incubatorName': incubatorName,
              'macAddress': macAddress,
            };
          } else {
            return null;
          }
        }).whereType<Map<String, String>>().toList();

        // Validate _selectedIncubator
        if (_selectedIncubator == null ||
            !incubators.any((incubator) => incubator['incubatorName'] == _selectedIncubator)) {
          _selectedIncubator = null;
        }
      });
    } else {
      setState(() {
        incubators = [];
        _selectedIncubator = null; // Reset if no incubators found
      });
    }
  } catch (e) {
    print("Error fetching incubators: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    double horizontalPadding = MediaQuery.of(context).size.width * 0.1;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Text(
                widget.userEmail ?? "No email",
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: StatefulBuilder(
                builder: (context, setState) => DropdownButton<String>(
  hint: Text(_selectedIncubator ?? "Select an incubator"),
  value: incubators.isNotEmpty
      ? _selectedIncubator
      : null, // Set value to null if no incubators
  onChanged: (String? newValue) {
    setState(() {
      _selectedIncubator = newValue;
    });
    _saveSelectedIncubator(newValue);
  },
  items: incubators.isNotEmpty
      ? incubators.map<DropdownMenuItem<String>>(
          (Map<String, String> incubator) {
            return DropdownMenuItem<String>(
              value: incubator['incubatorName'],
              child: Text(incubator['incubatorName']!),
            );
          },
        ).toList()
      : [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('No incubators available'),
          ),
        ],
),

              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
              onPressed: () async {
               await _clearPreferences(); // Clear SharedPreferences
                 Navigator.pushReplacementNamed(context, '/login');
},

                child: const Text('Logout', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Egg Setter Monitor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Detection')
                    .where('access', isEqualTo: widget.userEmail) // Listen for changes based on access
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No data available');
                  }

                  final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;

                  // Extract the values from Firestore document
temperaturesetter = (data['Tray_Temperature'] ?? 0).toDouble();
humiditysetter = (data['Tray_Humidity'] ?? 0).toDouble();
temperaturehatchery = (data['Hatchery_Temperature'] ?? 0).toDouble();
humidityhatchery = (data['Hatchery_Humidity'] ?? 0).toDouble();
waterLevel = (data['WaterLevel'] ?? 0).toDouble();

return Column(
  crossAxisAlignment: CrossAxisAlignment.start, // Aligns all child widgets to the left
  children: [
    // Temperature and Humidity Row (Setter)
    Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            decoration: BoxDecoration(
              gradient: getTemperatureGradient(temperaturesetter),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                const Icon(Icons.thermostat, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Temperature',
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${temperaturesetter.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            decoration: BoxDecoration(
              gradient: getHumidityGradient(humiditysetter),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                const Icon(Icons.water_drop, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Humidity',
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${humiditysetter.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 16),

    // Hatchery Monitor Label
    Padding(
      padding: const EdgeInsets.only(left: 16.0), // Align to the left with padding
      child: const Text(
        'Hatchery Monitor',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    const SizedBox(height: 16),

    // Temperature and Humidity Row (Hatchery)
    Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            decoration: BoxDecoration(
              gradient: getTemperatureGradient(temperaturehatchery),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                const Icon(Icons.thermostat, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Temperature',
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${temperaturehatchery.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            decoration: BoxDecoration(
              gradient: getHumidityGradient(humidityhatchery),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              children: [
                const Icon(Icons.water_drop, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  'Humidity',
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${humidityhatchery.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ],
);
                },
              ),
               const SizedBox(height: 16),
                   // Tray Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16.0),
                  backgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  if (_selectedIncubator != null) {
                    // Get the macAddress corresponding to the selected incubator
                    final selectedIncubatorData = incubators.firstWhere(
                        (incubator) =>
                            incubator['incubatorName'] == _selectedIncubator);
                    String macAddress = selectedIncubatorData['macAddress']!;

                    // Navigate to EggTrayScreen when the Tray button is pressed
                    Navigator.pushNamed(context, '/egg_tray', arguments: {
                      'selectedIncubator': _selectedIncubator,
                      'macAddress': macAddress, // Pass macAddress to EggTrayScreen
                    });
                  } else {
                    // Show a message if no incubator is selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please select an incubator")),
                    );
                  }
                },
                child: const Center(
                  child: Text(
                    'Tray',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
// Water Level Indicator with Gradient Background
Container(
  width: double.infinity,
  height: MediaQuery.of(context).size.height * 0.3,
  decoration: BoxDecoration(
    gradient: getWaterLevelGradient(waterLevel),
    borderRadius: BorderRadius.circular(8.0),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.water_drop, color: Colors.white, size: 32),
      const SizedBox(height: 8),
      Text(
        'Water Level',
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${waterLevel.toStringAsFixed(1)}%',
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),
),
const SizedBox(height: 16),

            ],
          ),
        ),
      ),
    );
  }
}