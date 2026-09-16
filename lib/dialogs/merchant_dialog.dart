import 'package:flutter/material.dart';
import '../core/helpers.dart';

Future<Map<String, dynamic>?> showMerchantEditor(
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
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController notes;
  late bool active;

  @override
  void initState() {
    super.initState();
    final x = widget.initial ?? {};
    name = TextEditingController(text: '${x['name'] ?? ''}');
    phone = TextEditingController(text: '${x['phone'] ?? ''}');
    notes = TextEditingController(text: '${x['notes'] ?? ''}');
    active = x['is_active'] != false;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
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
            editing ? 'تعديل التاجر' : 'إضافة تاجر',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'اسم التاجر',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف',
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('نشط'),
            value: active,
            onChanged: (v) => setState(() => active = v),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(context, {
                'name': name.text.trim(),
                'phone': emptyToNull(phone.text),
                'notes': emptyToNull(notes.text),
                'is_active': active,
              });
            },
            icon: const Icon(Icons.save_outlined),
            label: Text(editing ? 'حفظ التعديل' : 'إضافة التاجر'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
