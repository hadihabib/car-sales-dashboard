import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/database_service.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'traders_screen.dart';
import 'transactions_screen.dart';

class HomeShell extends StatefulWidget {
  final AppConfig config;
  final DatabaseService db;
  final Future<void> Function(AppConfig config) onConfigChanged;
  final Future<void> Function() onClearConfig;

  const HomeShell({
    super.key,
    required this.config,
    required this.db,
    required this.onConfigChanged,
    required this.onClearConfig,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(db: widget.db),
      TransactionsScreen(db: widget.db),
      TradersScreen(db: widget.db),
      SettingsScreen(
        config: widget.config,
        db: widget.db,
        onConfigChanged: widget.onConfigChanged,
        onClearConfig: widget.onClearConfig,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          setState(() => index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'المبيعات',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'التجار',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
