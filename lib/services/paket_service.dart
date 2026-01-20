import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paket_pendakian.dart';

class PaketService {
  static const String baseUrl = 'https://696e9572d7bacd2dd71721f4.mockapi.io/api/v1';

  Future<List<PaketPendakian>> fetchPaketPendakian() async {
    final response = await http.get(Uri.parse('$baseUrl/packages'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => PaketPendakian.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data paket pendakian');
    }
  }
}