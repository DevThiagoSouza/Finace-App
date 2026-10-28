import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Preferências locais do aparelho (não vão para o Firebase).
class LocalPrefs {
  late SharedPreferences _p;

  Future<void> init() async => _p = await SharedPreferences.getInstance();

  bool get isDark => _p.getBool('stoco_dark') ?? true;
  Future<void> setDark(bool v) => _p.setBool('stoco_dark', v);

  List<String> get joined => _p.getStringList('stoco_joined') ?? [];
  Future<void> setJoined(List<String> v) => _p.setStringList('stoco_joined', v);

  String? get activeCode => _p.getString('stoco_active_house');
  Future<void> setActiveCode(String? v) =>
      v == null ? _p.remove('stoco_active_house') : _p.setString('stoco_active_house', v);

  /// "Dono deste celular" (por casa).
  String? activeUser(String code) => _p.getString('stoco_active_user_$code');
  Future<void> setActiveUser(String code, String name) =>
      _p.setString('stoco_active_user_$code', name);

  Map<String, dynamic>? get offlineData {
    final raw = _p.getString('stoco_offline_data');
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setOfflineData(Map<String, dynamic> data) =>
      _p.setString('stoco_offline_data', jsonEncode(data));
}
