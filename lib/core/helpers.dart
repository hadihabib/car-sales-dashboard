import 'package:intl/intl.dart';

String money(dynamic value) {
  final n = num.tryParse('${value ?? 0}') ?? 0;
  return NumberFormat('#,##0.##', 'en_US').format(n);
}

String shortDate(dynamic value) {
  if (value == null) return '-';
  final d = DateTime.tryParse(value.toString())?.toLocal();
  if (d == null) return value.toString();
  return DateFormat('dd/MM HH:mm').format(d);
}

dynamic emptyToNull(String value) {
  final v = value.trim();
  return v.isEmpty ? null : v;
}

num? parseNum(String value) {
  final v = value.trim().replaceAll(',', '');
  if (v.isEmpty) return null;
  return num.tryParse(v);
}

int? parseInt(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;
  return int.tryParse(v);
}

String signedMoney(num value) {
  if (value > 0) return '+${money(value)}';
  return money(value);
}

const movementLabels = <String, String>{
  'i_paid_for_him': 'أنا دفعت عنه',
  'he_paid_for_me': 'هو دفع عني',
  'i_collected_for_him': 'أنا قبضت عنه',
  'he_collected_for_me': 'هو قبض عني',
  'invoice_from_him': 'فاتورة أخذتها منه',
  'invoice_to_him': 'فاتورة أعطيته ياها',
  'cash_to_him': 'دفعتله مبلغ',
  'cash_from_him': 'قبضت منه مبلغ',
  'manual_receivable': 'إلي عنده - يدوي',
  'manual_payable': 'عليّ إله - يدوي',
};

const movementEffects = <String, int>{
  'i_paid_for_him': 1,
  'he_paid_for_me': -1,
  'i_collected_for_him': -1,
  'he_collected_for_me': 1,
  'invoice_from_him': -1,
  'invoice_to_him': 1,
  'cash_to_him': 1,
  'cash_from_him': -1,
  'manual_receivable': 1,
  'manual_payable': -1,
};

String movementLabel(String? type) =>
    type == null ? '-' : (movementLabels[type] ?? type);
