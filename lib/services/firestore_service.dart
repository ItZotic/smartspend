import 'package:cloud_firestore/cloud_firestore.dart';

class _DefaultCategory {
  final String id;
  final String name;
  final String icon;
  final int color;

  const _DefaultCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

const List<_DefaultCategory> _defaultExpenseCategories = [
  _DefaultCategory(
    id: 'food_dining',
    name: 'Food & Dining',
    icon: 'restaurant',
    color: 0xFF2979FF,
  ),
  _DefaultCategory(
    id: 'transportation',
    name: 'Transportation',
    icon: 'directions_bus_filled_outlined',
    color: 0xFF455A64,
  ),
  _DefaultCategory(
    id: 'bills',
    name: 'Bills',
    icon: 'receipt_long_outlined',
    color: 0xFF00897B,
  ),
  _DefaultCategory(
    id: 'groceries',
    name: 'Groceries',
    icon: 'shopping_cart_outlined',
    color: 0xFFFF7043,
  ),
  _DefaultCategory(
    id: 'entertainment',
    name: 'Entertainment',
    icon: 'movie_outlined',
    color: 0xFFE53935,
  ),
  _DefaultCategory(
    id: 'shopping',
    name: 'Shopping',
    icon: 'shopping_bag_outlined',
    color: 0xFFFF9800,
  ),
  _DefaultCategory(
    id: 'clothing',
    name: 'Clothing',
    icon: 'checkroom',
    color: 0xFF8E24AA,
  ),
];

// 🔹 Default INCOME categories – match your Income list
const List<_DefaultCategory> _defaultIncomeCategories = [
  _DefaultCategory(
    id: 'salary',
    name: 'Salary',
    icon: 'paid',
    color: 0xFF2E7D32,
  ),
  _DefaultCategory(
    id: 'awards',
    name: 'Awards',
    icon: 'military_tech',
    color: 0xFF6A1B9A,
  ),
  _DefaultCategory(
    id: 'grants',
    name: 'Grants',
    icon: 'school',
    color: 0xFF3949AB,
  ),
  _DefaultCategory(
    id: 'rental',
    name: 'Rental',
    icon: 'home_work',
    color: 0xFF00897B,
  ),
  _DefaultCategory(
    id: 'investments',
    name: 'Investments',
    icon: 'trending_up',
    color: 0xFFF9A825,
  ),
  _DefaultCategory(
    id: 'refunds',
    name: 'Refunds',
    icon: 'replay',
    color: 0xFF039BE5,
  ),
  _DefaultCategory(
    id: 'gifts',
    name: 'Gifts',
    icon: 'card_giftcard',
    color: 0xFFD81B60,
  ),
  _DefaultCategory(
    id: 'interest',
    name: 'Interest',
    icon: 'savings',
    color: 0xFF5D4037,
  ),
];

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

  /// Seed BOTH default income + expense categories into the top-level `categories` collection.
  Future<void> ensureDefaultCategories({required String uid}) async {
    Future<void> ensureForList(
      List<_DefaultCategory> list,
      String type,
    ) async {
      for (final category in list) {
        final docRef =
            _firestore.collection('categories').doc('${uid}_${category.id}');
        final snapshot = await docRef.get();
        if (snapshot.exists) continue;

        await docRef.set({
          'name': category.name,
          'type': type, // 'income' or 'expense'
          'owner': uid,
          'icon': category.icon,
          'color': category.color,
          'isDefault': true,
        });
      }
    }

    await ensureForList(_defaultExpenseCategories, 'expense');
    await ensureForList(_defaultIncomeCategories, 'income');
  }

  /// Generic stream of user categories by type, from top-level `categories`.
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

