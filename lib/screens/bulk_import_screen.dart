import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import '../models/question.dart';
import '../services/content_service.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  String? _excelPath;
  String? _imagesFolderPath;
  bool _isImporting = false;
  int _processed = 0;
  int _total = 0;
  List<String> _errors = [];
  bool _finished = false;

  Future<void> _pickExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _excelPath = result.files.single.path);
    }
  }

  Future<void> _pickImagesFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      setState(() => _imagesFolderPath = path);
    }
  }

  Future<void> _startImport() async {
    if (_excelPath == null) return;

    setState(() {
      _isImporting = true;
      _processed = 0;
      _errors = [];
      _finished = false;
    });

    final bytes = File(_excelPath!).readAsBytesSync();
    final workbook = excel_lib.Excel.decodeBytes(bytes);
    final sheet = workbook.tables[workbook.tables.keys.first]!;

    final rows = sheet.rows.skip(1).toList();
    setState(() => _total = rows.length);

    final subjects = await ContentService.getSubjectsOnce();

    for (var row in rows) {
      try {
        // Sütun sırası:
        // 0 Fənn | 1 Mövzu | 2 Sual | 3-6 Cavab1-4 | 7 DuzgunCavab | 8 Sekil
        // 9 Tip | 10 Ifadeler | 11 DuzgunIndeksler
        final subjectName = _cellText(row, 0);
        final topicName = _cellText(row, 1);
        final questionText = _cellText(row, 2);
        final cavab1 = _cellText(row, 3);
        final cavab2 = _cellText(row, 4);
        final cavab3 = _cellText(row, 5);
        final cavab4 = _cellText(row, 6);
        final cavab5 = _cellText(row, 7);
        final duzgunRaw = _cellText(row, 8);
        final imageFileName = _cellText(row, 9);
        final tip = _cellText(row, 10).toLowerCase().trim();
        final ifadelerRaw = _cellText(row, 11);
        final duzgunIndekslerRaw = _cellText(row, 12);

        if (subjectName.isEmpty || topicName.isEmpty) {
          _errors.add('Boş sətir keçildi');
          continue;
        }

        final subject = subjects.where((s) => s.name.trim() == subjectName.trim());
        if (subject.isEmpty) {
          _errors.add('Fənn tapılmadı: "$subjectName"');
          continue;
        }

        final topicId = await ContentService.findOrCreateTopic(
          subjectId: subject.first.id,
          topicName: topicName,
        );

        String? imageUrl;
        if (imageFileName.isNotEmpty && _imagesFolderPath != null) {
          final imageFile = File('$_imagesFolderPath/$imageFileName');
          if (await imageFile.exists()) {
            imageUrl = await ContentService.uploadQuestionImage(imageFile);
          } else {
            _errors.add('Şəkil tapılmadı: $imageFileName');
          }
        }

        if (tip == 'coxsecim') {
          if (questionText.isEmpty || ifadelerRaw.isEmpty || duzgunIndekslerRaw.isEmpty) {
            _errors.add('Çoxseçimli sual natamamdır: "$questionText"');
            continue;
          }
          final statements = ifadelerRaw
              .split(';')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          final correctIndices = duzgunIndekslerRaw
              .split(',')
              .map((s) => int.tryParse(s.trim()))
              .where((n) => n != null)
              .map((n) => n! - 1)
              .toList();

          if (statements.isEmpty || correctIndices.isEmpty) {
            _errors.add('Çoxseçimli sual natamamdır: "$questionText"');
            continue;
          }

          await ContentService.addQuestion(
            subjectId: subject.first.id,
            topicId: topicId,
            text: questionText,
            options: const [],
            correctIndex: 0,
            imageUrl: imageUrl,
            type: QuestionType.multiSelect,
            statements: statements,
            correctStatementIndices: correctIndices,
          );
        } else {
          if (questionText.isEmpty) {
            _errors.add('Boş sətir keçildi');
            continue;
          }
          final correctIndex = (int.tryParse(duzgunRaw) ?? 1) - 1;
          await ContentService.addQuestion(
            subjectId: subject.first.id,
            topicId: topicId,
            text: questionText,
            options: [cavab1, cavab2, cavab3, cavab4],
            correctIndex: correctIndex,
            imageUrl: imageUrl,
          );
        }
      } catch (e) {
        _errors.add('Xəta: $e');
      }

      setState(() => _processed++);
    }

    setState(() {
      _isImporting = false;
      _finished = true;
    });
  }

  String _cellText(List<excel_lib.Data?> row, int index) {
    if (index >= row.length || row[index] == null) return '';
    return row[index]!.value?.toString().trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Toplu yüklə')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _pickExcel,
              icon: const Icon(Icons.table_chart),
              label: Text(_excelPath == null
                  ? 'Excel faylı seç'
                  : 'Seçildi: ${_excelPath!.split('/').last}'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isImporting ? null : _pickImagesFolder,
              icon: const Icon(Icons.folder),
              label: Text(_imagesFolderPath == null
                  ? 'Şəkillər qovluğu seç (məcburi deyil)'
                  : 'Seçildi: ${_imagesFolderPath!.split('/').last}'),
            ),
            const SizedBox(height: 24),
            if (_isImporting) ...[
              LinearProgressIndicator(
                value: _total > 0 ? _processed / _total : 0,
              ),
              const SizedBox(height: 8),
              Text('$_processed / $_total emal olunur...'),
            ],
            if (_finished) ...[
              Text(
                '${_processed - _errors.length} sual uğurla əlavə edildi',
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
              if (_errors.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${_errors.length} problem:',
                  style: const TextStyle(color: Colors.red),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _errors.length,
                    itemBuilder: (context, index) => Text(
                      '• ${_errors[index]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
            const Spacer(),
            if (!_isImporting)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _excelPath == null ? null : _startImport,
                  child: const Text('İdxala başla'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}