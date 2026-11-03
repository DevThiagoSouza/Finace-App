import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/categories.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

Future<void> openTransactionSheet(BuildContext context) {
  final p = Pal.of(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.surface,
    barrierColor: p.overlay,
    constraints: const BoxConstraints(maxWidth: 448),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: p.border2),
    ),
    builder: (_) => const _TransactionForm(),
  );
}

class _TransactionForm extends StatefulWidget {
  const _TransactionForm();

  @override
  State<_TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<_TransactionForm> {
  final _amount = TextEditingController();
  final _desc = TextEditingController();
  String _type = 'expense';
  String _category = 'Supermercado';
  late String _payer = context.read<AppState>().activeUser;
  DateTime _date = DateTime.now();
  String _paymentMethod = 'debit';
  bool _creditInstallment = false;
  final _installments = TextEditingController(text: '1');
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _desc.dispose();
    _installments.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (d != null) setState(() => _date = d);
  }

  void _save() {
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Informe um valor maior que zero.');
      return;
    }
    if (_desc.text.trim().isEmpty) {
      setState(() => _error = 'Informe a descrição.');
      return;
    }
    final installments = _creditInstallment ? int.tryParse(_installments.text.trim()) ?? 1 : 1;
    if (_paymentMethod == 'credit' && (installments < 1 || installments > 120)) {
      setState(() => _error = 'Informe entre 1 e 120 parcelas.');
      return;
    }
    context.read<AppState>().addTransaction(
          title: _desc.text.trim(),
          amount: amount,
          type: _type,
          category: _category,
          payer: _payer,
          date: isoDate(_date),
          paymentMethod: _paymentMethod,
          installments: installments,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final members = context.watch<AppState>().house!.members;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          const ModalHeader(icon: Icons.add_circle_rounded, iconColor: SC.brand500, title: 'Novo Lançamento Variável'),
          const SizedBox(height: 16),

          // Saída / Entrada
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: p.inner,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border2),
            ),
            child: Row(children: [
              Expanded(child: _TypeButton(
                label: '🔴 Saída', icon: Icons.arrow_circle_down_rounded,
                color: SC.red500, textColor: p.redText, active: _type == 'expense',
                onTap: () => setState(() => _type = 'expense'),
              )),
              const SizedBox(width: 8),
              Expanded(child: _TypeButton(
                label: '🟢 Entrada', icon: Icons.arrow_circle_up_rounded,
                color: SC.brand500, textColor: p.brandText, active: _type == 'income',
                onTap: () => setState(() => _type = 'income'),
              )),
            ]),
          ),
          const SizedBox(height: 14),

          // Valor
          const FieldLabel('Valor'),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: ts(24, w: FontWeight.w800, c: p.text),
            decoration: inputDeco(
              context,
              hint: '0,00',
              radius: 16,
              pad: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Text('R\$', style: ts(18, w: FontWeight.w700, c: SC.slate400)),
              ),
            ).copyWith(prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0)),
          ),
          const SizedBox(height: 14),

          const FieldLabel('Forma de pagamento'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: p.inner,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _paymentMethod,
                isExpanded: true,
                dropdownColor: p.surface,
                style: ts(12, c: p.text),
                items: const [
                  DropdownMenuItem(value: 'debit', child: Text('Débito')),
                  DropdownMenuItem(value: 'pix', child: Text('Pix')),
                  DropdownMenuItem(value: 'credit', child: Text('Cartão de crédito')),
                  DropdownMenuItem(value: 'cash', child: Text('Dinheiro')),
                ],
                onChanged: (v) => setState(() {
                  _paymentMethod = v ?? 'debit';
                  if (_paymentMethod != 'credit') _creditInstallment = false;
                }),
              ),
            ),
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
          const SizedBox(height: 14),

          // Categoria
          const FieldLabel('Categoria'),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.15,
            children: [
              for (final c in kCategories)
                _CategoryChip(cat: c, selected: c.id == _category, onTap: () => setState(() => _category = c.id)),
            ],
          ),
          const SizedBox(height: 14),

          // Pagador
          const FieldLabel('Quem Pagou?'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 4,
            children: [
              for (final m in members)
                _PayerButton(
                  name: m.name,
                  color: kMemberColors[m.colorIndex % kMemberColors.length],
                  selected: _payer == m.name,
                  onTap: () => setState(() => _payer = m.name),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Descrição e Data
          const FieldLabel('Descrição'),
          TextField(
            controller: _desc,
            textCapitalization: TextCapitalization.sentences,
            style: ts(12, c: p.text),
            decoration: inputDeco(context, hint: 'Ex: Mercado, Lanche...'),
          ),
          const SizedBox(height: 12),
          const FieldLabel('Data'),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: inputDeco(context),
              child: Row(children: [
                Expanded(child: Text(formatFullDate(isoDate(_date)), style: ts(12, c: p.text))),
                Icon(Icons.calendar_today_rounded, size: 14, color: p.muted),
              ]),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: ts(11, w: FontWeight.w600, c: p.redText)),
          ],
          const SizedBox(height: 16),
          GradientButton(label: 'Salvar Lançamento', icon: Icons.check_rounded, onTap: _save),
        ]),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  const _TypeButton({
    required this.label, required this.icon, required this.color,
    required this.textColor, required this.active, required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Material(
      color: active ? color.o(.2) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? color.o(.3) : Colors.transparent),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 14, color: active ? textColor : p.muted),
            const SizedBox(width: 6),
            Text(label, style: ts(12, w: FontWeight.w700, c: active ? textColor : p.muted)),
          ]),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.cat, required this.selected, required this.onTap});
  final Category cat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final color = selected ? p.brandText : p.soft;
    return Material(
      color: selected ? SC.brand500.o(.2) : p.inner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? SC.brand500 : p.border2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(cat.icon, size: 16, color: color),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(cat.label,
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                style: ts(10, w: selected ? FontWeight.w700 : FontWeight.w400, c: color)),
          ),
        ]),
      ),
    );
  }
}

class _PayerButton extends StatelessWidget {
  const _PayerButton({required this.name, required this.color, required this.selected, required this.onTap});
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Material(
      color: selected ? SC.brand500.o(.2) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? SC.brand500 : p.border2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ColorDot(color, size: 8),
          const SizedBox(width: 6),
          Flexible(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: ts(12, w: FontWeight.w700, c: selected ? p.brandText : p.soft)),
          ),
        ]),
      ),
    );
  }
}
