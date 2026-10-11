import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/history_screen.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();
runApp(const SpeedXApp());
}

class SpeedXApp extends StatelessWidget {
const SpeedXApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'SpeedX',
debugShowCheckedModeBanner: false,
theme: ThemeData(
brightness: Brightness.dark,
scaffoldBackgroundColor: const Color(0xFF0B111B),
colorScheme: const ColorScheme.dark(
primary: Color(0xFF35D9FF),
surface: Color(0xFF18212F),
),
useMaterial3: true,
),
home: const MainNavigation(),
);
}
}

class MainNavigation extends StatefulWidget {
const MainNavigation({super.key});

@override
State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
int _selectedIndex = 0;

final List<Widget> _screens = const [
HomeScreen(),
HistoryScreen(),
];

@override
Widget build(BuildContext context) {
return Scaffold(
body: IndexedStack(
index: _selectedIndex,
children: _screens,
),
bottomNavigationBar: NavigationBar(
selectedIndex: _selectedIndex,
backgroundColor: const Color(0xFF111A27),
indicatorColor: const Color(0xFF35D9FF).withValues(alpha: 0.15),
onDestinationSelected: (index) {
setState(() {
_selectedIndex = index;
});
},
destinations: const [
NavigationDestination(
icon: Icon(Icons.speed_outlined),
selectedIcon: Icon(Icons.speed),
label: 'Speedometer',
),
NavigationDestination(
icon: Icon(Icons.history),
selectedIcon: Icon(Icons.history_toggle_off),
label: 'History',
),
],
),
);
}
}
