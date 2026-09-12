import 'dart:io';

Future<void> writeBytesToFilePath(String path, List<int> bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}
