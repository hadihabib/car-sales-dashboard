import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_config.dart';
import 'core/database_service.dart';
import 'screens/home_shell.dart';
import 'screens/setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(CarSalesApp(initialConfig: config));
}

class CarSalesApp extends StatefulWidget {
  final AppConfig? initialConfig;

  const CarSalesApp({
    super.key,
    required this.initialConfig,
  });

  @override
  State<CarSalesApp> createState() => _CarSalesAppState();
}

class _CarSalesAppState extends State<CarSalesApp> {
  AppConfig? config;
  DatabaseService? db;

  @override
  void initState() {
    super.initState();
    apply(widget.initialConfig);
  }

  void apply(AppConfig? value) {
    config = value;

    if (value == null) {
      db = null;
    } else {
      db = DatabaseService(
        url: value.url,
        publishableKey: value.publishableKey,
      );
    }
  }

  Future<void> saveConfig(AppConfig value) async {
    await value.save();
    setState(() => apply(value));
  }

  Future<void> clearConfig() async {
    await AppConfig.clear();
    setState(() => apply(null));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'إدارة مبيعات قطع السيارات',
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F8FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF247BA0),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: config == null || db == null
          ? SetupScreen(onSaved: saveConfig)
          : HomeShell(
              key: ValueKey(
                '${config!.url}:${config!.publishableKey.hashCode}',
              ),
              config: config!,
              db: db!,
              onConfigChanged: saveConfig,
              onClearConfig: clearConfig,
            ),
    );
  }
}
