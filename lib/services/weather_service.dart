import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = 'a75515134c6f98d66a1ee295202948fb'; // API KEY
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const double _latitude = -7.4500;
  static const double _longitude = 110.4333;

  Future<WeatherData> fetchWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/weather?lat=$_latitude&lon=$_longitude&appid=$_apiKey&units=metric&lang=id'
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }
    } catch (e) {
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
      description: 'awan berawan',
      icon: '04d',
      windSpeed: 3.1,
      lastUpdated: DateTime.now().toString(),
    );
  }

  String getWeatherAdvice(WeatherData weather) {
    if (weather.isStormy) return '🚨 BAHAYA! Ada badai petir. Tidak disarankan pendakian.';
    if (weather.isRainy) return '⚠️ Hujan lebat. Persiapkan jas hujan dan berhati-hati di jalur licin.';
    if (weather.isWindy) return '💨 Angin kencang. Pastikan tenda dan perlengkapan aman.';
    if (weather.isCold) return '❄️ Suhu sangat dingin. Bawa sleeping bag yang cukup hangat.';
    if (weather.isGoodWeather) return '✅ Cuaca bagus untuk pendakian! Selamat mendaki!';
    return 'ℹ️ Cuaca normal. Tetap waspada dan perhatikan kondisi fisik.';
  }
}