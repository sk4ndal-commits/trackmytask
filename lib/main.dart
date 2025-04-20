import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'package:trackmytasks/services/task_service.dart';
import 'package:trackmytasks/services/theme_service.dart';
import 'package:trackmytasks/screens/home_screen.dart';
import 'package:trackmytasks/screens/task_list_screen.dart';
import 'package:trackmytasks/screens/daily_summary_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite_common_ffi for desktop (Linux, MacOS, Windows)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize sqflite ffi mode for database access
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Initialize window manager
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            themeMode: themeService.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const AppContainer(),
            routes: {
              '/tasks': (context) => const TaskListScreen(),
              '/summary': (context) => const DailySummaryScreen(),
            },
          );
        },
      ),
    );
  }
}

class AppContainer extends StatefulWidget {
  const AppContainer({super.key});

  @override
  State<AppContainer> createState() => _AppContainerState();
}

class _AppContainerState extends State<AppContainer> with WindowListener {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TaskListScreen(),
    const DailySummaryScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Set up window manager
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _showWindow() {
    windowManager.show();
    windowManager.focus();
  }


  @override
  void onWindowClose() async {
    // Hide the window instead of closing it
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: themeService.isDarkMode ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () {
              themeService.toggleTheme();
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize),
            label: 'Summary',
          ),
        ],
      ),
    );
  }
}
