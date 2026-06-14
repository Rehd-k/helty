import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Whether [content] is Quill delta JSON stored in a TEXT column.
bool isQuillDeltaJson(String content) {
  final t = content.trimLeft();
  if (t.isEmpty) return false;
  if (t.startsWith('[')) return true;
  return t.startsWith('{') && t.contains('"insert"');
}

Document? _documentFromStoredContent(String? content) {
  final raw = content?.trim();
  if (raw == null || raw.isEmpty) return null;

  if (isQuillDeltaJson(raw)) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return Document.fromJson(
          decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        );
      }
      if (decoded is Map) {
        return Document.fromJson([Map<String, dynamic>.from(decoded)]);
      }
    } catch (_) {}
    return null;
  }

  return Document()..insert(0, raw);
}

/// Build a [QuillController] for editing or read-only display.
QuillController quillControllerFromStoredContent(String? content) {
  final doc = _documentFromStoredContent(content);
  if (doc != null) {
    return QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }
  return QuillController.basic(config: QuillControllerConfig());
}

/// Plain-text preview for lists, validation, and handover summaries.
String plainTextFromStoredContent(String? content) {
  final raw = content?.trim();
  if (raw == null || raw.isEmpty) return '';

  if (isQuillDeltaJson(raw)) {
    final doc = _documentFromStoredContent(raw);
    if (doc != null) {
      return doc.toPlainText().trim();
    }
    return '';
  }

  return raw;
}

/// Serialize editor state for API `content` TEXT field.
String encodeQuillContent(QuillController controller) {
  return jsonEncode(controller.document.toDelta().toJson());
}
