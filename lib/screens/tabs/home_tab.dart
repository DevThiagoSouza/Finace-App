import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
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
        Text(all ? 'GASTOS VARIÁVEIS RECENTES (CASAL)' : 'GASTOS VARIÁVEIS (${s.viewMember.toUpperCase()})',
            style: ts(12, w: FontWeight.w700, c: p.muted, ls: .8)),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Nenhum gasto variável nesta visão.', style: ts(12, c: p.muted))),
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

class _Hero extends StatelessWidget {
  const _Hero({required this.totals, required this.all, required this.member, required this.month});
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
        boxShadow: [BoxShadow(color: Colors.black.o(.25), blurRadius: 24, offset: const Offset(0, 10))],
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
              decoration: BoxDecoration(color: SC.brand500.o(.12), shape: BoxShape.circle),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                child: Text('SOBRA PROJETADA • ${monthName(month).toUpperCase()}',
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
            Text('Sobra Livre Disponível:', style: ts(11, w: FontWeight.w500, c: p.muted)),
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
              decoration: BoxDecoration(border: Border(top: BorderSide(color: p.border))),
              child: Row(children: [
                Expanded(child: _Mini('Salário / Renda', formatBRL(totals.salary), p.brandText)),
                const SizedBox(width: 6),
                Expanded(child: _Mini('Despesas Fixas', formatBRL(totals.fixed), p.redText)),
                const SizedBox(width: 6),
                Expanded(child: _Mini('Sobra Inicial', formatBRL(totals.surplusInitial), p.indigoText)),
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
          child: Text(label.toUpperCase(), style: ts(9, w: FontWeight.w600, c: p.muted)),
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
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border2))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              ColorDot(color, size: 10),
              const SizedBox(width: 6),
              Text(member.name, style: ts(12, w: FontWeight.w800, c: p.text)),
            ]),
            Text('Sobra: ${formatBRL(stats.leftover)}',
                style: ts(10, w: FontWeight.w800, c: stats.leftover >= 0 ? p.brandText : SC.red500)),
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
