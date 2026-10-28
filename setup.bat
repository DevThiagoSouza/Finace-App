@echo off
REM Gera as pastas nativas (android/ios/web) e prepara o projeto.
call flutter create --org com.stoco --project-name stoco_family --platforms=android,ios,web .

REM Firebase exige minSdk 23 no Android
if exist android\app\build.gradle.kts powershell -Command "(Get-Content android\app\build.gradle.kts) -replace 'flutter\.minSdkVersion','23' | Set-Content android\app\build.gradle.kts"
if exist android\app\build.gradle powershell -Command "(Get-Content android\app\build.gradle) -replace 'flutter\.minSdkVersion','23' | Set-Content android\app\build.gradle"

call flutter pub get

echo.
echo Pronto! Agora falta ligar ao SEU projeto Firebase:
echo   1) dart pub global activate flutterfire_cli
echo   2) flutterfire configure        (substitui lib\firebase_options.dart)
echo   3) firebase deploy --only firestore:rules
echo   4) flutter run
