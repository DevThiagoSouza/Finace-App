import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'widgets/common.dart';
import 'widgets/toast.dart';

class StocoApp extends StatelessWidget {
  const StocoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.select<AppState, bool>((s) => s.isDark);
    return MaterialApp(
      title: 'Stoco Family',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(false),
      darkTheme: buildTheme(true),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Gate(),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = Pal.of(context);

    if (s.booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: SC.brand500)));
    }
    if (s.bootError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: p.amberText),
              const SizedBox(height: 16),
              Text('Não foi possível conectar ao Firebase',
                  textAlign: TextAlign.center, style: ts(16, w: FontWeight.w700, c: p.strong)),
              const SizedBox(height: 8),
              Text(s.bootError!, textAlign: TextAlign.center, maxLines: 6,
                  overflow: TextOverflow.ellipsis, style: ts(11, c: p.muted)),
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: GradientButton(label: 'Tentar novamente', icon: Icons.refresh_rounded, onTap: s.init),
              ),
            ]),
          ),
        ),
      );
    }
    if (s.activeCode == null) return const WelcomeScreen();
    return const HomeShell();
  }
}
