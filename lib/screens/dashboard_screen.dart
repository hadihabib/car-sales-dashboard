import 'package:flutter/material.dart';
import '../core/database_service.dart';
import '../core/helpers.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  final DatabaseService db;

  const DashboardScreen({
    super.key,
    required this.db,
  });

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;
  String? error;

  int operations = 0;
  int returnsCount = 0;
  num monthSyp = 0;
  num monthUsd = 0;
  num tradersNet = 0;
  List<Map<String, dynamic>> recent = [];

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
      final tx = await widget.db.getTransactions(limit: 500);
      final ledger = await widget.db.getLedger();

      final now = DateTime.now();
      num syp = 0;
      num usd = 0;
      int count = 0;
      int rcount = 0;

      for (final row in tx) {
        if (row['status'] == 'cancelled') continue;

        final created =
            DateTime.tryParse('${row['created_at'] ?? ''}')?.toLocal();

        if (created == null ||
            created.year != now.year ||
            created.month != now.month) {
          continue;
        }

        count++;

        final value = num.tryParse('${row['total_price'] ?? 0}') ?? 0;
        final isReturn = row['transaction_type'] == 'return';
        final sign = isReturn ? -1 : 1;

        if (isReturn) rcount++;

        final currency = '${row['currency'] ?? 'SYP'}'.toUpperCase();

        if (currency == 'USD') {
          usd += value * sign;
        } else {
          syp += value * sign;
        }
      }

      num traderTotal = 0;

      for (final row in ledger) {
        final amount = num.tryParse('${row['amount'] ?? 0}') ?? 0;
        final effect = num.tryParse('${row['balance_effect'] ?? 0}') ?? 0;
        traderTotal += amount * effect;
      }

      if (!mounted) return;

      setState(() {
        operations = count;
        returnsCount = rcount;
        monthSyp = syp;
        monthUsd = usd;
        tradersNet = traderTotal;
        recent = tx.take(8).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = '$e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          const Text(
            'لوحة المحل',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF173B53),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ملخص المبيعات وحسابات التجار',
            style: TextStyle(color: Color(0xFF7A8B96)),
          ),
          const SizedBox(height: 18),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(50),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF1654),
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          else ...[
            StatCard(
              title: 'صافي الشهر - ليرة سورية',
              value: '${money(monthSyp)} SYP',
              icon: Icons.payments_outlined,
              color: const Color(0xFF247BA0),
            ),
            const SizedBox(height: 10),
            StatCard(
              title: 'صافي الشهر - دولار',
              value: '${money(monthUsd)} USD',
              icon: Icons.attach_money,
              color: const Color(0xFF20A77A),
            ),
            const SizedBox(height: 10),
            StatCard(
              title: 'عدد عمليات الشهر',
              value: '$operations',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFFFF9F1C),
            ),
            const SizedBox(height: 10),
            StatCard(
              title: 'مرتجعات الشهر',
              value: '$returnsCount',
              icon: Icons.keyboard_return,
              color: const Color(0xFFFF1654),
            ),
            const SizedBox(height: 10),
            StatCard(
              title: 'الحساب الكلي مع كل التجار',
              value: signedMoney(tradersNet),
              icon: Icons.groups_2_outlined,
              color: tradersNet >= 0
                  ? const Color(0xFF20A77A)
                  : const Color(0xFFFF1654),
            ),
            const SizedBox(height: 24),
            const Text(
              'آخر العمليات',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            if (recent.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(30),
                child: Text('لا توجد عمليات بعد'),
              ))
            else
              ...recent.map(
                (row) => Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4ECF1)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        child: Icon(
                          row['transaction_type'] == 'return'
                              ? Icons.keyboard_return
                              : Icons.shopping_bag_outlined,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${row['customer_name'] ?? 'بدون اسم'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${row['part_name'] ?? 'قطعة غير محددة'}',
                              style: const TextStyle(
                                color: Color(0xFF6F818C),
                              ),
                            ),
                            Text(
                              shortDate(row['created_at']),
                              style: const TextStyle(
                                color: Color(0xFFA0ADB5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${money(row['total_price'])}\n${row['currency'] ?? 'SYP'}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