  /// Convenience wrapper for expenses.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamExpenseCategories(
      String uid) {
    return streamUserCategories(uid: uid, type: 'expense');
  }

  /// Main API used by Add Transaction / others.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCategoriesByType({
    required String uid,
    required String type,
  }) {
    return streamUserCategories(uid: uid, type: type);
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
    String? accountName,
  }) {
    Query<Map<String, dynamic>> query =
        _firestore.collection('transactions').where('uid', isEqualTo: uid);

    if (accountName != null) {
      query = query.where('accountName', isEqualTo: accountName);
    }

    if (start != null) {
      query = query.where(
        'date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }

    if (end != null) {
      query = query.where(
        'date',
        isLessThanOrEqualTo: Timestamp.fromDate(end),
      );
    }

    query = query.orderBy('date', descending: true);

    return query.snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamAccounts({
    required String uid,
  }) {
    return _firestore
        .collection('accounts')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt')
        .snapshots();
  }

  Future<void> updateTransaction({
    required String uid,
    required String transactionId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('transactions').doc(transactionId).update(data);
  }

  Future<void> setBudgetLimit({
    required String uid,
    required String categoryName,
    required int year,
    required int month,
    required double limit,
  }) async {
    final docId =
        '${uid}_${categoryName}_${year}_${month.toString().padLeft(2, '0')}';
    final docRef = _firestore.collection('categoryBudgets').doc(docId);
    final data = {
      'uid': uid,
      'categoryName': categoryName,
      'year': year,
      'month': month,
      'limit': limit,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final existing = await docRef.get();
    if (existing.exists) {
      await docRef.update(data);
    } else {
      await docRef.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> setMonthlyBudget({
    required String uid,
    required int year,
    required int month,
    required double amount,
  }) async {
    final docId = "${uid}_${year}_${month.toString().padLeft(2, '0')}";
    final docRef = _firestore.collection('budgets').doc(docId);

    final existingDoc = await docRef.get();
    final data = {
      'uid': uid,
      'year': year,
      'month': month,
      'amount': amount,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existingDoc.exists) {
      await docRef.update(data);
    } else {
      await docRef.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<double?> getMonthlyBudget({
    required String uid,
    required int year,
    required int month,
  }) async {
    final docId = "${uid}_${year}_${month.toString().padLeft(2, '0')}";
    final snapshot =
        await _firestore.collection('budgets').doc(docId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();
    return (data?['amount'] as num?)?.toDouble();
  }

  Future<Map<String, double>> getCategoryBudgetsForMonth({
    required String uid,
    required int year,
    required int month,
  }) async {
    final snapshot = await _firestore
        .collection('categoryBudgets')
        .where('uid', isEqualTo: uid)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .get();

    final budgets = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final categoryName = data['categoryName'] as String?;
      final limit = (data['limit'] as num?)?.toDouble();
      if (categoryName != null && limit != null) {
        budgets[categoryName] = limit;
      }
    }

    return budgets;
  }

  Future<Map<String, double>> getSpentByCategoryForMonth({
    required String uid,
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final snapshot = await _firestore
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    final spent = <String, double>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final categoryName = data['category'] as String?;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

      if (categoryName != null) {
        spent.update(
          categoryName,
          (current) => current + amount.abs(),
          ifAbsent: () => amount.abs(),
        );
      }
    }

    return spent;
  }

  Future<void> setMonthlyBudget({
    required String uid,
    required int year,
    required int month,
    required double amount,
  }) async {
    final docId = "${uid}_${year}_${month.toString().padLeft(2, '0')}";
    final docRef = _firestore.collection('budgets').doc(docId);

    final existingDoc = await docRef.get();
    final data = {
      'uid': uid,
      'year': year,
      'month': month,
      'amount': amount,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existingDoc.exists) {
      await docRef.update(data);
    } else {
      await docRef.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<double?> getMonthlyBudget({
    required String uid,
    required int year,
    required int month,
  }) async {
    final docId = "${uid}_${year}_${month.toString().padLeft(2, '0')}";
    final snapshot =
        await _firestore.collection('budgets').doc(docId).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();
    return (data?['amount'] as num?)?.toDouble();
  }

  Future<void> setMonthlyBudget({
    required String uid,
    required int year,
    required int month,
    required double amount,
  }) async {
    final docId = "${uid}_$year${month.toString().padLeft(2, '0')}";
    final docRef = _firestore.collection('budgets').doc(docId);

    final existingDoc = await docRef.get();
    final data = {
      'uid': uid,
      'year': year,
      'month': month,
      'amount': amount,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (existingDoc.exists) {
      await docRef.update(data);
    } else {
      await docRef.set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMonthlyBudget({
    required String uid,
    required int year,
    required int month,
  }) {
    return _firestore
        .collection('budgets')
        .where('uid', isEqualTo: uid)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .limit(1)
        .snapshots();
  }

  Future<void> addCategory({
    required String uid,
    required String name,
    required String type,
    required String iconString,
    int? colorValue,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Category name cannot be empty');
    }

    await _firestore.collection('categories').add({
      'name': trimmedName,
      'type': type,
      'owner': uid,
      'icon': iconString,
      'color': colorValue ?? 0xFF2979FF,
      'iconIndex': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> addUserCategory({
    required String uid,
    required String name,
    required String type,
    required int iconIndex,
    required String iconId,
    required int iconColor,
  }) {
    final trimmedName = name.trim();

    return _firestore.collection('categories').add({
      'name': trimmedName,
      'type': type,
      'owner': uid,
      'iconIndex': iconIndex,
      'iconId': iconId,
      'iconColor': iconColor,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCategory({
    required String uid,
    required String categoryId,
    String? name,
    int? iconIndex,
    String? iconId,
    int? iconColor,
  }) async {
    final updates = <String, dynamic>{
      'owner': uid,
    };

    if (name != null) {
      updates['name'] = name.trim();
    }

    if (iconIndex != null) {
      updates['iconIndex'] = iconIndex;
    }

    if (iconId != null) {
      updates['iconId'] = iconId;
    }

    if (iconColor != null) {
      updates['iconColor'] = iconColor;
    }

    await _firestore
        .collection('categories')
        .doc(categoryId)
        .set(updates, SetOptions(merge: true));
  }

  Future<void> deleteCategory({
    required String uid,
    required String categoryId,
  }) {
    return _firestore.collection('categories').doc(categoryId).delete();
  }
}
