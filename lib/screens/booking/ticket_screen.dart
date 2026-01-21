import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../models/booking_model.dart';
import '../../services/ticket_pdf_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';

class TicketScreen extends StatefulWidget {
  final Booking booking;

  const TicketScreen({super.key, required this.booking});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  static const double _cardElevation = 4.0;
  static const double _cardBorderRadius = 16.0;
  static const double _contentPadding = 20.0;
  static const double _qrCodeSize = 200.0;
  static const double _statusIndicatorHeight = 30.0;

  bool _isGeneratingPdf = false;
  bool _isSharing = false;
  bool _isQrLoaded = false;

  static const _statusMap = {
    'confirmed': StatusInfo('TERKONFIRMASI', Colors.green),
    'paid': StatusInfo('SUDAH DIBAYAR', Colors.green),
    'pending': StatusInfo('MENUNGGU', Colors.orange),
    'pending_payment': StatusInfo('MENUNGGU PEMBAYARAN', Colors.orange),
    'cancelled': StatusInfo('DIBATALKAN', Colors.red),
  };

  static const _appTitle = 'MerbabuAccess';
  static const _ticketTitle = 'TIKET DIGITAL PENDAKIAN';
  static const _validForText = 'Tiket ini berlaku untuk';

  @override
  void initState() {
    super.initState();
    // Delay QR load untuk performance
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isQrLoaded = true);
      }
    });
  }

  StatusInfo _getStatusInfo(String status) {
    return _statusMap[status.toLowerCase()] ??
        StatusInfo(status.toUpperCase(), Colors.grey);
  }

  String _shortId(String id, [int length = 8]) {
    return id.length > length ? '${id.substring(0, length)}...' : id;
  }

  String _rupiah(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  bool get _isQrActive {
    final status = widget.booking.status.toLowerCase();
    return status == 'confirmed' || status == 'paid';
  }

  String get _qrData => 'MERBABU-${widget.booking.id}-${widget.booking.userId}';

  String get _qrInstructionText => _isQrActive
      ? 'Tunjukkan QR Code ini di pos pendakian'
      : 'QR Code aktif setelah pembayaran dikonfirmasi';

  Future<void> _generatePdf(BuildContext context) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final file = await TicketPdfService.generateTicketPdf(widget.booking);
      
      if (Platform.isAndroid || Platform.isIOS) {
        final result = await Printing.layoutPdf(
          onLayout: (_) => file.readAsBytes(),
        );
        
        if (!result && mounted) {
          _showSnackbar('Tidak ada printer yang terdeteksi', Colors.orange);
        }
      } else {
        await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Gagal membuat PDF tiket';
      
      if (e.toString().contains('permission')) {
        errorMessage = 'Izin ditolak. Pastikan aplikasi memiliki izin penyimpanan';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Waktu proses habis. Coba lagi';
      }

      _showSnackbar(errorMessage, Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _shareTicket(BuildContext context) async {
    setState(() => _isSharing = true);
    
    try {
      final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
      final String shareText = '''
🎫 *Tiket Pendakian MerbabuAccess*

*Detail Booking:*
ID: ${_shortId(widget.booking.id)}
Nama: ${widget.booking.userName}
Paket: ${widget.booking.paketName}
Rute: ${widget.booking.paketRoute}
Tanggal: ${dateFormat.format(widget.booking.tanggalBooking)}
Jumlah: ${widget.booking.jumlahOrang} orang
Status: ${_getStatusInfo(widget.booking.status).text}
Total: ${_rupiah(widget.booking.totalHarga)}

_Harap tunjukkan tiket ini di pos pendakian_
''';

      await Share.share(
        shareText,
        subject: 'Tiket Pendakian MerbabuAccess',
      );
    } catch (e) {
      if (mounted) {
        _showSnackbar('Gagal membagikan tiket', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    _showSnackbar('ID berhasil disalin ke clipboard', Colors.green);
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiket Pendakian'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        // ✅ FIX: Back button selalu ke Riwayat
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.riwayatBooking,
              (route) => false,
            );
          },
        ),
        actions: [
          if (_isSharing)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Bagikan Tiket',
              onPressed: () => _shareTicket(context),
            ),
          if (_isGeneratingPdf)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export PDF',
              onPressed: () => _generatePdf(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Card(
          elevation: _cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardBorderRadius),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : _contentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, isSmallScreen),
                const SizedBox(height: 20),
                _buildQrSection(isSmallScreen),
                const SizedBox(height: 24),
                _buildBookingDetails(dateFormat, timeFormat, isSmallScreen),
                const SizedBox(height: 24),
                _buildClimberDetails(isSmallScreen),
                const SizedBox(height: 24),
                _buildTotalSection(),
                const SizedBox(height: 20),
                _buildFooter(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isSmallScreen) {
    final statusInfo = _getStatusInfo(widget.booking.status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _copyToClipboard(context, widget.booking.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _appTitle,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'ID: ${_shortId(widget.booking.id)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.content_copy,
                    size: isSmallScreen ? 10 : 12,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          constraints: BoxConstraints(minHeight: _statusIndicatorHeight),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12,
            vertical: isSmallScreen ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: statusInfo.color,
            borderRadius: BorderRadius.circular(_statusIndicatorHeight / 2),
          ),
          child: Center(
            child: Text(
              statusInfo.text,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 10 : 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrSection(bool isSmallScreen) {
    final qrSize = isSmallScreen ? 150.0 : _qrCodeSize;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        border: Border.all(
          color: _isQrActive ? Colors.green.shade200 : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _isQrActive ? Colors.green.shade50 : Colors.grey.shade50,
      ),
      child: Column(
        children: [
          if (_isQrLoaded && _isQrActive)
            QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: qrSize,
              backgroundColor: Colors.white,
              gapless: false,
              errorStateBuilder: (cxt, err) {
                return Container(
                  width: qrSize,
                  height: qrSize,
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      'QR Error\nCoba lagi',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            )
          else
            Container(
              width: qrSize,
              height: qrSize,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: qrSize * 0.5,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isQrActive ? 'Memuat QR Code...' : 'Menunggu Konfirmasi',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _ticketTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
              color: _isQrActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _qrInstructionText,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(DateFormat dateFormat, DateFormat timeFormat, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Detail Booking', isSmallScreen),
        _buildDetailRow('Paket', widget.booking.paketName, isSmallScreen),
        _buildDetailRow('Rute', widget.booking.paketRoute, isSmallScreen),
        _buildDetailRow('Tanggal', dateFormat.format(widget.booking.tanggalBooking), isSmallScreen),
        _buildDetailRow(
          'Waktu',
          '${timeFormat.format(widget.booking.tanggalBooking)} WIB',
          isSmallScreen,
        ),
        _buildDetailRow('Jumlah Pendaki', '${widget.booking.jumlahOrang} orang', isSmallScreen),
        _buildDetailRow('Harga / Orang', _rupiah(widget.booking.paketPrice), isSmallScreen),
      ],
    );
  }

  Widget _buildClimberDetails(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Data Pendaki', isSmallScreen),
        _buildDetailRow('Nama', widget.booking.userName, isSmallScreen),
        _buildDetailRow('Email', widget.booking.userEmail, isSmallScreen),
        _buildDetailRow('No. Telepon', widget.booking.userPhone, isSmallScreen),
        _buildDetailRow('ID Booking', _shortId(widget.booking.id, 12), isSmallScreen),
        _buildDetailRow(
          'Tanggal Booking',
          DateFormat('dd MMM yyyy HH:mm').format(widget.booking.createdAt),
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            _rupiah(widget.booking.totalHarga),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      '$_validForText ${widget.booking.jumlahOrang} orang • ${DateFormat('dd MMMM yyyy').format(widget.booking.tanggalBooking)}',
      style: TextStyle(
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSectionTitle(String text, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isSmallScreen ? 100 : 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusInfo {
  final String text;
  final Color color;

  const StatusInfo(this.text, this.color);
}