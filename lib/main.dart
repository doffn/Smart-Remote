import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'scan_tab.dart';
import 'about_tab.dart';
import 'remote_tab.dart';
import 'web_hub_tab.dart';
import 'lucky_stb.dart';

void main() {
  runApp(const LuckyApp());
}

class LuckyApp extends StatefulWidget {
  const LuckyApp({super.key});

  @override
  State<LuckyApp> createState() => _LuckyAppState();
}

class _LuckyAppState extends State<LuckyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    _saveTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;

    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucky STB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      themeMode: _themeMode,
      // Launch the pre-splash first
      home: PreSplashWrapper(onThemeToggle: toggleTheme),
    );
  }
}

/// ---------------- PreSplash Wrapper ----------------
/// Shows pre-splash then loads MainScreen
class PreSplashWrapper extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const PreSplashWrapper({super.key, required this.onThemeToggle});

  @override
  State<PreSplashWrapper> createState() => _PreSplashWrapperState();
}

class _PreSplashWrapperState extends State<PreSplashWrapper> {
  bool _showMain = false;

  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  void _startSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _showMain = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMain) {
      return MainScreen(
        onThemeToggle: widget.onThemeToggle,
        onUpdateState: () {},
      );
    }

    return Scaffold(
      body: Container(
        color: Colors.blue.shade50,
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_icon.png', // your app icon
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 16),
            const Text(
              "Smart STB maker",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// ------------------- MainScreen code below stays completely unchanged -------------------

class MainScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final VoidCallback onUpdateState;

  const MainScreen({
    super.key,
    required this.onThemeToggle,
    required this.onUpdateState,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final LuckySTB lucky = LuckySTB();

  String? selectedIp;
  List<String> devices = [];
  bool isScanning = false;
  bool isFullRemote = false;
  String scanStatus = "Ready to scan";

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('selectedIp');

    if (savedIp != null && savedIp.isNotEmpty) {
      setState(() {
        selectedIp = savedIp;
        devices = [savedIp];
      });
    }
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedIp', ip);
  }

  void updateSelectedIp(String ip) {
    setState(() {
      selectedIp = ip;
    });
    _saveIp(ip);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      ScanTab(
        lucky: lucky,
        selectedIp: selectedIp,
        devices: devices,
        isScanning: isScanning,
        scanStatus: scanStatus,
        onStateChanged: (scanning, status, deviceList) {
          setState(() {
            isScanning = scanning;
            scanStatus = status;
            devices = deviceList;
          });
        },
        onDeviceSelected: updateSelectedIp,
      ),
      RemoteTab(
        lucky: lucky,
        selectedIp: selectedIp,
        isFullRemote: isFullRemote,
      ),
      WebHubTab(
        lucky: lucky,
        selectedIp: selectedIp,
      ),
      const AboutTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: Text(
          _selectedIndex == 1
              ? (isFullRemote ? "Full Remote" : "Mini Remote")
              : _selectedIndex == 3
                  ? "About"
                  : "Lucky STB",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
        actions: [
          if (_selectedIndex == 0 || _selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: widget.onThemeToggle,
            ),
          if (_selectedIndex == 1)
            IconButton(
              icon: Icon(
                isFullRemote ? Icons.view_compact : Icons.fullscreen,
              ),
              onPressed: () => setState(() => isFullRemote = !isFullRemote),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wifi_find), label: 'Scan'),
          NavigationDestination(
              icon: Icon(Icons.settings_remote), label: 'Remote'),
          NavigationDestination(icon: Icon(Icons.language), label: 'WebHub'),
          NavigationDestination(icon: Icon(Icons.info_outline), label: 'About'),
        ],
      ),
    );
  }
}
