// lib/services/paket_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paket_pendakian.dart';

class PaketService {
  static const String baseUrl = 'https://696e9572d7bacd2dd71721f4.mockapi.io/api/v1';
  
  static final PaketService _instance = PaketService._internal();
  factory PaketService() => _instance;
  PaketService._internal();

  Future<List<PaketPendakian>> fetchPaketPendakian() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/packages'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PaketPendakian.fromMap(json)).toList();
      } else {
        throw Exception('Failed to load packages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<PaketPendakian?> getPaketById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/packages/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaketPendakian.fromMap(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}