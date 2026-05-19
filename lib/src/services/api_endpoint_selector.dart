import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/server_time_model.dart';
import 'server_time_service.dart';

/// Result of probing a candidate API origin with `GET /server-time`.
class ApiEndpointProbeResult {
  const ApiEndpointProbeResult({
    required this.baseUrl,
    required this.serverTime,
    required this.latency,
  });

  final String baseUrl;
  final ServerTimePayload serverTime;
  final Duration latency;
}

/// Races [candidates] in parallel and returns the first successful `/server-time`.
class ApiEndpointSelector {
  ApiEndpointSelector._();

  static const _probeTimeout = Duration(seconds: 5);

  static Future<ApiEndpointProbeResult> selectFastest(
    List<String> candidates,
  ) async {
    if (candidates.isEmpty) {
      throw StateError('No API candidate base URLs configured.');
    }

    final completer = Completer<ApiEndpointProbeResult>();
    final failures = <String>[];
    var pending = candidates.length;

    for (final baseUrl in candidates) {
      unawaited(
        _probe(baseUrl).then((result) {
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        }).catchError((Object e) {
          failures.add('$baseUrl: $e');
          pending--;
          if (pending == 0 && !completer.isCompleted) {
            completer.completeError(
              Exception(
                'None of the configured servers responded.\n'
                '${failures.join('\n')}',
              ),
            );
          }
        }),
      );
    }

    return completer.future;
  }

  static Future<ApiEndpointProbeResult> _probe(String baseUrl) async {
    final normalized =
        baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final dio = Dio(
      BaseOptions(
        baseUrl: normalized,
        connectTimeout: _probeTimeout,
        receiveTimeout: _probeTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final started = DateTime.now();
    try {
      final resp = await dio.get<Map<String, dynamic>>(ServerTimeService.path);
      final data = resp.data;
      if (data == null) {
        throw const FormatException('server-time: empty response body');
      }
      final payload = ServerTimePayload.fromJson(data);
      final latency = DateTime.now().difference(started);
      if (kDebugMode) {
        debugPrint(
          'ApiEndpointSelector: $normalized responded in ${latency.inMilliseconds}ms',
        );
      }
      return ApiEndpointProbeResult(
        baseUrl: normalized,
        serverTime: payload,
        latency: latency,
      );
    } on DioException catch (e) {
      throw Exception(e.message ?? e.type.name);
    } finally {
      dio.close(force: true);
    }
  }
}
