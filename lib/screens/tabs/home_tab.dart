import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/categories.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/tx_tile.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);
    final h = s.house!;
    final t = s.viewTotals;
    final all = s.viewMember == 'all';
    final stats = s.memberStats;
    final recent = s.viewTxs.take(6).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _Hero(totals: t, all: all, member: s.viewMember, month: s.month),
        const SizedBox(height: 16),
        _ChartCard(
            transactions: s.txs, viewMember: s.viewMember, month: s.month),
        if (all) ...[
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.balance_rounded, size: 14, color: SC.brand500),
            const SizedBox(width: 6),
            Text('RESUMO SEPARADO POR PESSOA',
                style: ts(12, w: FontWeight.w700, c: p.muted, ls: .8)),
          ]),
          const SizedBox(height: 10),
          for (final m in h.members) ...[
            _MemberCard(member: m, stats: stats[m.name] ?? MemberStats()),
            const SizedBox(height: 10),
          ],
        ],
        const SizedBox(height: 6),
        Text(
            all
                ? 'GASTOS VARIÁVEIS RECENTES (CASAL)'
                : 'GASTOS VARIÁVEIS (${s.viewMember.toUpperCase()})',
            style: ts(12, w: FontWeight.w700, c: p.muted, ls: .8)),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: Text('Nenhum gasto variável nesta visão.',
                    style: ts(12, c: p.muted))),
          )
        else
          for (final tx in recent) ...[
            TxTile(tx: tx, onDelete: () => s.deleteTransaction(tx.id)),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.transactions,
      required this.viewMember,
      required this.month});
  final List<Tx> transactions;
  final String viewMember;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final months =
        List.generate(6, (i) => DateTime(month.year, month.month - 5 + i));
    final values = [
      for (final item in months)
        (income: _total(item, false), expense: _total(item, true)),
    ];
    final maxValue = values.fold<double>(1, (max, v) {
      final current = v.income > v.expense ? v.income : v.expense;
      return max > current ? max : current;
    });

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('EVOLUÇÃO FINANCEIRA',
              style: ts(11, w: FontWeight.w700, c: p.muted, ls: .8)),
          Row(children: [
            _Legend(color: p.redText, label: 'Saídas'),
            const SizedBox(width: 10),
            _Legend(color: p.brandText, label: 'Entradas'),
          ]),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < months.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Bar(
                                    value: values[i].expense,
                                    maxValue: maxValue,
                                    color: p.redText),
                                const SizedBox(width: 3),
                                _Bar(
                                    value: values[i].income,
                                    maxValue: maxValue,
                                    color: p.brandText),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(monthName(months[i]).substring(0, 3),
                              style: ts(9, c: p.muted)),
                        ]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('ONDE MAIS GASTOU NESTE MÊS',
            style: ts(11, w: FontWeight.w700, c: p.muted, ls: .8)),
        const SizedBox(height: 10),
        if (_categoryTotals.isEmpty)
          Text('Ainda não há gastos categorizados neste mês.',
              style: ts(11, c: p.muted))
        else
          for (final item in _categoryTotals.take(5)) ...[
            _CategoryBar(
              label: categoryOf(item.key).label,
              value: item.value,
              maxValue: _categoryTotals.first.value,
              color: categoryOf(item.key).color,
            ),
            const SizedBox(height: 8),
          ],
      ]),
    );
  }

  List<MapEntry<String, double>> get _categoryTotals {
    final key = monthKey(month);
    final totals = <String, double>{};
    for (final tx in transactions) {
      if (tx.date.startsWith(key) &&
          tx.isExpense &&
          (viewMember == 'all' || tx.payer == viewMember)) {
        totals[tx.category] = (totals[tx.category] ?? 0) + tx.amount;
      }
    }
    return totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  double _total(DateTime target, bool expense) {
    final key = monthKey(target);
    return transactions
        .where((t) =>
            t.date.startsWith(key) &&
            t.isExpense == expense &&
            (viewMember == 'all' || t.payer == viewMember))
        .fold(0, (sum, t) => sum + t.amount);
  }
}

class _Bar extends StatelessWidget {
  const _Bar(
      {required this.value, required this.maxValue, required this.color});
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 116.0;
    final height =
        value == 0 ? 2.0 : chartHeight * (value / maxValue).clamp(.02, 1);

