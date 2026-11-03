import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/toast.dart';

/// Modal "Alternar Código de Casa".
Future<void> openHouseholdDialog(BuildContext context) =>
    showAppDialog(context, builder: (_) => const _HouseholdList());

/// Modal "Criar / Conectar a Novo Código".
Future<void> openNewHouseholdDialog(BuildContext context) =>
    showAppDialog(context, builder: (_) => const _NewHousehold());

class _HouseholdList extends StatelessWidget {
  const _HouseholdList();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);

    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModalHeader(
              icon: Icons.home_rounded,
              iconColor: SC.brand500,
              title: 'Alternar Código de Casa'),
          const SizedBox(height: 16),
          Text(
              'Cada núcleo familiar tem um código isolado. Alterne entre os códigos para testar a privacidade total:',
              style: ts(12, c: p.muted)),
          const SizedBox(height: 14),
          for (final code in s.joined) ...[
            _HouseTile(code: code, current: code == s.activeCode),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration:
                BoxDecoration(border: Border(top: BorderSide(color: p.border))),
            child: DashedBox(
              color: p.dark ? SC.slate700 : SC.slate400,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.of(context).pop();
                  openNewHouseholdDialog(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 14, color: p.soft),
                        const SizedBox(width: 8),
                        Text('Criar / Conectar a Novo Código',
                            style: ts(12, w: FontWeight.w700, c: p.soft)),
                      ]),
                ),
              ),
            ),
          ),
        ]);
  }
}

class _HouseTile extends StatefulWidget {
  const _HouseTile({required this.code, required this.current});
  final String code;
  final bool current;

  @override
  State<_HouseTile> createState() => _HouseTileState();
}

class _HouseTileState extends State<_HouseTile> {
  late final Future<HouseSummary?> _future =
      context.read<AppState>().summary(widget.code);

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final s = context.read<AppState>();
    final code = widget.code;
    final current = widget.current;

    return FutureBuilder<HouseSummary?>(
      future: _future,
      builder: (ctx, snap) {
        final h = snap.data;
        final name = h?.name ??
            (snap.connectionState == ConnectionState.done
                ? code
                : 'Carregando...');
        final detail = h == null
            ? ''
            : 'Membros: ${h.members.join(', ')}${h.txCount != null ? ' • ${h.txCount} lançamentos' : ''}';

        return Material(
          color: current ? SC.brand500.o(.1) : p.inner,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: current ? SC.brand500 : p.border2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).pop();
              s.switchHousehold(code, name: h?.name ?? code);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                              child: Text(name,
                                  style:
                                      ts(12, w: FontWeight.w700, c: p.text))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.dark ? SC.slate800 : SC.slate300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(code,
                                style:
                                    ts(10, w: FontWeight.w700, c: p.brandText)),
                          ),
                        ]),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(detail, style: ts(10, c: p.muted)),
                    ],
                  ]),
            ),
          ),
        );
      },
    );
  }
}

class _NewHousehold extends StatefulWidget {
  const _NewHousehold();

  @override
  State<_NewHousehold> createState() => _NewHouseholdState();
}

class _NewHouseholdState extends State<_NewHousehold> {
  final _name = TextEditingController();
  final _firstMember = TextEditingController();
  final _secondMember = TextEditingController();
  final _code = TextEditingController();
  bool _joining = false;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _firstMember.dispose();
    _secondMember.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty || _firstMember.text.trim().isEmpty) {
      setState(() => _error = 'Informe o nome do espaço e da primeira pessoa.');
      return;
    }
    setState(() {
      _error = null;
      _creating = true;
    });
    try {
      final state = context.read<AppState>();
      final names = [_firstMember.text.trim(), _secondMember.text.trim()]
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      final code = await state.createHousehold(_name.text, memberNames: names);
      final offline = !state.firebaseAvailable;
      if (!mounted) return;
      Navigator.of(context).pop();
      await Clipboard.setData(ClipboardData(text: code));
      Toast.show(
        offline
            ? 'Código criado neste aparelho: $code. Conecte o Firebase para usar em outro celular.'
            : 'Código criado e copiado: $code',
        offline ? Icons.wifi_off_rounded : Icons.copy_rounded,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _creating = false;
        _error =
            'Não foi possível criar o código. Verifique a conexão e tente novamente.';
      });
    }
  }

  Future<void> _join() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Digite o código da casa.');
      return;
    }
    setState(() {
      _joining = true;
      _error = null;
    });
    final ok = await context.read<AppState>().joinHousehold(_code.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _joining = false;
        _error = 'Código não encontrado.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ModalHeader(
              icon: Icons.home_rounded,
              iconColor: SC.brand500,
              title: 'Criar / Conectar a Novo Código'),
          const SizedBox(height: 16),
          const FieldLabel('Criar novo espaço familiar'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style: ts(12, c: p.text),
            decoration: inputDeco(context, hint: 'Ex: Lucas & Camila'),
          ),
          const SizedBox(height: 10),
          const FieldLabel('Seu nome'),
          TextField(
            controller: _firstMember,
            textCapitalization: TextCapitalization.words,
            style: ts(12, c: p.text),
            decoration: inputDeco(context, hint: 'Ex: João'),
          ),
          const SizedBox(height: 10),
          const FieldLabel('Nome da segunda pessoa (opcional)'),
          TextField(
            controller: _secondMember,
            textCapitalization: TextCapitalization.words,
            style: ts(12, c: p.text),
            decoration: inputDeco(context, hint: 'Ex: Maria'),
          ),
          const SizedBox(height: 10),
          GradientButton(
            label: _creating ? 'Criando...' : 'Criar Espaço',
            icon: Icons.add_rounded,
            onTap: _creating ? () {} : _create,
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Divider(color: p.border2)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('OU', style: ts(10, w: FontWeight.w700, c: p.muted)),
            ),
            Expanded(child: Divider(color: p.border2)),
          ]),
          const SizedBox(height: 14),
          const FieldLabel('Já tenho um código'),
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            style: ts(12, w: FontWeight.w700, c: p.text, ls: 1),
            decoration: inputDeco(context, hint: 'FAM-XXXXXX'),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: _joining ? .6 : 1,
            child: GradientButton(
              label: _joining ? 'Conectando...' : 'Conectar',
              icon: Icons.link_rounded,
              color: SC.brand600,
              onTap: _joining ? () {} : _join,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: ts(11, w: FontWeight.w600, c: p.redText)),
          ],
        ]);
  }
}
