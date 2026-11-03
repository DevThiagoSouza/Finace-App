import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../dialogs/household_dialog.dart';
import '../dialogs/transaction_sheet.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'tabs/extrato_tab.dart';
import 'tabs/family_tab.dart';
import 'tabs/fixas_tab.dart';
import 'tabs/home_tab.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);

    if (s.house == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: SC.brand500)));
    }

    const tabs = <Widget>[HomeTab(), FixasTab(), ExtratoTab(), FamilyTab()];

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(children: [
              const _Header(),
              const _SpaceBanner(),
              const _ViewModeBar(),
              if (!s.isOnline) const _OfflineBanner(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(key: ValueKey(s.tabIndex), child: tabs[s.tabIndex]),
                ),
              ),
            ]),
          ),
        ),
      ),
      floatingActionButton: FabPulse(onTap: () => openTransactionSheet(context)),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

// ---------------------------------------------------------------- Header
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: p.header,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: gradBrand,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: SC.brand500.o(.25), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.home_work_rounded, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              s.house!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts(16, w: FontWeight.w800, c: p.strong, ls: -.3, h: 1),
            ),
            const SizedBox(height: 3),
            Text.rich(TextSpan(style: ts(11, c: p.muted), children: [
              const TextSpan(text: 'Celular de: '),
              TextSpan(text: s.activeUser, style: ts(11, w: FontWeight.w700, c: p.brandText)),
            ])),
          ]),
        ),
        _SyncPill(online: s.isOnline, onTap: s.toggleOnline),
        const SizedBox(width: 8),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: s.toggleTheme,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: p.chip, shape: BoxShape.circle),
            child: Icon(
              p.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 14,
              color: p.dark ? SC.amber400 : SC.indigo600,
            ),
          ),
        ),
      ]),
    );
  }
}

class _SyncPill extends StatelessWidget {
  const _SyncPill({required this.online, required this.onTap});
  final bool online;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final base = online ? SC.brand500 : SC.amber500;
    final text = online ? p.brandText : (p.dark ? SC.amber400 : SC.amber600);
    return Material(
      color: base.o(p.dark && online ? .2 : .1),
      shape: StadiumBorder(side: BorderSide(color: base.o(.3))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            PulseDot(color: base, pulse: online),
            const SizedBox(width: 6),
            Text(online ? 'Online' : 'Offline', style: ts(10, w: FontWeight.w600, c: text)),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Banner da casa
class _SpaceBanner extends StatelessWidget {
  const _SpaceBanner();

  @override
  Widget build(BuildContext context) {
    final h = context.watch<AppState>().house!;
    final p = Pal.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: p.bannerBg,
        border: Border(bottom: BorderSide(color: p.border2)),
      ),
      child: Row(children: [
        Icon(Icons.shield_rounded, size: 13, color: p.brandText),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(style: ts(11, w: FontWeight.w500, c: p.soft), children: [
              const TextSpan(text: 'Espaço: '),
              TextSpan(text: h.name, style: ts(11, w: FontWeight.w700, c: p.soft)),
            ]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: SC.brand500.o(.15), borderRadius: BorderRadius.circular(4)),
          child: Text(h.code,
              style: monoStyle(10, p.dark ? SC.brand400 : SC.brand700)),
        ),
        const Spacer(),
        InkWell(
          onTap: () => openHouseholdDialog(context),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.sync_rounded, size: 11, color: p.brandText),
            const SizedBox(width: 4),
            Text('Trocar Código', style: ts(10, w: FontWeight.w800, c: p.brandText)),
          ]),
        ),
      ]),
    );
  }
}

TextStyle monoStyle(double size, Color c) =>
    TextStyle(fontFamily: 'monospace', fontSize: size, fontWeight: FontWeight.w700, color: c);


// ---------------------------------------------------------------- Seletor de visão
class _ViewModeBar extends StatelessWidget {
  const _ViewModeBar();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);
    final h = s.house!;

    Widget pill(String label, String value) {
      final selected = s.viewMember == value;
      return GestureDetector(
        onTap: () => s.setViewMember(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? SC.brand500 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected ? [BoxShadow(color: Colors.black.o(.2), blurRadius: 6, offset: const Offset(0, 2))] : null,
          ),
          child: Text(label,
              style: ts(11, w: FontWeight.w700, c: selected ? Colors.white : (p.dark ? SC.slate400 : SC.slate600))),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: p.dark ? SC.slate900.o(.7) : SC.slate100,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(children: [
        Text('VISÃO:', style: ts(10, w: FontWeight.w700, c: p.muted, ls: 1)),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: p.dark ? SC.slate950 : SC.slate200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: p.dark ? SC.slate800.o(.8) : SC.slate300),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  pill('👥 Casal (Geral)', 'all'),
                  for (final m in h.members) pill('👤 ${m.name}', m.name),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);
    final color = p.dark ? SC.amber400 : SC.amber600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SC.amber500.o(.15),
        border: Border(bottom: BorderSide(color: SC.amber500.o(.3))),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.wifi_off_rounded, size: 13, color: color),
          const SizedBox(width: 6),
          Text('Salvo localmente (${s.pendingCount} pendentes)',
              style: ts(11, w: FontWeight.w500, c: color)),
        ]),
        InkWell(
          onTap: s.toggleOnline,
          child: Text('Sincronizar Agora',
              style: ts(10, w: FontWeight.w700, c: color).copyWith(decoration: TextDecoration.underline)),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- Navegação inferior
class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);

    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.calculate_rounded, 'Fixas & Renda'),
      (Icons.receipt_long_rounded, 'Extrato'),
      (Icons.groups_rounded, 'Família'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: p.header,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => s.setTab(i),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(items[i].$1, size: 20, color: s.tabIndex == i ? p.brandText : p.muted),
                    const SizedBox(height: 4),
                    Text(items[i].$2,
                        style: ts(10,
                            w: s.tabIndex == i ? FontWeight.w700 : FontWeight.w400,
                            c: s.tabIndex == i ? p.brandText : p.muted)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
