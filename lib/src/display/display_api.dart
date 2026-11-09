import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/staff_registration_options.dart';
import '../services/api_service.dart';

const _kSelectedLaneKey = 'display_board_lane';

Future<String?> loadSelectedDisplayLane() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(_kSelectedLaneKey)?.trim().toUpperCase();
  if (value == null) return null;
  final known = kDisplayLaneOptions.any((option) => option.$1 == value);
  return known ? value : null;
}

Future<void> saveSelectedDisplayLane(String lane) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kSelectedLaneKey, lane);
}

Future<void> clearSelectedDisplayLane() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kSelectedLaneKey);
}

class DisplayBoardRow {
  const DisplayBoardRow({
    required this.lane,
    required this.ticket,
    required this.displayName,
    required this.place,
    required this.waitingSince,
  });

  final String lane;
  final String ticket;
  final String displayName;
  final String place;
  final DateTime? waitingSince;

  factory DisplayBoardRow.fromJson(Map<String, dynamic> json) {
    return DisplayBoardRow(
      lane: json['lane']?.toString() ?? '',
      ticket: json['ticket']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'Patient',
      place: json['place']?.toString() ?? '',
      waitingSince: DateTime.tryParse(json['waitingSince']?.toString() ?? ''),
    );
  }
}

class DisplayBoardSnapshot {
  const DisplayBoardSnapshot({
    required this.lane,
    required this.rows,
  });

  final String lane;
  final List<DisplayBoardRow> rows;

  factory DisplayBoardSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['rows'];
    final rows = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => DisplayBoardRow.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <DisplayBoardRow>[];
    return DisplayBoardSnapshot(
      lane: json['lane']?.toString() ?? '',
      rows: rows,
    );
  }
}

class DisplayVideoItem {
  const DisplayVideoItem({
    required this.id,
    required this.title,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final bool isActive;
  final int sortOrder;

  factory DisplayVideoItem.fromJson(Map<String, dynamic> json) {
    return DisplayVideoItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Video',
      isActive: json['isActive'] != false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class DisplayApi {
  DisplayApi({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  Future<DisplayBoardSnapshot> fetchBoard(String lane) async {
    final resp = await _dio.get<dynamic>(
      '/display/board',
      queryParameters: {'lane': lane},
    );
    final data = resp.data;
    if (data is Map) {
      return DisplayBoardSnapshot.fromJson(Map<String, dynamic>.from(data));
    }
    return const DisplayBoardSnapshot(lane: '', rows: []);
  }

  Future<List<DisplayVideoItem>> fetchActiveVideos() async {
    final resp = await _dio.get<dynamic>('/display/videos');
    return _videos(resp.data);
  }

  Future<List<DisplayVideoItem>> fetchManagedVideos() async {
    final resp = await _dio.get<dynamic>('/display/videos/manage');
    return _videos(resp.data);
  }

  String fileUrl(String id) {
    final base = _dio.options.baseUrl;
    final trimmed = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$trimmed/display/videos/$id/file';
  }

  Future<DisplayVideoItem> uploadVideo(PlatformFile file, {String? title}) async {
    final name = file.name.trim().isEmpty ? 'video.mp4' : file.name.trim();
    final MultipartFile part;
    if (file.bytes != null) {
      part = MultipartFile.fromBytes(file.bytes!, filename: name);
    } else if (file.path != null && file.path!.isNotEmpty) {
      part = await MultipartFile.fromFile(file.path!, filename: name);
    } else {
      throw StateError('Selected file has no data');
    }
    final trimmedTitle = title?.trim();
    final titleValue =
        trimmedTitle == null || trimmedTitle.isEmpty ? null : trimmedTitle;
    final resp = await _dio.post<dynamic>(
      '/display/videos',
      data: FormData.fromMap({
        'file': part,
        'title': ?titleValue,
      }),
      options: Options(
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 2),
        contentType: 'multipart/form-data',
      ),
    );
    final data = resp.data;
    if (data is Map) {
      return DisplayVideoItem.fromJson(Map<String, dynamic>.from(data));
    }
    throw StateError('Upload did not return a video');
  }

  Future<void> updateVideo(
    String id, {
    String? title,
    bool? isActive,
  }) async {
    await _dio.patch<dynamic>(
      '/display/videos/$id',
      data: {
        'title': ?title,
        'isActive': ?isActive,
      },
    );
  }

  Future<List<DisplayVideoItem>> reorder(List<String> orderedIds) async {
    final resp = await _dio.patch<dynamic>(
      '/display/videos/order',
      data: {'orderedIds': orderedIds},
    );
    return _videos(resp.data);
  }

  Future<void> deleteVideo(String id) async {
    await _dio.delete<dynamic>('/display/videos/$id');
  }

  List<DisplayVideoItem> _videos(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => DisplayVideoItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

String displayLaneTitle(String lane) {
  switch (lane.toUpperCase()) {
    case 'TRIAGE':
      return 'Nurse triage';
    case 'CONSULTATION':
      return 'Consultation';
    case 'PHARMACY':
      return 'Pharmacy';
    case 'RADIOLOGY':
      return 'Radiology';
    case 'LAB':
      return 'Laboratory';
    case 'ALL':
      return 'Waiting patients';
    default:
      return 'Waiting';
  }
}

String waitingDurationLabel(DateTime? since, DateTime now) {
  if (since == null) return '';
  final mins = now.difference(since.toLocal()).inMinutes;
  if (mins < 1) return 'Just arrived';
  if (mins < 60) return '$mins min';
  final hours = mins ~/ 60;
  final rest = mins % 60;
  return '${hours}h ${rest}m';
}
