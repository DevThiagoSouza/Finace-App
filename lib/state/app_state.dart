import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/local_prefs.dart';
import '../widgets/toast.dart';

class AppState extends ChangeNotifier {
  AppState(this._db, this._prefs, {this.firebaseAvailable = true});

  final FirestoreService _db;
  final LocalPrefs _prefs;
  bool firebaseAvailable;

  // ---------- Estado ----------
  bool booting = true;
  String? bootError;
  bool isDark = true;
  bool isOnline = true;
  String? firebaseError;

  List<String> joined = [];
  String? activeCode;
  Household? house;
  List<FixedExpense> fixed = [];
  List<Tx> txs = [];
  List<HouseholdNotification> notifications = [];
  int pendingCount = 0;

  String viewMember = 'all'; // 'all' = Casal (Geral) ou nome do membro
  int tabIndex = 0;
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  final Map<String, String> _activeUsers = {};
  final List<StreamSubscription> _subs = [];
  bool _notificationsLoaded = false;
  Timer? _reconnectTimer;

  // ---------- Boot ----------
  Future<void> init() async {
    var finished = false;
    final watchdog = Timer(const Duration(seconds: 12), () {
      if (!finished && booting) {
        booting = false;
        isOnline = false;
        bootError = null;
        notifyListeners();
        _scheduleReconnect();
      }
    });
    booting = true;
    bootError = null;
    notifyListeners();
    try {
      isDark = _prefs.isDark;
      joined = List.of(_prefs.joined);
      activeCode = _prefs.activeCode;

      if (!firebaseAvailable) {
        await _initOffline();
      } else {
        await _connectFirebase();
        if (FirebaseAuth.instance.currentUser == null) {
          await _initOffline();
        }
      }

      for (final c in joined) {
        final u = _prefs.activeUser(c);
        if (u != null) _activeUsers[c] = u;
      }

      if (activeCode != null && !joined.contains(activeCode)) {
        activeCode = joined.isEmpty ? null : joined.first;
      }
      if (activeCode == null && joined.isNotEmpty) activeCode = joined.first;

      booting = false;
      if (activeCode != null &&
          firebaseAvailable &&
          FirebaseAuth.instance.currentUser != null) {
        _listen(activeCode!);
      }
      if (FirebaseAuth.instance.currentUser == null) _scheduleReconnect();
    } catch (e) {
      isOnline = false;
      bootError = null;
    } finally {
      finished = true;
      watchdog.cancel();
      booting = false;
      notifyListeners();
    }
  }

