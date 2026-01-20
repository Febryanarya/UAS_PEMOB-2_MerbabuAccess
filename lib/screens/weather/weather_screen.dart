import 'package:flutter/material.dart';
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
        title: const Text('Cuaca Merbabu'),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 50),
                  const SizedBox(height: 16),
                  const Text('Gagal mengambil data cuaca'),
                  ElevatedButton(
                    onPressed: _refreshWeather,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            final weather = snapshot.data!;
            return _buildWeatherCard(weather);
          }

          return const Center(child: Text('Tidak ada data'));
        },
      ),
    );
  }

  Widget _buildWeatherCard(WeatherData weather) {
    return SingleChildScrollView(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
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
                        'Update: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  Image.network(weather.iconUrl, width: 60, height: 60),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '${weather.temperature.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
              ),
              Text(
                weather.description,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Terasa seperti', '${weather.feelsLike.toStringAsFixed(1)}°C'),
              _buildDetailRow('Suhu min/maks', '${weather.tempMin.toStringAsFixed(1)}° / ${weather.tempMax.toStringAsFixed(1)}°'),
              _buildDetailRow('Kelembaban', '${weather.humidity}%'),
              _buildDetailRow('Tekanan', '${weather.pressure} hPa'),
              _buildDetailRow('Angin', '${weather.windSpeed.toStringAsFixed(1)} km/jam'),
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getAdviceColor(weather),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saran Pendakian',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _weatherService.getWeatherAdvice(weather),
                      style: const TextStyle(color: Colors.white),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
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