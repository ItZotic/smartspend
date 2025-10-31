import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();

  static final FirestoreService _instance = FirestoreService._();

  factory FirestoreService() => _instance;

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<String> addOrGetCategory({
    required String uid,
    required String name,
    required String type,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    final existing = await _firestore
        .collection('categories')
        .where('owner', isEqualTo: uid)
        .where('type', isEqualTo: type)
        .where('name', isEqualTo: trimmedName)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final doc = await _firestore.collection('categories').add({
      'name': trimmedName,
      'type': type,
      'owner': uid,
      'icon': '',
    });

    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamUserCategories({
    required String uid,
    required String type,
  }) {
    return _firestore
        .collection('categories')
        .where('owner', isEqualTo: uid)
        .where('type', isEqualTo: type)
        .orderBy('name')
        .snapshots();
  }

  Future<String> addTransaction({
    required String uid,
    required double amount,
    required String type,
    required String categoryId,
    String? note,
    required DateTime date,
  }) async {
    final positiveAmount = amount.abs();

    final doc = await _firestore.collection('transactions').add({
      'uid': uid,
      'amount': positiveAmount,
      'type': type,
      'categoryId': categoryId,
      'note': note ?? '',
      'date': Timestamp.fromDate(date),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamTransactions({
    required String uid,
    DateTime? start,
    DateTime? end,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('transactions')
        .where('uid', isEqualTo: uid);

    if (start != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start));
    }

    if (end != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    query = query.orderBy('date', descending: true);

    return query.snapshots();
  }
}
