import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  static Stream<QuerySnapshot> getProgressStream({String? userId}) {
    final uid = userId ?? _userId;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
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

  static Stream<QuerySnapshot> getResultsStream({String? userId}) {
    final uid = userId ?? _userId;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('results')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  static Future<void> saveInProgress({
    required String subjectId,
    required String topicId,
    required String subjectName,
    required String topicName,
    required List<String> questionIds,
    required int currentIndex,
    required List<int?> answers,
    required int correctCount,
  }) async {
    final userId = _userId;
    if (userId == null) return;
    await _db
        .collection('users')
        .doc(userId)
        .collection('inProgress')
        .doc('${subjectId}_$topicId')
        .set({
      'subjectId': subjectId,
      'topicId': topicId,
      'subjectName': subjectName,
      'topicName': topicName,
      'questionIds': questionIds,
      'currentIndex': currentIndex,
      'answers': answers,
      'correctCount': correctCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getInProgress(
      String subjectId, String topicId) async {
    final userId = _userId;
    if (userId == null) return null;
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('inProgress')
        .doc('${subjectId}_$topicId')
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  static Future<List<Map<String, dynamic>>> getWrongQuestionsForTopic({
    required String subjectId,
    required String topicId,
    String? userId,
  }) async {
    final uid = userId ?? _userId;
    if (uid == null) return [];

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('results')
        .where('subjectId', isEqualTo: subjectId)
        .where('topicId', isEqualTo: topicId)
        .get();

    final Map<String, Map<String, dynamic>> wrongByText = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final questions = List<Map<String, dynamic>>.from(
        (data['questions'] as List).map((q) => Map<String, dynamic>.from(q)),
      );
      for (var q in questions) {
        if (q['selectedIndex'] != q['correctIndex']) {
          wrongByText[q['text']] = q;
        }
      }
    }
    return wrongByText.values.toList();
  }

  static Stream<QuerySnapshot> getInProgressStream() {
    final userId = _userId;
    if (userId == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(userId)
        .collection('inProgress')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> clearInProgress(String subjectId, String topicId) async {
    final userId = _userId;
    if (userId == null) return;
    await _db
        .collection('users')
        .doc(userId)
        .collection('inProgress')
        .doc('${subjectId}_$topicId')
        .delete();
  }
}
