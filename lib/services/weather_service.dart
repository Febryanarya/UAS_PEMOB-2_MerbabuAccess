import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = 'a75515134c6f98d66a1ee295202948fb';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Koordinat Gunung Merbabu (fix & aman)
  static const double _latitude = -7.4547;
  static const double _longitude = 110.4417;

  Future<WeatherData> fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather'
          '?lat=$_latitude'
          '&lon=$_longitude'
          '&appid=$_apiKey'
          '&units=metric'
          '&lang=id',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (_) {
      return _getMockWeatherData();
    }
  }

  WeatherData _getMockWeatherData() {
    return WeatherData(
      location: 'Gunung Merbabu',
      temperature: 18.5,
      feelsLike: 17.8,
      tempMin: 16.2,
      tempMax: 20.1,
      humidity: 75,
      pressure: 1013,
      condition: 'Clouds',
      description: 'berawan',
      icon: '04d',
      windSpeed: 3.1,
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }

  String getWeatherAdvice(WeatherData weather) {
    if (weather.isStormy) {
      return '🚨 BAHAYA! Ada badai petir. Pendakian tidak disarankan.';
    }
    if (weather.isRainy) {
      return '⚠️ Hujan. Jalur licin, siapkan jas hujan.';
    }
    if (weather.isWindy) {
      return '💨 Angin kencang. Perhatikan tenda dan perlengkapan.';
    }
    if (weather.isCold) {
      return '❄️ Suhu dingin. Gunakan perlengkapan hangat.';
    }
    if (weather.isGoodWeather) {
      return '✅ Cuaca bagus untuk pendakian.';
    }
    return 'ℹ️ Cuaca normal. Tetap waspada.';
  }
}
