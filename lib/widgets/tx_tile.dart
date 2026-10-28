import 'package:flutter/material.dart';

import '../core/categories.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';

/// Item de lançamento. Com [onDelete] mostra a lixeira (tela Home); sem ele, o
/// formato compacto do Extrato.
class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx, this.onDelete});
  final Tx tx;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final cat = categoryOf(tx.category);
    final compact = onDelete == null;
    final amountColor = tx.isExpense ? p.redText : p.brandText;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(children: [
        Container(
          width: compact ? 32 : 36,
          height: compact ? 32 : 36,
          decoration: BoxDecoration(color: cat.color.o(.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(cat.icon, size: 14, color: cat.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(tx.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: ts(12, w: FontWeight.w700, c: p.text)),
              ),
              if (tx.pending) ...[
                const SizedBox(width: 6),
                Icon(Icons.cloud_off_rounded, size: 11, color: p.amberText),
              ],
            ]),
            const SizedBox(height: 3),
            if (compact)
              Text('${tx.payer} • ${tx.category} • ${formatFullDate(tx.date)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: ts(10, c: p.muted))
            else
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: p.chip,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: p.chipBorder),
                  ),
                  child: Text(tx.payer, style: ts(9, w: FontWeight.w700, c: p.brandText)),
                ),
                const SizedBox(width: 6),
                Text(formatDayMonth(tx.date), style: ts(10, c: p.muted)),
              ]),
          ]),
        ),
        const SizedBox(width: 8),
        Text('${tx.isExpense ? '-' : '+'} ${formatBRL(tx.amount)}',
            style: ts(12, w: FontWeight.w800, c: amountColor)),
        if (onDelete != null)
          InkWell(
            onTap: onDelete,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.delete_outline_rounded, size: 16, color: p.muted),
            ),
          ),
      ]),
    );
  }
}
