import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/common.dart';

/// Equivalente ao `prompt()` do app web.
Future<String?> showPromptDialog(BuildContext context, String label, {String? hint, String okLabel = 'Salvar'}) {
  final ctrl = TextEditingController();
  return showAppDialog<String>(context, builder: (ctx) {
    final p = Pal.of(ctx);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: ts(13, w: FontWeight.w700, c: p.text)),
      const SizedBox(height: 12),
      TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: ts(13, c: p.text),
        decoration: inputDeco(ctx, hint: hint),
        onSubmitted: (v) => Navigator.of(ctx).pop(v),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancelar', style: ts(12, w: FontWeight.w700, c: p.muted)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: GradientButton(
            label: okLabel,
            icon: Icons.check_rounded,
            onTap: () => Navigator.of(ctx).pop(ctrl.text),
          ),
        ),
      ]),
    ]);
  });
}
