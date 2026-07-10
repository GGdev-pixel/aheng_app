import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProgressService {
  static final _db = FirebaseFirestore.instance;

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  static Future<void> saveQuizResult({
    required String subjectId,
    required int answered,
    required int correct,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(subjectId);

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      final prevAnswered = data['answered'] ?? 0;
      final prevCorrect = data['correct'] ?? 0;
      await docRef.update({
        'answered': prevAnswered + answered,
        'correct': prevCorrect + correct,
      });
    } else {
      await docRef.set({
        'answered': answered,
        'correct': correct,
      });
    }
  }

  static Stream<QuerySnapshot> getProgressStream() {
    final userId = _userId;
    if (userId == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .snapshots();
  }
}