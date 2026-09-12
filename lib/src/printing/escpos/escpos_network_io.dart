import 'dart:io';
import 'dart:typed_data';

Future<void> sendEscposOverNetwork(
  String ip,
  int printerPort,
  List<int> bytes,
) async {
  final socket = await Socket.connect(ip, printerPort);
  try {
    socket.add(Uint8List.fromList(bytes));
    await socket.flush();
  } finally {
    await socket.close();
  }
}
