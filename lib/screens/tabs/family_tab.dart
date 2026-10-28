import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../dialogs/household_dialog.dart';
import '../../dialogs/prompt_dialog.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/toast.dart';

class FamilyTab extends StatelessWidget {
  const FamilyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);
    final h = s.house!;

    Widget title(String t) => Text(t.toUpperCase(), style: ts(12, w: FontWeight.w700, c: p.muted, ls: .8));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // ----- Dono do celular -----
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            title('Dono deste Celular'),
            const SizedBox(height: 6),
            Text('Selecione quem está segurando este aparelho no dia a dia.', style: ts(11, c: p.muted)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.6,
              children: [
                for (final m in h.members)
                  _UserButton(
                    name: m.name,
                    active: s.activeUser == m.name,
                    onTap: () => s.setActiveUser(m.name),
                  ),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ----- Membros -----
        AppCard(
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              title('Membros da Casa'),
              SmallTonalButton(
                label: 'Adicionar',
                icon: Icons.add_rounded,
                color: SC.brand500,
                textColor: p.brandText,
                onTap: () async {
                  final name = await showPromptDialog(context, 'Nome do novo membro da casa/família:');
                  if (name != null && name.trim().isNotEmpty) s.addMember(name);
                },
              ),
            ]),
            const SizedBox(height: 12),
            for (final m in h.members) ...[
              InnerBox(
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    ColorDot(kMemberColors[m.colorIndex % kMemberColors.length]),
                    const SizedBox(width: 8),
                    Text(m.name, style: ts(12, w: FontWeight.w700, c: p.text)),
                  ]),
                  if (h.members.length > 1)
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => s.removeMember(m.name),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded, size: 16, color: p.muted),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
          ]),
        ),
        const SizedBox(height: 16),

        // ----- Código da casa -----
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            title('Código da Casa & Isolamento'),
            const SizedBox(height: 12),
            InnerBox(
              padding: const EdgeInsets.all(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Seu Código Familiar de Sincronização', style: ts(10, c: p.muted)),
                  const SizedBox(height: 2),
                  Text(h.code, style: ts(14, w: FontWeight.w800, c: p.brandText, ls: 1)),
                ]),
                Material(
                  color: p.dark ? SC.slate800 : SC.slate300,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: h.code));
                      Toast.show('Código ${h.code} copiado!', Icons.copy_rounded);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.copy_rounded, size: 13, color: p.text),
                        const SizedBox(width: 4),
                        Text('Copiar', style: ts(12, w: FontWeight.w500, c: p.text)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SC.blue500.o(.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SC.blue500.o(.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.lock_rounded, size: 12, color: p.dark ? SC.blue300 : SC.blue800),
                  const SizedBox(width: 4),
                  Text('Privacidade Garantida',
                      style: ts(11, w: FontWeight.w700, c: p.dark ? SC.blue300 : SC.blue800)),
                ]),
                const SizedBox(height: 4),
                Text.rich(TextSpan(style: ts(10, c: p.muted, h: 1.5), children: [
                  const TextSpan(
                      text: 'Parentes ou amigos (ex: seu cunhado e a esposa dele) usam o código de casa deles. Seus dados e salários ficam '),
                  TextSpan(text: '100% invisíveis', style: ts(10, w: FontWeight.w700, c: p.muted, h: 1.5)),
                  const TextSpan(text: ' para qualquer outra casa.'),
                ])),
              ]),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: p.chip,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: p.chipBorder),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => openHouseholdDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.sync_rounded, size: 14, color: p.text),
                      const SizedBox(width: 8),
                      Text('Alternar Código / Testar Isolamento',
                          style: ts(12, w: FontWeight.w700, c: p.text)),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _UserButton extends StatelessWidget {
  const _UserButton({required this.name, required this.active, required this.onTap});
  final String name;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Material(
      color: active ? SC.brand500.o(.15) : p.inner,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: active ? SC.brand500 : p.border2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(active ? Icons.how_to_reg_rounded : Icons.person_rounded,
              size: 14, color: active ? p.brandText : p.muted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: ts(12, w: FontWeight.w700, c: active ? p.brandText : p.muted)),
          ),
        ]),
      ),
    );
  }
}
