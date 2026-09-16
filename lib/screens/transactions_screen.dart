import 'package:flutter/material.dart';

import '../core/database_service.dart';
import '../core/helpers.dart';
import '../dialogs/transaction_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  final DatabaseService db;

  const TransactionsScreen({
    super.key,
    required this.db,
  });

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  final search = TextEditingController();

  bool loading = true;
  String? error;
  String filter = 'all';
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    search.addListener(() => setState(() {}));
    load();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await widget.db.getTransactions();
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

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();

    return rows.where((row) {
      if (filter != 'all' && '${row['transaction_type']}' != filter) {
        return false;
      }

      if (q.isEmpty) return true;

      final text = [
        row['id'],
        row['customer_name'],
        row['car_make'],
        row['car_model'],
        row['part_name'],
        row['part_brand'],
        row['notes'],
        row['original_text'],
      ].join(' ').toLowerCase();

      return text.contains(q);
    }).toList();
  }

  Future<void> add() async {
    final values = await showTransactionEditor(context);
    if (values == null) return;

    try {
      await widget.db.addTransaction(values);
      await load();
    } catch (e) {
      showError(e);
    }
  }

  Future<void> edit(Map<String, dynamic> row) async {
    final values = await showTransactionEditor(
      context,
      initial: row,
    );
    if (values == null) return;

    try {
      await widget.db.updateTransaction(
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
        title: const Text('حذف العملية؟'),
        content: Text('سيتم حذف العملية رقم ${row['id']} نهائياً.'),
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
      await widget.db.deleteTransaction(int.parse('${row['id']}'));
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

  void details(Map<String, dynamic> row) {
    final items = <String, dynamic>{
      'رقم العملية': row['id'],
      'النوع': row['transaction_type'] == 'return' ? 'مرتجع' : 'بيع',
      'اسم الزبون': row['customer_name'],
      'ماركة السيارة': row['car_make'],
      'موديل السيارة': row['car_model'],
      'اسم القطعة': row['part_name'],
      'ماركة القطعة': row['part_brand'],
      'حالة القطعة': row['part_condition'],
      'الكمية': row['quantity'],
      'سعر القطعة': row['unit_price'],
      'الإجمالي': row['total_price'],
      'العملة': row['currency'],
      'طريقة الدفع': row['payment_method'],
      'المبلغ المدفوع': row['amount_paid'],
      'رقم البيعة الأصلية': row['related_sale_id'],
      'الملاحظات': row['notes'],
      'النص الأصلي': row['original_text'],
      'الحالة': row['status'],
      'تاريخ الإنشاء': row['created_at'],
      'آخر تعديل': row['updated_at'],
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'تفاصيل العملية',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    Navigator.pop(context);
                    edit(row);
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          color: Color(0xFF72838E),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        '${e.value ?? '-'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add),
        label: const Text('عملية جديدة'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'المبيعات والمرتجعات',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: search,
                decoration: const InputDecoration(
                  hintText: 'بحث بالزبون، القطعة، السيارة...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('الكل'),
                    selected: filter == 'all',
                    onSelected: (_) => setState(() => filter = 'all'),
                  ),
                  const SizedBox(width: 7),
                  ChoiceChip(
                    label: const Text('بيع'),
                    selected: filter == 'sale',
                    onSelected: (_) => setState(() => filter = 'sale'),
                  ),
                  const SizedBox(width: 7),
                  ChoiceChip(
                    label: const Text('مرتجع'),
                    selected: filter == 'return',
                    onSelected: (_) => setState(() => filter = 'return'),
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
                          child: data.isEmpty
                              ? ListView(
                                  children: const [
                                    SizedBox(height: 120),
                                    Center(child: Text('لا توجد نتائج')),
                                  ],
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    18, 8, 18, 100,
                                  ),
                                  itemCount: data.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (_, i) {
                                    final row = data[i];
                                    final isReturn =
                                        row['transaction_type'] == 'return';

                                    return Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      child: InkWell(
                                        onTap: () => details(row),
                                        borderRadius: BorderRadius.circular(18),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                child: Icon(
                                                  isReturn
                                                      ? Icons.keyboard_return
                                                      : Icons.shopping_bag_outlined,
                                                ),
                                              ),
                                              const SizedBox(width: 11),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${row['customer_name'] ?? 'بدون اسم'}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      '${row['part_name'] ?? 'قطعة غير محددة'}',
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      '#${row['id']} • ${shortDate(row['created_at'])}',
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFFA0ADB5),
                                                        fontSize: 11,
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
                                                    '${money(row['total_price'])} ${row['currency'] ?? 'SYP'}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: isReturn
                                                          ? const Color(
                                                              0xFFFF1654)
                                                          : const Color(
                                                              0xFF173B53),
                                                    ),
                                                  ),
                                                  PopupMenuButton<String>(
                                                    onSelected: (v) {
                                                      if (v == 'edit') {
                                                        edit(row);
                                                      } else if (v ==
                                                          'delete') {
                                                        delete(row);
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
