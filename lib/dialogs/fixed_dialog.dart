import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

Future<void> openFixedDialog(BuildContext context) =>
    showAppDialog(context, builder: (_) => const _FixedForm());

class _FixedForm extends StatefulWidget {
  const _FixedForm();

  @override
  State<_FixedForm> createState() => _FixedFormState();
}

class _FixedFormState extends State<_FixedForm> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  late String _payer = context.read<AppState>().activeUser;
  String _paymentMethod = 'debit';
  bool _creditInstallment = false;
  final _installments = TextEditingController(text: '1');
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _installments.dispose();
    super.dispose();
  }

  void _save() {
    final amount = parseMoney(_amount.text);
    if (_title.text.trim().isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'Preencha o nome e um valor maior que zero.');
      return;
    }
    final installments = _creditInstallment ? int.tryParse(_installments.text.trim()) ?? 1 : 1;
    if (_paymentMethod == 'credit' && (installments < 1 || installments > 120)) {
      setState(() => _error = 'Informe entre 1 e 120 parcelas.');
      return;
    }
    context.read<AppState>().addFixed(
          _title.text.trim(),
          amount,
          _payer,
          _paymentMethod,
          installments,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final members = context.watch<AppState>().house!.members;
    final value = members.any((m) => m.name == _payer) ? _payer : members.first.name;

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ModalHeader(icon: Icons.receipt_long_rounded, iconColor: SC.red500, title: 'Nova Despesa Fixa'),
      const SizedBox(height: 16),
      const FieldLabel('Nome da Conta / Compromisso'),
      TextField(
        controller: _title,
        textCapitalization: TextCapitalization.sentences,
        style: ts(12, c: p.text),
        decoration: inputDeco(context, hint: 'Ex: Aluguel, Luz, Internet...'),
      ),
      const SizedBox(height: 12),
      const FieldLabel('Valor Fixo Mensal (R\$)'),
      TextField(
        controller: _amount,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: ts(14, w: FontWeight.w700, c: p.text),
        decoration: inputDeco(context, hint: '0,00'),
      ),
      const SizedBox(height: 12),
      const FieldLabel('Forma de pagamento'),
      DropdownButtonFormField<String>(
        value: _paymentMethod,
        decoration: inputDeco(context),
        dropdownColor: p.surface,
        items: const [
          DropdownMenuItem(value: 'debit', child: Text('Débito')),
          DropdownMenuItem(value: 'pix', child: Text('Pix')),
          DropdownMenuItem(value: 'credit', child: Text('Cartão de crédito')),
          DropdownMenuItem(value: 'cash', child: Text('Dinheiro')),
        ],
        onChanged: (v) => setState(() => _paymentMethod = v ?? 'debit'),
      ),
      if (_paymentMethod == 'credit') ...[
        const SizedBox(height: 12),
        const FieldLabel('Pagamento no crédito'),
        Row(children: [
          Expanded(
            child: RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('À vista', style: ts(11, c: p.text)),
              value: false,
              groupValue: _creditInstallment,
              onChanged: (v) => setState(() => _creditInstallment = v ?? false),
            ),
          ),
          Expanded(
            child: RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text('Parcelado', style: ts(11, c: p.text)),
              value: true,
              groupValue: _creditInstallment,
              onChanged: (v) => setState(() => _creditInstallment = v ?? true),
            ),
          ),
        ]),
        if (_creditInstallment) ...[
          const FieldLabel('Quantidade de parcelas'),
          TextField(
            controller: _installments,
            keyboardType: TextInputType.number,
            style: ts(12, w: FontWeight.w700, c: p.text),
            decoration: inputDeco(context, hint: '1'),
          ),
        ],
      ],
      const SizedBox(height: 12),
      const FieldLabel('Responsável pelo Pagamento'),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: p.inner,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border2),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: p.surface,
            style: ts(12, c: p.text),
            icon: Icon(Icons.expand_more_rounded, size: 18, color: p.muted),
            items: [
              for (final m in members) DropdownMenuItem(value: m.name, child: Text(m.name)),
            ],
            onChanged: (v) => setState(() => _payer = v ?? _payer),
          ),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 10),
        Text(_error!, style: ts(11, w: FontWeight.w600, c: p.redText)),
      ],
      const SizedBox(height: 16),
      GradientButton(
        label: 'Salvar Despesa Fixa',
        icon: Icons.add_rounded,
        color: SC.brand600,
        onTap: _save,
      ),
    ]);
  }
}
