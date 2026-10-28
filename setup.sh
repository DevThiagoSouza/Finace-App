#!/usr/bin/env bash
# Gera as pastas nativas (android/ios/web) e prepara o projeto.
set -e
flutter create --org com.stoco --project-name stoco_family --platforms=android,ios,web .

# Firebase exige minSdk 23 no Android
for f in android/app/build.gradle android/app/build.gradle.kts; do
  if [ -f "$f" ]; then
    sed -i.bak 's/flutter\.minSdkVersion/23/' "$f" && rm -f "$f.bak"
  fi
done

flutter pub get

echo ""
echo "Pronto! Agora falta ligar ao SEU projeto Firebase:"
echo "  1) dart pub global activate flutterfire_cli"
echo "  2) flutterfire configure        (substitui lib/firebase_options.dart)"
echo "  3) firebase deploy --only firestore:rules"
echo "  4) flutter run"
