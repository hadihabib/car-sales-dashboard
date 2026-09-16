import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const CarSalesApp());
}

SupabaseClient? get supabase =>
    AppConfig.isConfigured ? Supabase.instance.client : null;

class CarSalesApp extends StatelessWidget {
  const CarSalesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لوحة المحل',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF247BA0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8FB),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: RootPage(),
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isConfigured) {
      return const ConfigurationPage();
    }
    return const MainShell();
  }
}

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE1EAF0)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.settings_outlined,
                    size: 58,
                    color: Color(0xFF247BA0),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'باقي إعداد Supabase',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF163A52),
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'افتح lib/config.dart وضع Project URL و Publishable key ثم أعد بناء التطبيق.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.6,
                      color: Color(0xFF657985),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    SalesPage(),
    TradersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[index]),
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
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;

  const Header({
    super.key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF163A52),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7C8F9B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onRefresh != null)
            IconButton.filledTonal(
              onPressed: onRefresh,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  String? error;

  int monthCount = 0;
  num monthNet = 0;
  num returnsValue = 0;
  num traderNet = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final client = supabase!;
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1).toUtc();

      final transactions = await client
          .from('transactions')
          .select()
          .gte('created_at', firstDay.toIso8601String())
          .order('created_at', ascending: false);

      num net = 0;
      num returned = 0;
      var count = 0;

      for (final row in transactions) {
        if (row['status'] == 'cancelled') continue;

        count += 1;
        final total = _asNum(row['total_price']);

        if (row['transaction_type'] == 'return') {
          net -= total;
          returned += total;
        } else {
          net += total;
        }
      }

      final ledger = await client
          .from('merchant_ledger')
          .select('amount,balance_effect');

      num merchantsNet = 0;
      for (final row in ledger) {
        merchantsNet +=
            _asNum(row['amount']) * _asNum(row['balance_effect']);
      }

      if (!mounted) return;

      setState(() {
        monthCount = count;
        monthNet = net;
        returnsValue = returned;
        traderNet = merchantsNet;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Header(
            title: 'لوحة المحل',
            subtitle: 'المبيعات وحسابات التجار',
            onRefresh: load,
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            ErrorBox(message: error!, onRetry: load)
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
              child: Column(
                children: [
                  StatCard(
                    title: 'صافي هذا الشهر',
                    value: _money(monthNet),
                    icon: Icons.trending_up,
                    accent: const Color(0xFF247BA0),
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'عدد عمليات الشهر',
                    value: '$monthCount',
                    icon: Icons.receipt_long,
                    accent: const Color(0xFF70C1B3),
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'قيمة المرتجعات',
                    value: _money(returnsValue),
                    icon: Icons.keyboard_return,
                    accent: const Color(0xFFFF9F1C),
                  ),
                  const SizedBox(height: 12),
                  StatCard(
                    title: 'صافي الحساب مع كل التجار',
                    value: traderNet > 0
                        ? '+${_money(traderNet)}'
                        : _money(traderNet),
                    icon: Icons.groups_2_outlined,
                    accent: traderNet >= 0
                        ? const Color(0xFF20A77A)
                        : const Color(0xFFFF1654),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EBF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withAlpha(28),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF7C8F9B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF163A52),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await supabase!
          .from('transactions')
          .select()
          .order('created_at', ascending: false)
          .limit(200);

      if (!mounted) return;

      setState(() {
        rows = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: 'المبيعات',
          subtitle: 'آخر 200 عملية',
          onRefresh: load,
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? ListView(
                      children: [
                        ErrorBox(message: error!, onRetry: load),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: load,
                      child: rows.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 100),
                                EmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  text: 'لا توجد عمليات بعد',
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 6, 18, 30),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  TransactionCard(row: rows[i]),
                            ),
                    ),
        ),
      ],
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> row;

  const TransactionCard({
    super.key,
    required this.row,
  });

  @override
  Widget build(BuildContext context) {
    final isReturn = row['transaction_type'] == 'return';
    final customer = _display(row['customer_name'], 'بدون اسم');
    final part = _display(row['part_name'], 'قطعة غير محددة');

    final car = [
      _display(row['car_make'], ''),
      _display(row['car_model'], ''),
    ].where((e) => e.isNotEmpty).join(' ');

    final currency = _display(row['currency'], 'SYP');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isReturn
              ? const Color(0xFFFFD4DF)
              : const Color(0xFFE2EBF0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isReturn
                  ? const Color(0xFFFFEAF0)
                  : const Color(0xFFEAF5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isReturn
                  ? Icons.keyboard_return
                  : Icons.shopping_bag_outlined,
              color: isReturn
                  ? const Color(0xFFFF1654)
                  : const Color(0xFF247BA0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF163A52),
                        ),
                      ),
                    ),
                    Text(
                      '${_money(row['total_price'])} $currency',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isReturn
                            ? const Color(0xFFFF1654)
                            : const Color(0xFF163A52),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  part,
                  style: const TextStyle(
                    color: Color(0xFF536976),
                    fontSize: 14,
                  ),
                ),
                if (car.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    car,
                    style: const TextStyle(
                      color: Color(0xFF7C8F9B),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      _shortDate(row['created_at']),
                      style: const TextStyle(
                        color: Color(0xFFA0ADB5),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (isReturn)
                      const Text(
                        'مرتجع',
                        style: TextStyle(
                          color: Color(0xFFFF1654),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TradersPage extends StatefulWidget {
  const TradersPage({super.key});

  @override
  State<TradersPage> createState() => _TradersPageState();
}

class _TradersPageState extends State<TradersPage> {
  bool loading = true;
  String? error;

  num totalNet = 0;
  List<Map<String, dynamic>> traders = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final client = supabase!;

      final merchantRows = await client
          .from('merchants')
          .select('id,name')
          .eq('is_active', true)
          .order('name');

      final ledgerRows = await client
          .from('merchant_ledger')
          .select('merchant_id,amount,balance_effect');

      final totals = <int, num>{};

      for (final row in ledgerRows) {
        final merchantId = int.tryParse('${row['merchant_id']}');
        if (merchantId == null) continue;

        totals[merchantId] = (totals[merchantId] ?? 0) +
            (_asNum(row['amount']) * _asNum(row['balance_effect']));
      }

      final result = <Map<String, dynamic>>[];
      num all = 0;

      for (final row in merchantRows) {
        final merchantId = int.tryParse('${row['id']}');
        if (merchantId == null) continue;

        final net = totals[merchantId] ?? 0;
        all += net;

        result.add({
          'id': merchantId,
          'name': row['name'] ?? 'تاجر',
          'net': net,
        });
      }

      if (!mounted) return;

      setState(() {
        traders = result;
        totalNet = all;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Header(
          title: 'حسابات التجار',
          subtitle: 'الصافي الحالي لكل تاجر',
          onRefresh: load,
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? ListView(
                      children: [
                        ErrorBox(message: error!, onRetry: load),
                      ],
                    )
                  : RefreshIndicator(
                      onRefresh: load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 30),
                        children: [
                          StatCard(
                            title: 'الحساب الكلي مع كل التجار',
                            value: totalNet > 0
                                ? '+${_money(totalNet)}'
                                : _money(totalNet),
                            icon: Icons.account_balance_wallet_outlined,
                            accent: totalNet >= 0
                                ? const Color(0xFF20A77A)
                                : const Color(0xFFFF1654),
                          ),
                          const SizedBox(height: 16),
                          if (traders.isEmpty)
                            const EmptyState(
                              icon: Icons.groups_outlined,
                              text: 'لا يوجد تجار بعد',
                            )
                          else
                            ...traders.map((row) {
                              final net = row['net'] as num;
                              final positive = net >= 0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE2EBF0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: positive
                                            ? const Color(0xFFE8F7F1)
                                            : const Color(0xFFFFEAF0),
                                        child: Icon(
                                          Icons.person_outline,
                                          color: positive
                                              ? const Color(0xFF20A77A)
                                              : const Color(0xFFFF1654),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${row['name']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF163A52),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            net > 0
                                                ? '+${_money(net)}'
                                                : _money(net),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              color: positive
                                                  ? const Color(0xFF20A77A)
                                                  : const Color(0xFFFF1654),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            net > 0
                                                ? 'إلي عنده'
                                                : net < 0
                                                    ? 'عليّ إله'
                                                    : 'الحساب صفر',
                                            style: const TextStyle(
                                              color: Color(0xFF8B9AA4),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorBox({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFCDD8)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: Color(0xFFFF1654),
            ),
            const SizedBox(height: 10),
            const Text(
              'تعذر الاتصال بالبيانات',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: Color(0xFF163A52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF657985),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const EmptyState({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(38),
      child: Column(
        children: [
          Icon(
            icon,
            size: 52,
            color: const Color(0xFFAAB7BF),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF7C8F9B),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

num _asNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('${value ?? 0}') ?? 0;
}

String _display(dynamic value, String fallback) {
  final s = '${value ?? ''}'.trim();
  return s.isEmpty ? fallback : s;
}

String _money(dynamic value) {
  final rounded = _asNum(value).round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();

  final output = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    output.write(digits[i]);

    if (remaining > 1 && remaining % 3 == 1) {
      output.write(',');
    }
  }

  return negative ? '-$output' : output.toString();
}

String _shortDate(dynamic value) {
  if (value == null) return '-';

  final date = DateTime.tryParse(value.toString())?.toLocal();
  if (date == null) return '-';

  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');

  return '$d/$m  $h:$min';
}
