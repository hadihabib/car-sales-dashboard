import 'package:flutter/material.dart';
import '../core/app_config.dart';
import '../core/database_service.dart';

class SetupScreen extends StatefulWidget {
  final AppConfig? initial;
  final Future<void> Function(AppConfig config) onSaved;
  final bool allowCancel;

  const SetupScreen({
    super.key,
    required this.onSaved,
    this.initial,
    this.allowCancel = false,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController url;
  late final TextEditingController key;

  bool working = false;
  bool hide = true;
  String? message;
  bool ok = false;

  @override
  void initState() {
    super.initState();
    url = TextEditingController(text: widget.initial?.url ?? '');
    key = TextEditingController(text: widget.initial?.publishableKey ?? '');
  }

  @override
  void dispose() {
    url.dispose();
    key.dispose();
    super.dispose();
  }

  Future<AppConfig?> test() async {
    final u = url.text.trim();
    final k = key.text.trim();

    if (u.isEmpty || k.isEmpty) {
      setState(() {
        ok = false;
        message = 'اكتب Project URL والـ Publishable Key.';
      });
      return null;
    }

    setState(() {
      working = true;
      message = null;
    });

    try {
      final db = DatabaseService(url: u, publishableKey: k);
      await db.testConnection();

      final config = AppConfig(url: u, publishableKey: k);

      setState(() {
        ok = true;
        message = 'تم الاتصال بنجاح ✅';
      });

      return config;
    } catch (e) {
      setState(() {
        ok = false;
        message = 'تعذر الاتصال:\n$e';
      });
      return null;
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> save() async {
    final config = await test();
    if (config == null) return;
    await widget.onSaved(config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.allowCancel
          ? AppBar(title: const Text('إعداد الاتصال'))
          : null,
      backgroundColor: const Color(0xFFF4F8FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.storage_rounded,
                      size: 56,
                      color: Color(0xFF247BA0),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ربط التطبيق بقاعدة البيانات',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'هذه الشاشة تظهر أول مرة فقط. '
                      'استخدم Project URL والـ Publishable Key من Supabase.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: url,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'Supabase Project URL',
                        hintText: 'https://xxxx.supabase.co',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: key,
                      textDirection: TextDirection.ltr,
                      obscureText: hide,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Publishable Key',
                        hintText: 'sb_publishable_...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => hide = !hide),
                          icon: Icon(
                            hide
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ok
                              ? const Color(0xFFEAF8F2)
                              : const Color(0xFFFFEEF2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(message!),
                      ),
                    ],
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: working ? null : test,
                      icon: const Icon(Icons.wifi_tethering_outlined),
                      label: const Text('اختبار الاتصال'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: working ? null : save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('حفظ وفتح التطبيق'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
