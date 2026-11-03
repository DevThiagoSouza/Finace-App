import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/local_prefs.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  var firebaseAvailable = true;
  try {
    await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform)
        .timeout(
      const Duration(seconds: 30),
    );
  } catch (_) {
    // O Firebase pode terminar a inicialização depois do limite de abertura.
    // O AppState tenta autenticar novamente quando a internet estiver disponível.
    firebaseAvailable = true;
  }

  final prefs = LocalPrefs();
  await prefs.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(FirestoreService(), prefs,
          firebaseAvailable: firebaseAvailable)
        ..init(),
      child: const StocoApp(),
    ),
  );
}
