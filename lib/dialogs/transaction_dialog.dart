import 'package:flutter/material.dart';
import '../core/helpers.dart';

Future<Map<String, dynamic>?> showTransactionEditor(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    builder: (_) => _Editor(initial: initial),
  );
}

class _Editor extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _Editor({required this.initial});

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  final formKey = GlobalKey<FormState>();
  late String type;
  late String status;

  late final Map<String, TextEditingController> c;

  @override
  void initState() {
    super.initState();
    final x = widget.initial ?? {};
    type = '${x['transaction_type'] ?? 'sale'}';
    status = '${x['status'] ?? 'confirmed'}';

    c = {
      'customer_name': TextEditingController(text: '${x['customer_name'] ?? ''}'),
      'car_make': TextEditingController(text: '${x['car_make'] ?? ''}'),
      'car_model': TextEditingController(text: '${x['car_model'] ?? ''}'),
      'part_name': TextEditingController(text: '${x['part_name'] ?? ''}'),
      'part_brand': TextEditingController(text: '${x['part_brand'] ?? ''}'),
      'part_condition': TextEditingController(text: '${x['part_condition'] ?? ''}'),
      'quantity': TextEditingController(text: '${x['quantity'] ?? ''}'),
      'unit_price': TextEditingController(text: '${x['unit_price'] ?? ''}'),
      'total_price': TextEditingController(text: '${x['total_price'] ?? ''}'),
      'currency': TextEditingController(text: '${x['currency'] ?? 'SYP'}'),
      'payment_method': TextEditingController(text: '${x['payment_method'] ?? ''}'),
      'amount_paid': TextEditingController(text: '${x['amount_paid'] ?? ''}'),
      'related_sale_id': TextEditingController(text: '${x['related_sale_id'] ?? ''}'),
      'notes': TextEditingController(text: '${x['notes'] ?? ''}'),
      'original_text': TextEditingController(text: '${x['original_text'] ?? ''}'),
    };
  }

  @override
  void dispose() {
    for (final controller in c.values) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget field(
    String key,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c[key],
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: dec(label),
      ),
    );
  }

  void calcTotal() {
    final q = parseNum(c['quantity']!.text);
    final u = parseNum(c['unit_price']!.text);
    if (q != null && u != null) {
      c['total_price']!.text = (q * u).toString();
      setState(() {});
    }
  }

  void save() {
    Navigator.pop(context, {
      'transaction_type': type,
      'customer_name': emptyToNull(c['customer_name']!.text),
      'car_make': emptyToNull(c['car_make']!.text),
      'car_model': emptyToNull(c['car_model']!.text),
      'part_name': emptyToNull(c['part_name']!.text),
      'part_brand': emptyToNull(c['part_brand']!.text),
      'part_condition': emptyToNull(c['part_condition']!.text),
      'quantity': parseNum(c['quantity']!.text),
      'unit_price': parseNum(c['unit_price']!.text),
      'total_price': parseNum(c['total_price']!.text),
      'currency': emptyToNull(c['currency']!.text) ?? 'SYP',
      'payment_method': emptyToNull(c['payment_method']!.text),
      'amount_paid': parseNum(c['amount_paid']!.text),
      'related_sale_id': parseInt(c['related_sale_id']!.text),
      'notes': emptyToNull(c['notes']!.text),
      'original_text': emptyToNull(c['original_text']!.text),
      'status': status,
    });
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18, 12, 18, MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    editing ? 'تعديل العملية' : 'إضافة عملية',
                    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: type,
              decoration: dec('نوع العملية'),
              items: const [
                DropdownMenuItem(value: 'sale', child: Text('بيع')),
                DropdownMenuItem(value: 'return', child: Text('مرتجع')),
              ],
              onChanged: (v) => setState(() => type = v ?? 'sale'),
            ),
            const SizedBox(height: 12),
            field('customer_name', 'اسم الزبون'),
            field('car_make', 'ماركة السيارة'),
            field('car_model', 'موديل السيارة'),
            field('part_name', 'اسم القطعة'),
            field('part_brand', 'ماركة القطعة'),
            field('part_condition', 'حالة القطعة'),
            field('quantity', 'الكمية',
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
            field('unit_price', 'سعر القطعة',
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
            Row(
              children: [
                Expanded(
                  child: field('total_price', 'الإجمالي',
                      keyboard: const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: IconButton.filledTonal(
                    onPressed: calcTotal,
                    icon: const Icon(Icons.calculate_outlined),
                  ),
                ),
              ],
            ),
            field('currency', 'العملة'),
            field('payment_method', 'طريقة الدفع'),
            field('amount_paid', 'المبلغ المدفوع',
                keyboard: const TextInputType.numberWithOptions(decimal: true)),
            field('related_sale_id', 'رقم البيعة الأصلية للمرتجع',
                keyboard: TextInputType.number),
            field('notes', 'ملاحظات', maxLines: 3),
            field('original_text', 'النص الأصلي', maxLines: 3),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: dec('الحالة'),
              items: const [
                DropdownMenuItem(value: 'confirmed', child: Text('مؤكدة')),
                DropdownMenuItem(value: 'cancelled', child: Text('ملغاة')),
              ],
              onChanged: (v) => setState(() => status = v ?? 'confirmed'),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: save,
              icon: const Icon(Icons.save_outlined),
              label: Text(editing ? 'حفظ التعديل' : 'إضافة العملية'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
