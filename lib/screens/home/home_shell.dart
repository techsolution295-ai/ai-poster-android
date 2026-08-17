import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

/// Hosts the primary tabs with a bottom navigation bar. Uses an [IndexedStack]
/// so each tab keeps its state when switching.
///
/// The Home tab now contains the category row + templates grid, so a separate
/// "Templates" tab is no longer needed.
class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  late int _index = widget.initialIndex;
  final _historyKey = GlobalKey<HistoryScreenState>();

  late final _tabs = <Widget>[
    const HomeScreen(),
    HistoryScreen(key: _historyKey),
    const SettingsScreen(),
  ];

  /// Allows children to switch tabs.
  void goToTab(int index) {
    setState(() => _index = index);
    if (index == 1) {
      _historyKey.currentState?.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: goToTab,
            elevation: 0,
            selectedFontSize: 13,
            unselectedFontSize: 13,
            iconSize: 23,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.house),
                activeIcon: Icon(CupertinoIcons.house_fill),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.clock),
                activeIcon: Icon(CupertinoIcons.clock_fill),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.gear),
                activeIcon: Icon(CupertinoIcons.gear_solid),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
