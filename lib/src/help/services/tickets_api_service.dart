import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/api_service.dart';
import '../models/support_ticket_models.dart';

class TicketsApiService {
  TicketsApiService(this._dio);

  final Dio _dio;

  Future<List<SupportTicketSummary>> listTickets({
    String? status,
    bool? assignedToMe,
  }) async {
    final q = <String, dynamic>{};
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (assignedToMe != null) q['assignedToMe'] = assignedToMe;
    final res = await _dio.get<dynamic>(
      '/tickets',
      queryParameters: q.isEmpty ? null : q,
    );
    final data = _unwrapList(res.data);
    if (data == null) return [];
    final out = <SupportTicketSummary>[];
    for (final e in data) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final t = SupportTicketSummary.tryParse(m);
        if (t != null) out.add(t);
      }
    }
    return out;
  }

  static List<dynamic>? _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) return d;
      final t = raw['tickets'];
      if (t is List) return t;
    }
    return null;
  }

  Future<SupportTicketDetail?> getTicket(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/tickets/$id');
    var data = res.data;
    if (data == null) return null;
    final inner = data['data'];
    if (inner is Map) {
      data = Map<String, dynamic>.from(inner);
    }
    var detail = SupportTicketDetail.tryParse(data);
    if (detail != null && detail.messages.isEmpty) {
      final thread = await listTicketMessages(id);
      if (thread.isNotEmpty) {
        detail = SupportTicketDetail(
          id: detail.id,
          title: detail.title,
          status: detail.status,
          messages: thread,
          createdAt: detail.createdAt,
          createdById: detail.createdById,
          createdBy: detail.createdBy,
          assignments: detail.assignments,
        );
      }
    }
    return detail;
  }

  Future<List<TicketMessage>> listTicketMessages(String ticketId) async {
    final res = await _dio.get<dynamic>('/tickets/$ticketId/messages');
    final data = _unwrapList(res.data);
    if (data == null) return [];
    final out = <TicketMessage>[];
    for (final e in data) {
      if (e is Map) {
        final m = TicketMessage.tryParse(Map<String, dynamic>.from(e));
        if (m != null) out.add(m);
      }
    }
    return out;
  }

  Future<SupportTicketSummary?> createTicket({required String title}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/tickets',
      data: {'title': title},
    );
    var data = res.data;
    if (data == null) return null;
    final inner = data['data'];
    if (inner is Map) {
      data = Map<String, dynamic>.from(inner);
    }
    return SupportTicketSummary.tryParse(data);
  }

  Future<void> postTicketMessage({
    required String ticketId,
    String? content,
    String? fileUrl,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/tickets/$ticketId/messages',
      data: {
        if (content != null && content.isNotEmpty) 'content': content,
        if (fileUrl != null && fileUrl.isNotEmpty) 'fileUrl': fileUrl,
      },
    );
  }

  Future<void> updateStatus({
    required String ticketId,
    required String status,
  }) async {
    await _dio.patch<Map<String, dynamic>>(
      '/tickets/$ticketId/status',
      data: {'status': status},
    );
  }

  Future<void> assignTicket({
    required String ticketId,
    required String staffId,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/tickets/$ticketId/assign',
      data: {'staffId': staffId},
    );
  }

  Future<void> unassignTicket({
    required String ticketId,
    required String staffId,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/tickets/$ticketId/unassign',
      data: {'staffId': staffId},
    );
  }
}

final ticketsApiServiceProvider = Provider<TicketsApiService>((ref) {
  return TicketsApiService(ApiService().dio);
});
