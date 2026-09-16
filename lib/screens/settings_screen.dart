import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/database_service.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AppConfig config;
  final DatabaseService db;
  final Future<void> Function(AppConfig config) onConfigChanged;
  final Future<void> Function() onClearConfig;

  const SettingsScreen({
    super.key,
    required this.config,
    required this.db,
    required this.onConfigChanged,
    required this.onClearConfig,
  });

  @override
  State<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool testing = false;
  String? result;

  Future<void> test() async {
    setState(() {
      testing = true;
      result = null;
    });

    try {
      await widget.db.testConnection();
      setState(() => result = 'الاتصال يعمل بشكل صحيح ✅');
    } catch (e) {
      setState(() => result = 'فشل الاتصال: $e');
    } finally {
      if (mounted) setState(() => testing = false);
    }
  }

  Future<void> editConnection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetupScreen(
          initial: widget.config,
          allowCancel: true,
          onSaved: (newConfig) async {
            await widget.onConfigChanged(newConfig);
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final key = widget.config.publishableKey;
    final shortKey = key.length > 18
        ? '${key.substring(0, 10)}...${key.substring(key.length - 6)}'
        : key;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      children: [
        const Text(
          'الإعدادات',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اتصال Supabase',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Project URL',
                style: TextStyle(color: Color(0xFF778994)),
              ),
              SelectableText(
                widget.config.url,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 12),
              const Text(
                'Publishable Key',
                style: TextStyle(color: Color(0xFF778994)),
              ),
              SelectableText(
                shortKey,
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: testing ? null : test,
                icon: const Icon(Icons.wifi_tethering_outlined),
                label: const Text('اختبار الاتصال'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: editConnection,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تغيير الاتصال'),
              ),
              if (result != null) ...[
                const SizedBox(height: 10),
                Text(result!),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'إعادة الإعداد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'يمسح رابط ومفتاح Supabase من هذا الهاتف فقط، '
                'ولا يحذف أي بيانات من قاعدة البيانات.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onClearConfig,
                icon: const Icon(Icons.restart_alt),
                label: const Text('مسح الإعدادات والبدء من جديد'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
