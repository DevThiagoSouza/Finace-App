import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  const Member({
    required this.name,
    required this.salary,
    required this.colorIndex,
    this.incomePaymentMethod = 'pix',
  });
  final String name;
  final double salary;
  final int colorIndex;
  final String incomePaymentMethod;

  Member copyWith({double? salary, String? incomePaymentMethod}) => Member(
        name: name,
        salary: salary ?? this.salary,
        colorIndex: colorIndex,
        incomePaymentMethod: incomePaymentMethod ?? this.incomePaymentMethod,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'salary': salary,
        'colorIndex': colorIndex,
        'incomePaymentMethod': incomePaymentMethod,
      };

  factory Member.fromMap(Map<String, dynamic> m) => Member(
        name: (m['name'] ?? '') as String,
        salary: ((m['salary'] ?? 0) as num).toDouble(),
        colorIndex: ((m['colorIndex'] ?? 0) as num).toInt(),
        incomePaymentMethod: (m['incomePaymentMethod'] ?? 'pix') as String,
      );
}

class Household {
  const Household({required this.code, required this.name, required this.members});
  final String code;
  final String name;
  final List<Member> members;

  Map<String, dynamic> toMap() => {
        'name': name,
        'code': code,
        'members': members.map((m) => m.toMap()).toList(),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

  factory Household.fromDoc(String id, Map<String, dynamic> d) => Household(
        code: id,
        name: (d['name'] ?? '') as String,
        members: ((d['members'] ?? const []) as List)
            .map((e) => Member.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

class FixedExpense {
  const FixedExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.payer,
    this.paymentMethod = 'debit',
  });
  final String id;
  final String title;
  final double amount;
  final String payer;
  final String paymentMethod;

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'payer': payer,
        'paymentMethod': paymentMethod,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

  factory FixedExpense.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return FixedExpense(
      id: d.id,
      title: (m['title'] ?? '') as String,
      amount: ((m['amount'] ?? 0) as num).toDouble(),
      payer: (m['payer'] ?? '') as String,
      paymentMethod: (m['paymentMethod'] ?? 'debit') as String,
    );
  }
}

class Tx {
  const Tx({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.payer,
    required this.date,
    required this.createdAt,
    this.paymentMethod = 'debit',
    this.installmentNumber = 1,
    this.installmentTotal = 1,
    this.recurringId,
    this.pending = false,
  });
  final String id;
  final String title;
  final double amount;
  final String type; // 'expense' | 'income'
  final String category;
  final String payer;
  final String date; // yyyy-MM-dd
  final int createdAt;
  final String paymentMethod;
  final int installmentNumber;
  final int installmentTotal;
  final String? recurringId;
  final bool pending;

  bool get isExpense => type == 'expense';

  Map<String, dynamic> toMap() => {
        'title': title,
        'amount': amount,
        'type': type,
        'category': category,
        'payer': payer,
        'date': date,
        'createdAt': createdAt,
        'paymentMethod': paymentMethod,
        'installmentNumber': installmentNumber,
        'installmentTotal': installmentTotal,
        if (recurringId != null) 'recurringId': recurringId,
      };

  factory Tx.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return Tx(
      id: d.id,
      title: (m['title'] ?? '') as String,
      amount: ((m['amount'] ?? 0) as num).toDouble(),
      type: (m['type'] ?? 'expense') as String,
      category: (m['category'] ?? 'Outros') as String,
      payer: (m['payer'] ?? '') as String,
      date: (m['date'] ?? '') as String,
      createdAt: ((m['createdAt'] ?? 0) as num).toInt(),
      paymentMethod: (m['paymentMethod'] ?? 'debit') as String,
      installmentNumber: ((m['installmentNumber'] ?? 1) as num).toInt(),
      installmentTotal: ((m['installmentTotal'] ?? 1) as num).toInt(),
      recurringId: m['recurringId'] as String?,
      pending: d.metadata.hasPendingWrites,
    );
  }
}

/// Totais de uma pessoa (ou do casal, somados).
class MemberStats {
  MemberStats({this.salary = 0, this.fixed = 0, this.variable = 0});
  double salary;
  double fixed;
  double variable;

  double get surplusInitial => salary - fixed;
  double get leftover => surplusInitial - variable;
}

/// Resumo de uma casa para a tela "Alternar Código".
class HouseSummary {
  const HouseSummary({required this.code, required this.name, required this.members, this.txCount});
  final String code;
  final String name;
  final List<String> members;
  final int? txCount;
}
