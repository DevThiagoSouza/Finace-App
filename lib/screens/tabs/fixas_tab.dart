import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../dialogs/fixed_dialog.dart';
import '../../dialogs/salary_dialog.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class FixasTab extends StatelessWidget {
  const FixasTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);
    final all = s.viewMember == 'all';
    final t = s.viewTotals;
    final fixed = s.viewFixed;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // ----- Salários -----
        AppCard(
          child: Column(children: [
            _SectionHeader(
              icon: Icons.account_balance_wallet_rounded,
              iconColor: SC.brand500,
              title: 'Salários / Renda por Pessoa',
              subtitle: 'Renda bruta mensal de cada membro',
              action: SmallTonalButton(
                label: 'Editar',
                icon: Icons.edit_rounded,
                color: SC.brand500,
                textColor: p.brandText,
                onTap: () => openSalaryDialog(context),
              ),
            ),
            const SizedBox(height: 12),
            for (final m in s.viewMembers) ...[
              InnerBox(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    ColorDot(kMemberColors[m.colorIndex % kMemberColors.length]),
                    const SizedBox(width: 8),
                    Text(m.name, style: ts(12, w: FontWeight.w700, c: p.text)),
                  ]),
                  Text(formatBRL(m.salary), style: ts(12, w: FontWeight.w800, c: p.brandText)),
                ]),
              ),
              const SizedBox(height: 8),
            ],
            InnerBox(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                  child: Text(all ? 'Renda Familiar Total Combinada:' : 'Salário de ${s.viewMember}:',
                      style: ts(12, w: FontWeight.w700, c: p.muted)),
                ),
                Text(formatBRL(t.salary), style: ts(14, w: FontWeight.w800, c: p.brandText)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ----- Despesas fixas -----
        AppCard(
          child: Column(children: [
            _SectionHeader(
              icon: Icons.receipt_long_rounded,
              iconColor: SC.red500,
              title: 'Despesas Fixas Separadas',
              subtitle: 'Contas atribuídas a cada pessoa',
              action: SmallTonalButton(
                label: 'Nova Fixa',
                icon: Icons.add_rounded,
                color: SC.brand500,
                textColor: p.brandText,
                onTap: () => openFixedDialog(context),
              ),
            ),
            const SizedBox(height: 12),
            if (fixed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Nenhuma despesa fixa cadastrada para esta visão.',
                    textAlign: TextAlign.center, style: ts(12, c: SC.slate400)),
              )
            else
              for (final f in fixed) ...[
                InnerBox(
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.title, style: ts(12, w: FontWeight.w700, c: p.text)),
                        const SizedBox(height: 2),
                        Text.rich(TextSpan(style: ts(10, c: p.muted), children: [
                          const TextSpan(text: 'Pagador: '),
                          TextSpan(text: f.payer, style: ts(10, w: FontWeight.w700, c: p.brandText)),
                        ])),
                      ]),
                    ),
                    Text(formatBRL(f.amount), style: ts(12, w: FontWeight.w700, c: p.redText)),
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => s.deleteFixed(f.id),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline_rounded, size: 16, color: p.muted),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
            InnerBox(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                  child: Text(all ? 'Total Despesas Fixas da Casa:' : 'Despesas Fixas de ${s.viewMember}:',
                      style: ts(12, w: FontWeight.w700, c: p.muted)),
                ),
                Text(formatBRL(t.fixed), style: ts(14, w: FontWeight.w800, c: p.redText)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ----- Explicativo -----
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [SC.indigo700.o(.3), SC.brand700.o(.3)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SC.indigo500.o(.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.info_outline_rounded, size: 14, color: p.dark ? SC.indigo300 : SC.indigo700),
              const SizedBox(width: 6),
              Text('Como é calculada a sobra individual?',
                  style: ts(12, w: FontWeight.w700, c: p.dark ? SC.indigo300 : SC.indigo700)),
            ]),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(style: ts(11, c: p.soft, h: 1.5), children: [
                const TextSpan(text: 'Cada membro tem seu próprio cálculo: '),
                TextSpan(
                    text: '(Salário Individual) - (Despesas Fixas Atribuídas) - (Gastos Variáveis do Membro)',
                    style: ts(11, w: FontWeight.w700, c: p.soft, h: 1.5)),
                const TextSpan(text: '. A visão '),
                TextSpan(text: 'Casal (Geral)', style: ts(11, w: FontWeight.w700, c: p.soft, h: 1.5)),
                const TextSpan(text: ' soma os resultados dos dois para dar a visão geral da família.'),
              ]),
            ),
          ]),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.action,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: ts(11, w: FontWeight.w700, c: p.soft, ls: .6)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(subtitle, style: ts(10, c: p.muted)),
          ]),
        ),
        const SizedBox(width: 8),
        action,
      ]),
    );
  }
}
