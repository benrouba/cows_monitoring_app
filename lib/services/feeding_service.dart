import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/feeding_models.dart';

/// Thrown when the server cannot be reached or returns an unexpected error.
class ServerUnreachableException implements Exception {}

/// Thrown when /feeding/group responds 422 (stock insufficient).
class InfeasibleStockException implements Exception {}

class FeedingService {
  static const FeedingService instance = FeedingService._();
  const FeedingService._();

  Future<Map<String, dynamic>> _post(
    String baseUrl,
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$path');
      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
      if (resp.statusCode == 422) {
        throw InfeasibleStockException();
      }
      throw ServerUnreachableException();
    } on InfeasibleStockException {
      rethrow;
    } catch (_) {
      throw ServerUnreachableException();
    }
  }

  Future<IndividualRationResult> postIndividual(
    String baseUrl,
    FeedingCow cow,
  ) async {
    final json = await _post(baseUrl, '/feeding/individual', {
      'name': cow.name,
      'profile': cow.profile,
      'milk_yield_kg': cow.milkYieldKg,
    });
    return IndividualRationResult.fromJson(json);
  }

  Future<GroupRationResult> postGroup(
    String baseUrl,
    List<FeedingCow> cows,
    Map<String, double> stockKg,
  ) async {
    final json = await _post(baseUrl, '/feeding/group', {
      'cows': cows.map((c) => c.toJson()).toList(),
      'stock_kg': stockKg,
    });
    return GroupRationResult.fromJson(json);
  }

  Future<SmartResult> postSmart(
    String baseUrl,
    int nGroups,
    List<FeedingCow> cows,
  ) async {
    final json = await _post(baseUrl, '/feeding/smart', {
      'n_groups': nGroups,
      'cows': cows.map((c) => c.toJson()).toList(),
    });
    return SmartResult.fromJson(json);
  }
}
