import 'package:flutter/material.dart';

import '../core/database_service.dart';
import '../core/helpers.dart';
import '../dialogs/ledger_dialog.dart';
import '../dialogs/merchant_dialog.dart';

class MerchantDetailScreen extends StatefulWidget {
  final DatabaseService db;
  final Map<String, dynamic> merchant;

  const MerchantDetailScreen({
    super.key,
    required this.db,
    required this.merchant,
  });

  @override
  State<MerchantDetailScreen> createState() =>
      _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends State<MerchantDetailScreen> {
  late Map<String, dynamic> merchant;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    merchant = Map<String, dynamic>.from(widget.merchant);
    load();
  }

  int get merchantId => int.parse('${merchant['id']}');

  num get net {
    num result = 0;
    for (final row in rows) {
      final amount = num.tryParse('${row['amount'] ?? 0}') ?? 0;
      final effect = num.tryParse('${row['balance_effect'] ?? 0}') ?? 0;
      result += amount * effect;
    }
    return result;
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await widget.db.getLedger(merchantId: merchantId);
      if (!mounted) return;

      setState(() {
        rows = data;
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

  Future<void> editMerchant() async {
    final values = await showMerchantEditor(
      context,
      initial: merchant,
    );
    if (values == null) return;

    try {
      await widget.db.updateMerchant(merchantId, values);
      setState(() {
        merchant = {...merchant, ...values};
      });
    } catch (e) {
      showError(e);
    }
  }

  Future<void> addMovement() async {
    final values = await showLedgerEditor(
      context,
      merchantId: merchantId,
    );
    if (values == null) return;

    try {
      await widget.db.addLedger(values);
      await load();
    } catch (e) {
      showError(e);
    }
  }

  Future<void> editMovement(Map<String, dynamic> row) async {
    final values = await showLedgerEditor(
      context,
      merchantId: merchantId,
      initial: row,
    );
    if (values == null) return;

    try {
      await widget.db.updateLedger(
        int.parse('${row['id']}'),
        values,
      );
      await load();
    } catch (e) {
      showError(e);
    }
  }

  Future<void> deleteMovement(Map<String, dynamic> row) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الحركة؟'),
        content: const Text('سيتم حذف الحركة نهائياً.'),
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
      await widget.db.deleteLedger(int.parse('${row['id']}'));
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

  @override
  Widget build(BuildContext context) {
    final positive = net >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      appBar: AppBar(
        title: Text('${merchant['name']}'),
        actions: [
          IconButton(
            onPressed: editMerchant,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addMovement,
        icon: const Icon(Icons.add),
        label: const Text('إضافة حركة'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'صافي الحساب',
                              style: TextStyle(
                                color: Color(0xFF778A96),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              signedMoney(net),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: positive
                                    ? const Color(0xFF20A77A)
                                    : const Color(0xFFFF1654),
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              net > 0
                                  ? 'إلي عنده'
                                  : net < 0
                                      ? 'عليّ إله'
                                      : 'الحساب صفر',
                              style: const TextStyle(
                                color: Color(0xFF7E8E98),
                              ),
                            ),
                            if ('${merchant['phone'] ?? ''}'.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text('الهاتف: ${merchant['phone']}'),
                            ],
                            if ('${merchant['notes'] ?? ''}'.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text('ملاحظات: ${merchant['notes']}'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'الحركات',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 9),
                      if (rows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(30),
                          child: Center(child: Text('لا توجد حركات')),
                        )
                      else
                        ...rows.map(
                          (row) {
                            final effect =
                                num.tryParse('${row['balance_effect'] ?? 0}') ??
                                    0;
                            final amount =
                                num.tryParse('${row['amount'] ?? 0}') ?? 0;
                            final signed = amount * effect;
                            final pos = signed >= 0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 9),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFE5EDF2),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: pos
                                        ? const Color(0xFFEAF8F2)
                                        : const Color(0xFFFFEAF0),
                                    child: Icon(
                                      pos
                                          ? Icons.add_rounded
                                          : Icons.remove_rounded,
                                      color: pos
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
                                          movementLabel(
                                            '${row['movement_type']}',
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            row['movement_date'],
                                            row['counterparty'],
                                            row['reference'],
                                          ]
                                              .where((x) =>
                                                  x != null &&
                                                  '$x'.trim().isNotEmpty)
                                              .join(' • '),
                                          style: const TextStyle(
                                            color: Color(0xFF7D8E98),
                                            fontSize: 12,
                                          ),
                                        ),
                                        if ('${row['notes'] ?? ''}'
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text('${row['notes']}'),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${signedMoney(signed)} ${row['currency'] ?? 'SYP'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: pos
                                              ? const Color(0xFF20A77A)
                                              : const Color(0xFFFF1654),
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'edit') {
                                            editMovement(row);
                                          } else if (v == 'delete') {
                                            deleteMovement(row);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('تعديل'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('حذف'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
