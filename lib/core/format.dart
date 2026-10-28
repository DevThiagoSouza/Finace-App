import 'package:intl/intl.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$', decimalDigits: 2);

String formatBRL(num v) => _brl.format(v).replaceAll('\u00A0', ' ');

/// 'yyyy-MM-dd' -> 'dd/MM'
String formatDayMonth(String d) {
  final p = d.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}' : d;
}

/// 'yyyy-MM-dd' -> 'dd/MM/yyyy'
String formatFullDate(String d) {
  final p = d.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : d;
}

String isoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);

String monthName(DateTime d) => DateFormat('MMMM', 'pt_BR').format(d);

String capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Aceita "1234,56" ou "1234.56".
double? parseMoney(String s) {
  final t = s.trim().replaceAll(r'R$', '').replaceAll(' ', '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    return double.tryParse(t.replaceAll('.', '').replaceAll(',', '.'));
  }
  return double.tryParse(t);
}
