import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ContentService {
  static final _db = FirebaseFirestore.instance;

  // ---------- ПРЕДМЕТЫ ----------

  static Stream<List<Subject>> getSubjects() {
    return _db
        .collection('subjects')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Subject.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  static Future<String> uploadQuestionImage(File imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child('question_images/$fileName');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  static Future<void> addSubject({
    required String name,
    required String icon,
    required int order,
  }) async {
    await _db.collection('subjects').add({
      'name': name,
      'icon': icon,
      'order': order,
    });
  }

  static Future<void> deleteSubject(String subjectId) async {
    // Удаляем все темы и их вопросы внутри предмета перед удалением самого предмета
    final topics = await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .get();

    for (var topicDoc in topics.docs) {
      final questions = await topicDoc.reference.collection('questions').get();
      for (var q in questions.docs) {
        await q.reference.delete();
      }
      await topicDoc.reference.delete();
    }

    await _db.collection('subjects').doc(subjectId).delete();
  }

  static Future<List<Question>> getAllQuestionsForSubject(String subjectId) async {
    final topicsSnapshot = await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .get();

    final List<Question> allQuestions = [];

    for (var topicDoc in topicsSnapshot.docs) {
      final questionsSnapshot = await topicDoc.reference.collection('questions').get();
      for (var qDoc in questionsSnapshot.docs) {
        allQuestions.add(Question.fromFirestore(qDoc.id, qDoc.data()));
      }
    }

    return allQuestions;
  }

  // ---------- ТЕМЫ ----------

  static Stream<List<Topic>> getTopics(String subjectId) {
    return _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Topic.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  static Future<void> addTopic({
    required String subjectId,
    required String name,
    required int order,
  }) async {
    await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .add({'name': name, 'order': order});
  }

  static Future<void> deleteTopic(String subjectId, String topicId) async {
    final questions = await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .doc(topicId)
        .collection('questions')
        .get();

    for (var q in questions.docs) {
      await q.reference.delete();
    }

    await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .doc(topicId)
        .delete();
  }

  // ---------- ВОПРОСЫ ----------

  static Stream<List<Question>> getQuestions(String subjectId, String topicId) {
    return _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .doc(topicId)
        .collection('questions')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Question.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  static Future<void> addQuestion({
    required String subjectId,
    required String topicId,
    required String text,
    required List<String> options,
    required int correctIndex,
    String? imageUrl,
  }) async {
    await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .doc(topicId)
        .collection('questions')
        .add({
      'text': text,
      'options': options,
      'correctIndex': correctIndex,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
  }

  static Future<void> deleteQuestion(
      String subjectId, String topicId, String questionId) async {
    await _db
        .collection('subjects')
        .doc(subjectId)
        .collection('topics')
        .doc(topicId)
        .collection('questions')
        .doc(questionId)
        .delete();
  }
}