import '../models/question.dart';

final List<Subject> mockSubjects = [
  Subject(
    id: 'constitution',
    name: 'Konstitusiya',
    icon: '📜',
    questions: [
      Question(
        id: 'c1',
        text: 'Azərbaycan Respublikasının Konstitusiyası neçənci ildə qəbul edilib?',
        options: ['1991', '1995', '2002', '2009'],
        correctIndex: 1,
      ),
      Question(
        id: 'c2',
        text: 'Konstitusiyaya əsasən dövlət dili hansıdır?',
        options: ['Rus dili', 'Azərbaycan dili', 'İngilis dili', 'Türk dili'],
        correctIndex: 1,
      ),
    ],
  ),
  Subject(
    id: 'logic',
    name: 'Məntiq',
    icon: '🏛️',
    questions: [
      Question(
        id: 'h1',
        text: 'Azərbaycan Xalq Cümhuriyyəti neçənci ildə yaradılıb?',
        options: ['1917', '1918', '1920', '1922'],
        correctIndex: 1,
      ),
    ],
  ),
  Subject(
    id: 'informatika',
    name: 'Informatika',
    icon: '🗣️',
    questions: [
      Question(
        id: 'i1',
        text: '"Kitab" sözünün cəm forması hansıdır?',
        options: ['Kitablar', 'Kitabçı', 'Kitablı', 'Kitabsız'],
        correctIndex: 0,
      ),
    ],
  ),
  Subject(
    id: 'language',
    name: 'Azərbaycan dili',
    icon: '🗣️',
    questions: [
      Question(
        id: 'l1',
        text: '"Kitab" sözünün cəm forması hansıdır?',
        options: ['Kitablar', 'Kitabçı', 'Kitablı', 'Kitabsız'],
        correctIndex: 0,
      ),
    ],
  ),
];