  Future<void> _connectFirebase() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously().timeout(
              const Duration(seconds: 30),
            );
      }
      firebaseAvailable = true;
      isOnline = true;
      firebaseError = null;
    } on FirebaseException catch (e) {
      firebaseAvailable = true;
      isOnline = false;
      firebaseError = '${e.code}: ${e.message ?? 'erro do Firebase'}';
    } catch (e) {
      firebaseAvailable = true;
      isOnline = false;
      firebaseError = e.toString();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
        await _connectFirebase();
      }
      if (FirebaseAuth.instance.currentUser != null) {
        isOnline = true;
        if (activeCode != null && _subs.isEmpty) _listen(activeCode!);
        notifyListeners();
        _reconnectTimer?.cancel();
      }
    });
  }

  Future<void> _initOffline() async {
    isOnline = false;
    final saved = _prefs.offlineData;
    if (saved != null) {
      _loadOffline(saved);
    }
    if (activeCode != null) _loadOfflineHouse(activeCode!);
  }

  void _loadOffline(Map<String, dynamic> data) {
    final houses = Map<String, dynamic>.from(data['houses'] as Map? ?? {});
    final raw = Map<String, dynamic>.from(houses[activeCode] as Map? ?? {});
    house = raw['house'] == null
        ? null
        : Household.fromDoc(
            activeCode!, Map<String, dynamic>.from(raw['house']));
    fixed = (raw['fixed'] as List? ?? []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return FixedExpense(
        id: m['id'] as String,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        payer: m['payer'] as String,
        paymentMethod: (m['paymentMethod'] ?? 'debit') as String,
      );
    }).toList();
    txs = (raw['txs'] as List? ?? []).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return Tx(
        id: m['id'] as String,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        type: m['type'] as String,
        category: m['category'] as String,
        payer: m['payer'] as String,
        date: m['date'] as String,
        createdAt: (m['createdAt'] as num).toInt(),
        paymentMethod: (m['paymentMethod'] ?? 'debit') as String,
        installmentNumber: ((m['installmentNumber'] ?? 1) as num).toInt(),
        installmentTotal: ((m['installmentTotal'] ?? 1) as num).toInt(),
        recurringId: m['recurringId'] as String?,
      );
    }).toList();
  }

  void _loadOfflineHouse(String code) {
    final data = _prefs.offlineData;
    if (data != null) {
      activeCode = code;
      _loadOffline(data);
    }
  }

  Future<void> _saveOffline() async {
    final data =
        _prefs.offlineData ?? <String, dynamic>{'houses': <String, dynamic>{}};
    final houses = Map<String, dynamic>.from(data['houses'] as Map? ?? {});
    if (house != null) {
      houses[house!.code] = {
        'house': house!.toMap(),
        'fixed': fixed
            .map((f) => {
                  'id': f.id,
                  'title': f.title,
                  'amount': f.amount,
                  'payer': f.payer,
                  'paymentMethod': f.paymentMethod,
                })
            .toList(),
        'txs': txs.map((t) => t.toMap()..['id'] = t.id).toList(),
      };
    }
    data['houses'] = houses;
    await _prefs.setOfflineData(data);
  }

  // ---------- Listeners do Firestore ----------
  void _cancelSubs() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _listen(String code) {
    _cancelSubs();
    house = null;
    fixed = [];
    txs = [];
    notifications = [];
    _notificationsLoaded = false;
    pendingCount = 0;

    _subs.add(_db.watchHouse(code).listen((snap) {
      if (!snap.exists) {
        if (!snap.metadata.isFromCache) _houseMissing(code);
        return;
      }
      house = Household.fromDoc(snap.id, snap.data()!);
      if (viewMember != 'all' &&
          !house!.members.any((m) => m.name == viewMember)) {
        viewMember = 'all';
      }
      notifyListeners();
    },
        onError: (e) =>
            Toast.show('Erro ao carregar a casa', Icons.error_outline)));

    _subs.add(_db.watchFixed(code).listen((snap) {
      fixed = snap.docs.map(FixedExpense.fromDoc).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      notifyListeners();
    }));

    _subs.add(_db.watchTxs(code).listen((snap) {
      txs = snap.docs.map(Tx.fromDoc).toList()
        ..sort((a, b) {
          final c = b.date.compareTo(a.date);
          return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
        });
      pendingCount = txs.where((t) => t.pending).length;
      notifyListeners();
    }));

    _subs.add(_db.watchNotifications(code).listen((snap) {
      final next = snap.docs.map(HouseholdNotification.fromDoc).toList();
      if (_notificationsLoaded) {
        final previousIds = notifications.map((n) => n.id).toSet();
        for (final notification in next.reversed) {
          if (!previousIds.contains(notification.id) &&
              notification.authorUid != _currentUid) {
            Toast.show('${notification.title}: ${notification.message}',
                Icons.notifications_active_rounded);
          }
        }
      }
      notifications = next;
      _notificationsLoaded = true;
      notifyListeners();
    },
        onError: (e) => Toast.show(
            'Não foi possível carregar notificações.', Icons.error_outline)));
  }

  String get _currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _notifyHousehold(String title, String message) {
    final code = activeCode;
    if (code == null || !firebaseAvailable || _currentUid.isEmpty) return;
    _write(_db.addNotification(
      code: code,
      title: title,
      message: message,
      authorUid: _currentUid,
    ));
  }

  void _houseMissing(String code) {
    joined.remove(code);
    _prefs.setJoined(joined);
    activeCode = joined.isEmpty ? null : joined.first;
    _prefs.setActiveCode(activeCode);
    if (activeCode != null) {
      _listen(activeCode!);
    } else {
      _cancelSubs();
      house = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _cancelSubs();
    super.dispose();
  }

  // ---------- Getters de cálculo (mesma matemática do app web) ----------
  String get activeUser {
    final h = house;
    if (h == null || h.members.isEmpty) return '';
    final saved = _activeUsers[activeCode];
    if (saved != null && h.members.any((m) => m.name == saved)) return saved;
    return h.members.first.name;
  }

  List<Tx> get monthTxs {
    final k = monthKey(month);
    return txs.where((t) => t.date.startsWith(k)).toList();
  }

  List<Tx> get viewTxs => monthTxs
      .where((t) => viewMember == 'all' || t.payer == viewMember)
      .toList();

  List<FixedExpense> get viewFixed =>
      fixed.where((f) => viewMember == 'all' || f.payer == viewMember).toList();

  List<Member> get viewMembers => house == null
      ? []
      : house!.members
          .where((m) => viewMember == 'all' || m.name == viewMember)
          .toList();

  Map<String, MemberStats> get memberStats {
    final h = house;
    if (h == null || h.members.isEmpty) return {};
    final res = {
      for (final m in h.members) m.name: MemberStats(salary: m.salary)
    };
    final first = h.members.first.name;

    for (final f in fixed) {
      res[res.containsKey(f.payer) ? f.payer : first]!.fixed += f.amount;
    }
    for (final t in monthTxs) {
      if (t.isExpense) {
        res[res.containsKey(t.payer) ? t.payer : first]!.variable += t.amount;
      }
    }
    return res;
  }

  MemberStats get viewTotals {
    final stats = memberStats;
    if (viewMember == 'all') {
      final total = MemberStats();
      for (final s in stats.values) {
        total.salary += s.salary;
        total.fixed += s.fixed;
        total.variable += s.variable;
      }
      return total;
    }
    return stats[viewMember] ?? MemberStats();
  }

  // ---------- UI ----------
  void setTab(int i) {
    tabIndex = i;
    notifyListeners();
  }

  void setViewMember(String name, {bool toast = true}) {
    viewMember = name;
    notifyListeners();
    if (toast) {
      Toast.show(
          name == 'all' ? 'Visão Geral do Casal' : 'Visão Individual: $name',
          Icons.filter_alt_rounded);
    }
  }

  void shiftMonth(int delta) {
    month = DateTime(month.year, month.month + delta);
    notifyListeners();
  }

  void toggleTheme() {
    isDark = !isDark;
    _prefs.setDark(isDark);
    notifyListeners();
  }

  Future<void> toggleOnline() async {
    if (!firebaseAvailable) {
      isOnline = !isOnline;
      notifyListeners();
      Toast.show(
        isOnline ? 'Modo local ativo (sem Firebase).' : 'Modo Offline ativo.',
        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
      );
      return;
    }
    if (isOnline) {
      isOnline = false;
      notifyListeners();
      await _db.setNetwork(false);
      Toast.show('Modo Offline ativo.', Icons.wifi_off_rounded);
    } else {
      final n = pendingCount;
      isOnline = true;
      notifyListeners();
      await _db.setNetwork(true);
      Toast.show(
        n > 0 ? '$n lançamentos sincronizados!' : 'Conexão online ativa.',
        n > 0 ? Icons.cloud_done_rounded : Icons.wifi_rounded,
      );
    }
  }

  // ---------- Dono do celular ----------
  void setActiveUser(String name) {
    final code = activeCode;
    if (code == null) return;
    _activeUsers[code] = name;
    _prefs.setActiveUser(code, name);
    notifyListeners();
    Toast.show('Dono deste celular: $name', Icons.how_to_reg_rounded);
  }

  // ---------- Membros / salários ----------
  void addMember(String name) {
    final h = house;
    if (h == null || name.trim().isEmpty) return;
    final n = name.trim();
    if (h.members.any((m) => m.name.toLowerCase() == n.toLowerCase())) {
      Toast.show('Já existe um membro com esse nome.', Icons.error_outline);
      return;
    }
    final members = [
      ...h.members,
      Member(
          name: n,
          salary: 0,
          colorIndex: h.members.length % kMemberColors.length),
    ];
    if (firebaseAvailable) {
      _write(_db.updateMembers(h.code, members));
      _notifyHousehold('Pessoa adicionada', '$n foi adicionada ao espaço.');
    } else {
      house = Household(code: h.code, name: h.name, members: members);
      _saveOffline();
      notifyListeners();
    }
    Toast.show('Membro $n adicionado!', Icons.person_add_rounded);
  }

  void removeMember(String name) {
    final h = house;
    if (h == null || h.members.length <= 1) return;
    final members = h.members.where((m) => m.name != name).toList();
    if (firebaseAvailable) {
      _write(_db.updateMembers(h.code, members));
      _notifyHousehold('Pessoa removida', '$name foi removida do espaço.');
    } else {
      house = Household(code: h.code, name: h.name, members: members);
      _saveOffline();
      notifyListeners();
    }
    Toast.show('Membro removido.', Icons.person_remove_rounded);
  }

  void saveSalaries(Map<String, double> salaries) {
    final h = house;
    if (h == null) return;
    final members = h.members
        .map((m) => m.copyWith(
              salary: salaries[m.name] ?? m.salary,
              incomePaymentMethod: 'pix',
            ))
        .toList();
    if (firebaseAvailable) {
      _write(_db.updateMembers(h.code, members));
    } else {
      house = Household(code: h.code, name: h.name, members: members);
      _saveOffline();
      notifyListeners();
    }
    _notifyHousehold('Renda atualizada', 'As rendas fixas foram atualizadas.');
    _syncFixedIncomeTransactions(h.code, members);
    Toast.show(
        'Salários individuais salvos!', Icons.account_balance_wallet_rounded);
  }

  void _syncFixedIncomeTransactions(String code, List<Member> members) {
    final start = DateTime(month.year, month.month);
    for (final member in members) {
      if (member.salary <= 0) continue;
      for (var offset = 0; offset < 12; offset++) {
        final date = DateTime(start.year, start.month + offset, 1);
        final dateKey = monthKey(date);
        final tx = Tx(
          id: _fixedIncomeId(member.name, dateKey),
          title: 'Renda fixa - ${member.name}',
          amount: member.salary,
          type: 'income',
          category: 'Renda fixa',
          payer: member.name,
          date: isoDate(date),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          paymentMethod: 'pix',
          recurringId: 'salary:${member.name}',
        );
        if (firebaseAvailable) {
          _write(_db.addTx(code, tx));
        } else {
          txs = [...txs.where((t) => t.id != tx.id), tx];
        }
      }
    }
    if (!firebaseAvailable) {
      txs.sort((a, b) => b.date.compareTo(a.date));
      _saveOffline();
      notifyListeners();
    }
  }

  String _fixedIncomeId(String name, String dateKey) {
    final safeName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return 'fixed-income-$safeName-$dateKey';
  }

  // ---------- Despesas fixas ----------
  void addFixed(String title, double amount, String payer, String paymentMethod,
      int installments) {
    final code = activeCode;
    if (code == null) return;
    if (paymentMethod == 'credit') {
      addTransaction(
        title: title,
        amount: amount,
        type: 'expense',
        category: 'Contas',
        payer: payer,
        date: isoDate(DateTime.now()),
        paymentMethod: paymentMethod,
        installments: installments,
      );
      Toast.show('Despesa parcelada adicionada aos extratos futuros.',
          Icons.credit_card_rounded);
      return;
    }
    final f = FixedExpense(
      id: _db.newId(code, 'fixedExpenses'),
      title: title,
      amount: amount,
      payer: payer,
      paymentMethod: paymentMethod,
    );
    if (firebaseAvailable) {
      _write(_db.addFixed(code, f));
      _notifyHousehold('Despesa fixa adicionada', title);
    } else {
      fixed = [...fixed, f];
      _saveOffline();
      notifyListeners();
    }
    Toast.show('Despesa fixa cadastrada!', Icons.receipt_long_rounded);
  }

  void deleteFixed(String id) {
    final code = activeCode;
    if (code == null) return;
    if (firebaseAvailable) {
      _write(_db.deleteFixed(code, id));
    } else {
      fixed = fixed.where((f) => f.id != id).toList();
      _saveOffline();
      notifyListeners();
    }
    Toast.show('Despesa fixa removida.', Icons.delete_outline_rounded);
  }

  // ---------- Lançamentos ----------
  void addTransaction({
    required String title,
    required double amount,
    required String type,
    required String category,
    required String payer,
    required String date,
    String paymentMethod = 'debit',
    int installments = 1,
  }) {
    final code = activeCode;
    final h = house;
    if (code == null || h == null) return;
    final total = paymentMethod == 'credit'
        ? (installments < 1
            ? 1
            : installments > 120
                ? 120
                : installments)
        : 1;
    final purchaseDate = DateTime.parse(date);
    final cents = (amount * 100).round();
    for (var i = 0; i < total; i++) {
      final installmentCents = cents ~/ total + (i < cents % total ? 1 : 0);
      final installmentDate = _addMonthsClamped(purchaseDate, i);
      final tx = Tx(
        id: _db.newId(code, 'transactions'),
        title: total > 1 ? '$title (${i + 1}/$total)' : title,
        amount: installmentCents / 100,
        type: type,
        category: category,
        payer: payer.isEmpty ? h.members.first.name : payer,
        date: isoDate(installmentDate),
        createdAt: DateTime.now().millisecondsSinceEpoch + i,
        paymentMethod: paymentMethod,
        installmentNumber: i + 1,
        installmentTotal: total,
      );
      if (firebaseAvailable) {
        _write(_db.addTx(code, tx));
      } else {
        txs = [...txs, tx];
      }
    }
    _notifyHousehold(
      type == 'expense' ? 'Nova saída' : 'Nova entrada',
      total > 1 ? '$title ($total parcelas)' : title,
    );
    if (!firebaseAvailable) {
      _saveOffline();
      notifyListeners();
    }
    if (!isOnline) {
      Toast.show('Salvo OFFLINE no aparelho!', Icons.wifi_off_rounded);
    } else {
      Toast.show('Lançamento gravado no espaço!', Icons.cloud_upload_rounded);
    }
  }

  DateTime _addMonthsClamped(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months, 1);
    final lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(
        target.year, target.month, date.day > lastDay ? lastDay : date.day);
  }

  void deleteTransaction(String id) {
    final code = activeCode;
    if (code == null) return;
    if (firebaseAvailable) {
      _write(_db.deleteTx(code, id));
    } else {
      txs = txs.where((t) => t.id != id).toList();
      _saveOffline();
      notifyListeners();
    }
    Toast.show('Lançamento removido.', Icons.delete_outline_rounded);
  }

  // ---------- Casas ----------
  Future<HouseSummary?> summary(String code) => _db.houseSummary(code);

  void switchHousehold(String code, {String? name}) {
    activeCode = code;
    viewMember = 'all';
    if (!joined.contains(code)) joined.add(code);
    _prefs.setJoined(joined);
    _prefs.setActiveCode(code);
    final u = _prefs.activeUser(code);
    if (u != null) _activeUsers[code] = u;
    if (firebaseAvailable) {
      _listen(code);
    } else if (house?.code != code) {
      _loadOfflineHouse(code);
    }
    notifyListeners();
    if (name != null) {
      Toast.show('Conectado ao Espaço $name', Icons.home_rounded);
    }
  }

  Future<String> createHousehold(String name,
      {required List<String> memberNames}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      await _connectFirebase();
    }
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError(
        firebaseError ??
            'Não foi possível conectar ao Firebase. Verifique a internet e se o login anônimo está ativado.',
      );
    }
    var code = _db.newCode();
    if (firebaseAvailable) {
      for (var attempt = 0; attempt < 5; attempt++) {
        if (await _db.houseSummary(code) == null) break;
        code = _db.newCode();
      }
    }
    final h = Household(
      code: code,
      name: name.trim(),
      members: [
        for (var i = 0; i < memberNames.length; i++)
          Member(
              name: memberNames[i],
              salary: 0,
              colorIndex: (i + 2) % kMemberColors.length),
      ],
    );
    if (firebaseAvailable) {
      await _db.createHouse(h);
    } else {
      house = h;
      fixed = [];
      txs = [];
      _saveOffline();
    }
    switchHousehold(code, name: h.name);
    return code;
  }

  /// Conecta a uma casa existente pelo código. Retorna `false` se não existir.
  Future<bool> joinHousehold(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return false;
    if (!firebaseAvailable) {
      Toast.show('Firebase está indisponível neste aparelho.',
          Icons.cloud_off_rounded);
      return false;
    }
    HouseSummary? s;
    try {
      s = await _db.houseSummary(code);
    } on FirebaseException catch (e) {
      Toast.show(
        e.code == 'permission-denied'
            ? 'Firebase recusou o acesso. Verifique o projeto e as regras.'
            : 'Falha ao consultar o código: ${e.message ?? e.code}',
        Icons.error_outline,
      );
      return false;
    } catch (e) {
      Toast.show('Não foi possível consultar o código. Verifique a internet.',
          Icons.error_outline);
      return false;
    }
    if (s == null) {
      Toast.show('Código não encontrado.', Icons.error_outline);
      return false;
    }
    switchHousehold(code, name: s.name);
    return true;
  }

  // ---------- Utils ----------
  /// Escritas no Firestore NÃO são aguardadas: offline o Future só completa
  /// ao reconectar, e o app deve continuar fluido (a UI atualiza na hora via cache local).
  void _write(Future<void> f) {
    f.catchError((e) {
      Toast.show('Falha ao salvar: verifique a conexão/permissões.',
          Icons.error_outline);
    });
  }
}
