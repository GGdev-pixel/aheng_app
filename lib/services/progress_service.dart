import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/progress_service.dart';

class ProgressService {
  static final _db = FirebaseFirestore.instance;

  static String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  static Future<void> saveQuizResult({
    required String subjectId,
    required String topicId,
    required int answered,
    required int correct,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc('${subjectId}_$topicId');

    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data()!;
      final prevAnswered = data['answered'] ?? 0;
      final prevCorrect = data['correct'] ?? 0;
      await docRef.update({
        'answered': prevAnswered + answered,
        'correct': prevCorrect + correct,
        'subjectId': subjectId,
        'topicId': topicId,
      });
    } else {
      await docRef.set({
        'answered': answered,
        'correct': correct,
        'subjectId': subjectId,
        'topicId': topicId,
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

  static Future<void> saveQuizAttempt({
    required String subjectId,
    required String subjectName,
    required String topicId,
    required String topicName,
    required List<Map<String, dynamic>> questionsData,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final correct = questionsData
        .where((q) => q['selectedIndex'] == q['correctIndex'])
        .length;

    await _db.collection('users').doc(userId).collection('results').add({
      'subjectId': subjectId,
      'subjectName': subjectName,
      'topicId': topicId,
      'topicName': topicName,
      'answered': questionsData.length,
      'correct': correct,
      'questions': questionsData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getResultsStream() {
    final userId = _userId;
    if (userId == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(userId)
        .collection('results')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}