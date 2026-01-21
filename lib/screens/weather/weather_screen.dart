import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/weather_service.dart';
import '../../models/weather_model.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late Future<WeatherData> _weatherFuture;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _weatherFuture = _weatherService.fetchWeather();
  }

  Future<void> _refreshWeather() async {
    setState(() {
      _weatherFuture = _weatherService.fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaca Gunung Merbabu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshWeather,
          ),
        ],
      ),
      body: FutureBuilder<WeatherData>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (snapshot.hasData) {
            return _buildWeatherCard(snapshot.data!);
          }

          return const Center(child: Text('Tidak ada data cuaca'));
        },
      ),
    );
  }

  // ================= UI STATES =================

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Gagal mengambil data cuaca'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _refreshWeather,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather) {
    final updatedTime =
        DateFormat('dd MMM yyyy • HH:mm').format(DateTime.now());

    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ===== HEADER =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.location,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Update: $updatedTime',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Image.network(weather.iconUrl, width: 70),
                ],
              ),

              const SizedBox(height: 24),

              // ===== SUHU UTAMA =====
              Text(
                '${weather.temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                weather.description,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // ===== DETAIL =====
              _buildDetailRow(
                'Terasa seperti',
                '${weather.feelsLike.toStringAsFixed(1)}°C',
              ),
              _buildDetailRow(
                'Suhu Min / Max',
                '${weather.tempMin.toStringAsFixed(1)}° / ${weather.tempMax.toStringAsFixed(1)}°',
              ),
              _buildDetailRow(
                'Kelembaban',
                '${weather.humidity}%',
              ),
              _buildDetailRow(
                'Tekanan',
                '${weather.pressure} hPa',
              ),
              _buildDetailRow(
                // 🔥 FIX: m/s → km/jam
                'Angin',
                '${(weather.windSpeed * 3.6).toStringAsFixed(1)} km/jam',
              ),

              const SizedBox(height: 28),

              // ===== SARAN =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getAdviceColor(weather),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saran Pendakian',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _weatherService.getWeatherAdvice(weather),
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= COMPONENTS =================

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getAdviceColor(WeatherData weather) {
    if (weather.isStormy) return Colors.red;
    if (weather.isRainy) return Colors.orange;
    if (weather.isWindy) return Colors.amber;
    if (weather.isCold) return Colors.blue;
    if (weather.isGoodWeather) return Colors.green;
    return Colors.grey;
  }
}
