import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/helpers.dart';

Future<Map<String, dynamic>?> showLedgerEditor(
  BuildContext context, {
  required int merchantId,
  Map<String, dynamic>? initial,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    builder: (_) => _Editor(
      merchantId: merchantId,
      initial: initial,
    ),
  );
}

class _Editor extends StatefulWidget {
  final int merchantId;
  final Map<String, dynamic>? initial;

  const _Editor({
    required this.merchantId,
    required this.initial,
  });

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late String type;
  late DateTime date;

  late final TextEditingController amount;
  late final TextEditingController currency;
  late final TextEditingController counterparty;
  late final TextEditingController reference;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    final x = widget.initial ?? {};
    type = '${x['movement_type'] ?? 'i_paid_for_him'}';
    date = DateTime.tryParse('${x['movement_date'] ?? ''}') ?? DateTime.now();
    amount = TextEditingController(text: '${x['amount'] ?? ''}');
    currency = TextEditingController(text: '${x['currency'] ?? 'SYP'}');
    counterparty = TextEditingController(text: '${x['counterparty'] ?? ''}');
    reference = TextEditingController(text: '${x['reference'] ?? ''}');
    notes = TextEditingController(text: '${x['notes'] ?? ''}');
  }

  @override
  void dispose() {
    amount.dispose();
    currency.dispose();
    counterparty.dispose();
    reference.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => date = result);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18, 16, 18, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(
            editing ? 'تعديل الحركة' : 'إضافة حركة',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: type,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'نوع الحركة',
              border: OutlineInputBorder(),
            ),
            items: movementLabels.entries
                .map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => type = v ?? type),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: currency,
            decoration: const InputDecoration(
              labelText: 'العملة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'التاريخ',
                border: OutlineInputBorder(),
              ),
              child: Text(DateFormat('yyyy-MM-dd').format(date)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: counterparty,
            decoration: const InputDecoration(
              labelText: 'الطرف المقابل',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: reference,
            decoration: const InputDecoration(
              labelText: 'المرجع / رقم الفاتورة',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'ملاحظات',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              final a = parseNum(amount.text);
              if (a == null || a <= 0) return;

              Navigator.pop(context, {
                'merchant_id': widget.merchantId,
                'movement_type': type,
                'balance_effect': movementEffects[type] ?? 1,
                'amount': a,
                'currency': emptyToNull(currency.text) ?? 'SYP',
                'movement_date': DateFormat('yyyy-MM-dd').format(date),
                'counterparty': emptyToNull(counterparty.text),
                'reference': emptyToNull(reference.text),
                'notes': emptyToNull(notes.text),
              });
            },
            icon: const Icon(Icons.save_outlined),
            label: Text(editing ? 'حفظ التعديل' : 'إضافة الحركة'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
