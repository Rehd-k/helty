import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/theatre_models.dart';
import '../services/theatre_api_service.dart';

final theatreApiServiceProvider = Provider<TheatreApiService>((ref) {
  return TheatreApiService();
});

class SurgeryRequestsParams {
  const SurgeryRequestsParams({
    this.encounterId,
    this.patientId,
    this.status,
    this.from,
    this.to,
    this.skip = 0,
    this.take = 100,
  });

  final String? encounterId;
  final String? patientId;
  final SurgeryRequestStatus? status;
  final DateTime? from;
  final DateTime? to;
  final int skip;
  final int take;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurgeryRequestsParams &&
          runtimeType == other.runtimeType &&
          encounterId == other.encounterId &&
          patientId == other.patientId &&
          status == other.status &&
          from == other.from &&
          to == other.to &&
          skip == other.skip &&
          take == other.take;

  @override
  int get hashCode =>
      Object.hash(encounterId, patientId, status, from, to, skip, take);
}

class TheatreSchedulesParams {
  const TheatreSchedulesParams({
    required this.from,
    required this.to,
    this.theatreRoomId,
    this.surgeonId,
    this.skip = 0,
    this.take = 100,
  });

  final DateTime from;
  final DateTime to;
  final String? theatreRoomId;
  final String? surgeonId;
  final int skip;
  final int take;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TheatreSchedulesParams &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          theatreRoomId == other.theatreRoomId &&
          surgeonId == other.surgeonId &&
          skip == other.skip &&
          take == other.take;

  @override
  int get hashCode =>
      Object.hash(from, to, theatreRoomId, surgeonId, skip, take);
}

final surgeryRequestsProvider = FutureProvider.autoDispose
    .family<SurgeryRequestsResponse, SurgeryRequestsParams>((ref, params) {
      return ref.watch(theatreApiServiceProvider).getSurgeryRequests(
        encounterId: params.encounterId,
        patientId: params.patientId,
        status: params.status,
        fromDate: params.from,
        toDate: params.to,
        skip: params.skip,
        take: params.take,
      );
    });

final surgeryRequestsForEncounterProvider = FutureProvider.autoDispose
    .family<List<SurgeryRequest>, String>((ref, encounterId) {
      return ref
          .watch(theatreApiServiceProvider)
          .getSurgeryRequestsForEncounter(encounterId);
    });

final surgeryRequestByIdProvider = FutureProvider.autoDispose
    .family<SurgeryRequest, String>((ref, id) {
      return ref.watch(theatreApiServiceProvider).getSurgeryRequestById(id);
    });

final theatreCaseProvider = FutureProvider.autoDispose
    .family<SurgeryRequest, String>((ref, surgeryRequestId) {
      return ref.watch(theatreApiServiceProvider).getCase(surgeryRequestId);
    });

final theatreSchedulesProvider = FutureProvider.autoDispose
    .family<TheatreSchedulesResponse, TheatreSchedulesParams>((ref, params) {
      return ref.watch(theatreApiServiceProvider).getSchedules(
        fromDate: params.from,
        toDate: params.to,
        theatreRoomId: params.theatreRoomId,
        surgeonId: params.surgeonId,
        skip: params.skip,
        take: params.take,
      );
    });

final theatreRoomsProvider = FutureProvider.autoDispose<List<TheatreRoom>>((
  ref,
) async {
  return ref.watch(theatreApiServiceProvider).getRooms();
});

void invalidateTheatreCase(WidgetRef ref, String surgeryRequestId) {
  ref.invalidate(theatreCaseProvider(surgeryRequestId));
  ref.invalidate(surgeryRequestByIdProvider(surgeryRequestId));
}

void invalidateSurgeryRequests(WidgetRef ref) {
  ref.invalidate(surgeryRequestsProvider);
  ref.invalidate(surgeryRequestsForEncounterProvider);
}

void invalidateTheatreSchedules(WidgetRef ref) {
  ref.invalidate(theatreSchedulesProvider);
}

void invalidateTheatreRooms(WidgetRef ref) {
  ref.invalidate(theatreRoomsProvider);
}
