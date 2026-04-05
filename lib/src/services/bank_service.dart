import 'package:dio/dio.dart';

import '../services/api_service.dart';
import '../models/bank_model.dart';

/// Wraps a paginated list response from the backend.
class PaginatedBanks {
  const PaginatedBanks({
    required this.data,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<BankModel> data;
  final int total;
  final int skip;
  final int take;

  bool get hasMore => skip + data.length < total;
  int get currentPage => (skip ~/ take) + 1;
  int get totalPages => (total / take).ceil();
}

class BankService {
  BankService() : _dio = ApiService().dio;
  final Dio _dio;

  Future<PaginatedBanks> fetchBanks({int skip = 0, int take = 20}) async {
    final resp = await _dio.get(
      '/banks',
      queryParameters: {'skip': skip, 'take': take},
    );
    final body = resp.data as Map<String, dynamic>;

    final rawList = body['data'] as List;
    final total = body['total'] as int;
    final skipFromApi = body['skip'] as int;
    final takeFromApi = body['take'] as int;

    return PaginatedBanks(
      data: rawList
          .map((e) => BankModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
      skip: skipFromApi,
      take: takeFromApi,
    );
  }

  Future<BankModel> createBank(String name, String accountNumber) async {
    final resp = await _dio.post(
      '/banks',
      data: {'name': name, 'accountNumber': accountNumber},
    );
    return BankModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<BankModel> updateBank(
    String id,
    String name,
    String accountNumber,
  ) async {
    final resp = await _dio.put(
      '/banks/$id',
      data: {'name': name, 'accountNumber': accountNumber},
    );
    return BankModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteBank(String id) async {
    await _dio.delete('/banks/$id');
  }
}
