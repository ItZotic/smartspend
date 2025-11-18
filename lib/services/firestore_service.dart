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
      'icon': '', // Default icon
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
        // .orderBy('name') // This line is commented out to fix the read error
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
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }

    if (end != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    query = query.orderBy('date', descending: true);

    return query.snapshots();
  }

  Future<void> setBudget({
    required String uid,
    required String categoryId,
    required String categoryName,
    required double limit,
    required DateTime month,
  }) async {
    final monthString =
        "${month.year}-${month.month.toString().padLeft(2, '0')}";
    final budgetDocId = "${uid}_${categoryId}_$monthString";

    final docRef = _firestore.collection('budgets').doc(budgetDocId);

    await docRef.set({
      'uid': uid,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'limit': limit,
      'month': monthString,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 🔽 --- THIS FUNCTION IS NOW FIXED --- 🔽
  Future<void> addCategory({
    required String uid,
    required String name,
    required String type,
    required String iconString,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    // The complex query that was failing has been removed.
    // We now add the category directly to fix the PERMISSION_DENIED error.
    await _firestore.collection('categories').add({
      'name': trimmedName,
      'type': type,
      'owner': uid,
      'icon': iconString,
    });
  }
}
