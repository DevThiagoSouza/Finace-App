import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Cartão padrão (superfície + borda arredondada).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.color,
    this.borderColor,
    this.gradient,
    this.shadow = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? p.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? p.border),
        boxShadow: shadow
            ? [BoxShadow(color: Colors.black.o(.25), blurRadius: 24, offset: const Offset(0, 10))]
            : null,
      ),
      child: child,
    );
  }
}

/// Fundo interno (equivale a bg-slate-200/50 dark:bg-slate-950).
class InnerBox extends StatelessWidget {
  const InnerBox({super.key, required this.child, this.padding = const EdgeInsets.all(10), this.radius = 12});
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.inner,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.border2),
      ),
      child: child,
    );
  }
}

class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key, this.size = 12});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Bolinha que pulsa (status online).
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, required this.color, this.pulse = true});
  final Color color;
  final bool pulse;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = widget.pulse ? Curves.easeInOut.transform(_c.value) : 0.0;
        return Opacity(
          opacity: 1 - .5 * t,
          child: Transform.scale(scale: 1 + .2 * t, child: ColorDot(widget.color, size: 8)),
        );
      },
    );
  }
}

/// Botão "+" flutuante com a animação de pulso do app web.
class FabPulse extends StatefulWidget {
  const FabPulse({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<FabPulse> createState() => _FabPulseState();
}

class _FabPulseState extends State<FabPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(
          offset: Offset(0, -3 * t),
          child: Transform.scale(scale: 1 + .02 * t, child: child),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: gradBrand,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: SC.brand500.o(.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onTap,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

/// Botão com gradiente verde (Salvar etc.).
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color; // se informado, usa cor sólida

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: color == null ? gradBrand : null,
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: (color ?? SC.brand500).o(.25), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(label, style: ts(12, w: FontWeight.w700, c: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão pequeno tipo "pílula" (Editar / Nova Fixa / Adicionar).
class SmallTonalButton extends StatelessWidget {
  const SmallTonalButton({super.key, required this.label, required this.icon, required this.color, required this.textColor, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.o(.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.o(.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(label, style: ts(12, w: FontWeight.w700, c: textColor)),
          ]),
        ),
      ),
    );
  }
}

class CloseCircleButton extends StatelessWidget {
  const CloseCircleButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: p.chip, shape: BoxShape.circle),
        child: Icon(Icons.close_rounded, size: 16, color: p.muted),
      ),
    );
  }
}

/// Cabeçalho de modal (ícone + título + fechar), com divisória.
class ModalHeader extends StatelessWidget {
  const ModalHeader({super.key, required this.icon, required this.iconColor, required this.title});
  final IconData icon;
  final Color iconColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border))),
      child: Row(children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: ts(14, w: FontWeight.w700, c: p.text))),
        CloseCircleButton(onTap: () => Navigator.of(context).pop()),
      ]),
    );
  }
}

/// Diálogo central padrão (cantos 24, borda).
Future<T?> showAppDialog<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showDialog<T>(
    context: context,
    barrierColor: Pal.of(context).overlay,
    builder: (ctx) {
      final p = Pal.of(ctx);
      return Dialog(
        backgroundColor: p.surface,
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: p.border2),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: builder(ctx),
          ),
        ),
      );
    },
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text.toUpperCase(),
            style: ts(10, w: FontWeight.w600, c: Pal.of(context).muted, ls: .8)),
      );
}

InputDecoration inputDeco(BuildContext context,
    {String? hint, double radius = 12, EdgeInsets? pad, Widget? prefix, Widget? prefixIcon}) {
  final p = Pal.of(context);
  OutlineInputBorder b(Color c) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: c));
  return InputDecoration(
    isDense: true,
    hintText: hint,
    hintStyle: ts(12, c: SC.slate400),
    filled: true,
    fillColor: p.inner,
    contentPadding: pad ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: b(p.border2),
    focusedBorder: b(SC.brand500),
    border: b(p.border2),
    prefix: prefix,
    prefixIcon: prefixIcon,
  );
}

/// Retângulo arredondado tracejado (botão "Criar / Conectar").
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, required this.color, this.radius = 12});
  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DashedPainter(color, radius), child: child);
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, math.min(d + 5, m.length)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPainter old) => old.color != color || old.radius != radius;
}
