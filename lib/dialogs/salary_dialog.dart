import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

Future<void> openSalaryDialog(BuildContext context) =>
    showAppDialog(context, builder: (_) => const _SalaryForm());

class _SalaryForm extends StatefulWidget {
  const _SalaryForm();

  @override
  State<_SalaryForm> createState() => _SalaryFormState();
}

class _SalaryFormState extends State<_SalaryForm> {
  late final Map<String, TextEditingController> _c = {
    for (final m in context.read<AppState>().house!.members)
      m.name: TextEditingController(text: m.salary == 0 ? '' : m.salary.toStringAsFixed(2).replaceAll('.', ',')),
  };

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final out = <String, double>{
      for (final e in _c.entries) e.key: parseMoney(e.value.text) ?? 0,
    };
    context.read<AppState>().saveSalaries(out);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ModalHeader(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: SC.brand500,
        title: 'Ajustar Salários Individuais',
      ),
      const SizedBox(height: 16),
      for (final e in _c.entries) ...[
        FieldLabel('Salário / Renda de ${e.key}'),
        TextField(
          controller: e.value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: ts(14, w: FontWeight.w700, c: p.text),
          decoration: inputDeco(
            context,
            hint: '0,00',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: Text('R\$', style: ts(12, w: FontWeight.w700, c: SC.slate400)),
            ),
          ).copyWith(prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0)),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 4),
      GradientButton(
        label: 'Atualizar Salários',
        icon: Icons.save_rounded,
        color: SC.brand600,
        onTap: _save,
      ),
    ]);
  }
}
