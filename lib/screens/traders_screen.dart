import 'package:flutter/material.dart';

import '../core/database_service.dart';
import '../core/helpers.dart';
import '../dialogs/merchant_dialog.dart';
import 'merchant_detail_screen.dart';

class TradersScreen extends StatefulWidget {
  final DatabaseService db;

  const TradersScreen({
    super.key,
    required this.db,
  });

  @override
  State<TradersScreen> createState() => TradersScreenState();
}

class TradersScreenState extends State<TradersScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> merchants = [];
  List<Map<String, dynamic>> ledger = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Map<int, num> get totals {
    final result = <int, num>{};

    for (final row in ledger) {
      final id = int.tryParse('${row['merchant_id']}');
      if (id == null) continue;

      final amount = num.tryParse('${row['amount'] ?? 0}') ?? 0;
      final effect = num.tryParse('${row['balance_effect'] ?? 0}') ?? 0;

      result[id] = (result[id] ?? 0) + amount * effect;
    }

    return result;
  }

  num get totalNet =>
      totals.values.fold<num>(0, (previous, value) => previous + value);

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final m = await widget.db.getMerchants();
      final l = await widget.db.getLedger();

      if (!mounted) return;

      setState(() {
        merchants = m;
        ledger = l;
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

  Future<void> add() async {
    final values = await showMerchantEditor(context);
    if (values == null) return;

    try {
      await widget.db.addMerchant(values);
      await load();
    } catch (e) {
      showError(e);
    }
  }

  Future<void> edit(Map<String, dynamic> row) async {
    final values = await showMerchantEditor(
      context,
      initial: row,
    );
    if (values == null) return;

    try {
      await widget.db.updateMerchant(
        int.parse('${row['id']}'),
        values,
      );
      await load();
    } catch (e) {
      showError(e);
    }
  }

  Future<void> delete(Map<String, dynamic> row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف التاجر؟'),
        content: const Text(
          'إذا كان عنده حركات مالية، قد ترفض قاعدة البيانات الحذف '
          'حتى تحذف حركاته أولاً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await widget.db.deleteMerchant(int.parse('${row['id']}'));
      await load();
    } catch (e) {
      showError(e);
    }
  }

  void showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('حدث خطأ: $e')),
    );
  }

  Future<void> open(Map<String, dynamic> row) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MerchantDetailScreen(
          db: widget.db,
          merchant: row,
        ),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final map = totals;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('إضافة تاجر'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'حسابات التجار',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: load,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            if (!loading && error == null)
              Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'الحساب الكلي مع كل التجار',
                        style: TextStyle(
                          color: Color(0xFF72848F),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      signedMoney(totalNet),
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: totalNet >= 0
                            ? const Color(0xFF20A77A)
                            : const Color(0xFFFF1654),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text(error!))
                      : RefreshIndicator(
                          onRefresh: load,
                          child: merchants.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 140),
                                    Center(child: Text('لا يوجد تجار بعد')),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    18, 8, 18, 100,
                                  ),
                                  itemCount: merchants.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final row = merchants[i];
                                    final id = int.parse('${row['id']}');
                                    final net = map[id] ?? 0;
                                    final positive = net >= 0;

                                    return Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        onTap: () => open(row),
                                        borderRadius: BorderRadius.circular(18),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: positive
                                                    ? const Color(0xFFEAF8F2)
                                                    : const Color(0xFFFFEAF0),
                                                child: Icon(
                                                  Icons.storefront_outlined,
                                                  color: positive
                                                      ? const Color(0xFF20A77A)
                                                      : const Color(0xFFFF1654),
                                                ),
                                              ),
                                              const SizedBox(width: 11),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${row['name']}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                    if ('${row['phone'] ?? ''}'
                                                        .isNotEmpty)
                                                      Text(
                                                        '${row['phone']}',
                                                        style: const TextStyle(
                                                          color:
                                                              Color(0xFF82929C),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    signedMoney(net),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: positive
                                                          ? const Color(
                                                              0xFF20A77A)
                                                          : const Color(
                                                              0xFFFF1654),
                                                    ),
                                                  ),
                                                  Text(
                                                    net > 0
                                                        ? 'إلي عنده'
                                                        : net < 0
                                                            ? 'عليّ إله'
                                                            : 'صفر',
                                                    style: const TextStyle(
                                                      color: Color(0xFF8A9AA4),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              PopupMenuButton<String>(
                                                onSelected: (v) {
                                                  if (v == 'edit') {
                                                    edit(row);
                                                  } else if (v == 'delete') {
                                                    delete(row);
                                                  }
                                                },
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                    value: 'edit',
                                                    child:
                                                        Text('تعديل التاجر'),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete',
                                                    child:
                                                        Text('حذف التاجر'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
