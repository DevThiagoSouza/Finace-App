import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/tx_tile.dart';

class ExtratoTab extends StatefulWidget {
  const ExtratoTab({super.key});

  @override
  State<ExtratoTab> createState() => _ExtratoTabState();
}

class _ExtratoTabState extends State<ExtratoTab> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);
    final q = _search.text.toLowerCase();
    final list = s.viewTxs
        .where((t) => t.title.toLowerCase().contains(q) || t.category.toLowerCase().contains(q))
        .toList();

    Widget arrow(IconData i, int d) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => s.shiftMonth(d),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(12)),
            child: Icon(i, size: 16, color: p.soft),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            arrow(Icons.chevron_left_rounded, -1),
            Text('${capitalize(monthName(s.month))} ${s.month.year}',
                style: ts(12, w: FontWeight.w700, c: p.text)),
            arrow(Icons.chevron_right_rounded, 1),
          ]),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: ts(12, c: p.text),
          decoration: inputDeco(
            context,
            hint: 'Buscar por descrição ou categoria...',
            prefixIcon: Icon(Icons.search_rounded, size: 16, color: SC.slate400),
          ).copyWith(fillColor: p.surface, enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: p.border))),
        ),
        const SizedBox(height: 12),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Nenhum lançamento encontrado nesta visão.', style: ts(12, c: p.muted))),
          )
        else
          for (final t in list) ...[
            TxTile(tx: t),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
