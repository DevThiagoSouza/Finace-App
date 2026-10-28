import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../dialogs/household_dialog.dart';
import '../widgets/common.dart';

/// Aparece quando o aparelho ainda não está conectado a nenhuma casa.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: gradBrand,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: SC.brand500.o(.3), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.home_work_rounded, size: 34, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text('Stoco Family', style: ts(26, w: FontWeight.w800, c: p.strong, ls: -.5)),
                const SizedBox(height: 8),
                Text('Gestão financeira individual e a dois.\nCrie o espaço da sua família ou conecte-se com um código.',
                    textAlign: TextAlign.center, style: ts(13, c: p.muted, h: 1.5)),
                const SizedBox(height: 28),
                GradientButton(
                  label: 'Criar / Conectar a um Código',
                  icon: Icons.add_rounded,
                  onTap: () => openNewHouseholdDialog(context),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