    return SizedBox(
      width: 10,
      height: chartHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 10,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: ts(9, c: Pal.of(context).muted)),
      ]);
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });
  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: ts(11, w: FontWeight.w600, c: p.text)),
        Text(formatBRL(value), style: ts(10, w: FontWeight.w700, c: color)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          minHeight: 7,
          value: (value / maxValue).clamp(0, 1),
          color: color,
          backgroundColor: p.chip,
        ),
      ),
    ]);
  }
}

class _Hero extends StatelessWidget {
  const _Hero(
      {required this.totals,
      required this.all,
      required this.member,
      required this.month});
  final MemberStats totals;
  final bool all;
  final String member;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final tagColor = all ? SC.brand500 : SC.indigo500;
    final tagText = all ? p.brandText : p.indigoText;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.o(.25),
              blurRadius: 24,
              offset: const Offset(0, 10))
        ],
      ),
      child: Stack(children: [
        Positioned(
          right: -32,
          bottom: -32,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                  color: SC.brand500.o(.12), shape: BoxShape.circle),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                child: Text(
                    'SOBRA PROJETADA • ${monthName(month).toUpperCase()}',
                    overflow: TextOverflow.ellipsis,
                    style: ts(10, w: FontWeight.w700, c: p.muted, ls: .8)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.o(.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tagColor.o(.2)),
                ),
                child: Text(all ? 'Visão Casal (Geral)' : 'Somente: $member',
                    style: ts(10, w: FontWeight.w700, c: tagText)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('Sobra Livre Disponível:',
                style: ts(11, w: FontWeight.w500, c: p.muted)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatBRL(totals.leftover),
                  style: ts(36, w: FontWeight.w900, c: p.brandText, ls: -.5)),
            ),
            const SizedBox(height: 2),
            Text(
              'Salário (${formatBRL(totals.salary)}) - Fixas (${formatBRL(totals.fixed)}) - Variável (${formatBRL(totals.variable)})',
              style: ts(10, c: p.muted),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: p.border))),
              child: Row(children: [
                Expanded(
                    child: _Mini('Salário / Renda', formatBRL(totals.salary),
                        p.brandText)),
                const SizedBox(width: 6),
                Expanded(
                    child: _Mini(
                        'Despesas Fixas', formatBRL(totals.fixed), p.redText)),
                const SizedBox(width: 6),
                Expanded(
                    child: _Mini('Sobra Inicial',
                        formatBRL(totals.surplusInitial), p.indigoText)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: p.dark ? SC.slate950.o(.6) : SC.slate200.o(.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (p.dark ? SC.slate800 : SC.slate300).o(.6)),
      ),
      child: Column(children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label.toUpperCase(),
              style: ts(9, w: FontWeight.w600, c: p.muted)),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: ts(12, w: FontWeight.w700, c: color)),
        ),
      ]),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.stats});
  final Member member;
  final MemberStats stats;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.read<AppState>();
    final color = kMemberColors[member.colorIndex % kMemberColors.length];

    Widget row(String l, String v, Color c) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l, style: ts(11, c: p.muted)),
            Text(v, style: ts(11, w: FontWeight.w700, c: c)),
          ]),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border2),
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: p.border2))),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              ColorDot(color, size: 10),
              const SizedBox(width: 6),
              Text(member.name, style: ts(12, w: FontWeight.w800, c: p.text)),
            ]),
            Text('Sobra: ${formatBRL(stats.leftover)}',
                style: ts(10,
                    w: FontWeight.w800,
                    c: stats.leftover >= 0 ? p.brandText : SC.red500)),
          ]),
        ),
        const SizedBox(height: 8),
        row('Salário:', formatBRL(stats.salary), p.brandText),
        row('Contas Fixas:', '- ${formatBRL(stats.fixed)}', p.redText),
        row('Gastos Variáveis:', '- ${formatBRL(stats.variable)}', p.amberText),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: p.chip,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => s.setViewMember(member.name),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Center(
                  child: Text('Ver Detalhes de ${member.name.split(' ').first}',
                      style: ts(10, w: FontWeight.w700, c: p.soft)),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
