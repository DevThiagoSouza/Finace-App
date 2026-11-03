import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

typedef Json = Map<String, dynamic>;

class FirestoreService {
  FirestoreService();

  late final FirebaseFirestore _db = _createDb();

  FirebaseFirestore _createDb() {
    final db = FirebaseFirestore.instance;
    db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    return db;
  }

  DocumentReference<Json> _house(String code) => _db.collection('households').doc(code);
  CollectionReference<Json> _fixed(String code) => _house(code).collection('fixedExpenses');
  CollectionReference<Json> _txs(String code) => _house(code).collection('transactions');
  CollectionReference<Json> _notifications(String code) => _house(code).collection('notifications');

  Stream<DocumentSnapshot<Json>> watchHouse(String code) =>
      _house(code).snapshots(includeMetadataChanges: true);

  Stream<QuerySnapshot<Json>> watchFixed(String code) =>
      _fixed(code).snapshots(includeMetadataChanges: true);

  Stream<QuerySnapshot<Json>> watchTxs(String code) =>
      _txs(code).snapshots(includeMetadataChanges: true);

  Stream<QuerySnapshot<Json>> watchNotifications(String code) => _notifications(code)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots(includeMetadataChanges: true);

  Future<HouseSummary?> houseSummary(String code) async {
    final s = await _house(code).get();
    if (!s.exists) return null;
    final h = Household.fromDoc(s.id, s.data()!);
    int? count;
    try {
      count = (await _txs(code).count().get()).count;
    } catch (_) {}
    return HouseSummary(
      code: code,
      name: h.name,
      members: h.members.map((m) => m.name).toList(),
      txCount: count,
    );
  }

  String newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return 'FAM-${List.generate(6, (_) => chars[random.nextInt(chars.length)]).join()}';
  }

  Future<void> createHouse(Household h) => _house(h.code).set(h.toMap());

  Future<void> updateMembers(String code, List<Member> members) =>
      _house(code).update({'members': members.map((m) => m.toMap()).toList()});

  Future<void> addTx(String code, Tx tx) => _txs(code).doc(tx.id).set(tx.toMap());
  Future<void> deleteTx(String code, String id) => _txs(code).doc(id).delete();

  Future<void> addFixed(String code, FixedExpense fixed) =>
      _fixed(code).doc(fixed.id).set(fixed.toMap());

  Future<void> deleteFixed(String code, String id) => _fixed(code).doc(id).delete();

  Future<void> addNotification({
    required String code,
    required String title,
    required String message,
    required String authorUid,
  }) =>
      _notifications(code).add({
        'title': title,
        'message': message,
        'authorUid': authorUid,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

  String newId(String code, String subcollection) =>
      _house(code).collection(subcollection).doc().id;

  Future<void> setNetwork(bool online) =>
      online ? _db.enableNetwork() : _db.disableNetwork();
}
