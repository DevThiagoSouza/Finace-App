import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Toast no topo da tela (igual ao app web), por cima de modais.
class Toast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(String msg, [IconData icon = Icons.check_circle_rounded]) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _timer?.cancel();
    _entry?.remove();
    final entry = OverlayEntry(builder: (ctx) => _ToastView(msg: msg, icon: icon));
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (_entry == entry) {
        entry.remove();
        _entry = null;
      }
    });
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.msg, required this.icon});
  final String msg;
  final IconData icon;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top + 16;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _c,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -.3), end: Offset.zero)
                .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut)),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: SC.slate800,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SC.brand500.o(.4)),
                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 16, color: SC.brand400),
                      const SizedBox(width: 8),
                      Flexible(child: Text(widget.msg, style: ts(12, c: Colors.white))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
