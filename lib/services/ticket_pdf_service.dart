import 'dart:io';
import 'package:intl/intl.dart';  // TAMBAH
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Opsional jika mau QR di PDF

import '../models/booking_model.dart';

class TicketPdfService {
  static Future<File> generateTicketPdf(Booking booking) async {
    final pdf = pw.Document();
    
    // Formatters
    final dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');
    final timeFormat = DateFormat('HH:mm');
    final rupiahFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Status mapping
    String getStatusText(String status) {
      switch (status.toLowerCase()) {
        case 'confirmed': return 'TERKONFIRMASI';
        case 'paid': return 'SUDAH DIBAYAR';
        case 'pending': return 'MENUNGGU';
        case 'pending_payment': return 'MENUNGGU PEMBAYARAN';
        case 'cancelled': return 'DIBATALKAN';
        default: return status.toUpperCase();
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MERBABU ACCESS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                      pw.Text(
                        'Tiket Digital Pendakian',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: booking.status.toLowerCase() == 'confirmed' ||
                              booking.status.toLowerCase() == 'paid'
                          ? PdfColors.green
                          : booking.status.toLowerCase() == 'cancelled'
                              ? PdfColors.red
                              : PdfColors.orange,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      getStatusText(booking.status),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),

              pw.Divider(height: 24, thickness: 1),

              // ===== ID & INFO =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ID Booking:',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        booking.id,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Tanggal Cetak:',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // ===== DETAIL BOOKING =====
              pw.Text(
                'DETAIL BOOKING',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              _buildDetailRow('Paket Pendakian', booking.paketName),
              _buildDetailRow('Rute', booking.paketRoute),
              _buildDetailRow('Tanggal Pendakian',
                  dateFormat.format(booking.tanggalBooking)),
              _buildDetailRow('Waktu',
                  '${timeFormat.format(booking.tanggalBooking)} WIB'),
              _buildDetailRow('Jumlah Pendaki', '${booking.jumlahOrang} orang'),
              _buildDetailRow('Harga per Orang',
                  rupiahFormat.format(booking.paketPrice)),

              pw.SizedBox(height: 24),

              // ===== DATA PENDAKI =====
              pw.Text(
                'DATA PENDAKI',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),

              _buildDetailRow('Nama Lengkap', booking.userName),
              _buildDetailRow('Email', booking.userEmail),
              _buildDetailRow('Tanggal Booking',
                  DateFormat('dd MMM yyyy HH:mm').format(booking.createdAt)),

              pw.SizedBox(height: 24),

              // ===== TOTAL PEMBAYARAN =====
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL PEMBAYARAN',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      rupiahFormat.format(booking.totalHarga),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 32),

              // ===== INSTRUKSI =====
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INSTRUKSI PENGGUNAAN TIKET:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildInstruction('1. Bawalah tiket ini saat pendakian'),
                    _buildInstruction('2. Tunjukkan tiket di pos pendakian'),
                    _buildInstruction('3. Tiket berlaku untuk ${booking.jumlahOrang} orang'),
                    _buildInstruction('4. Tiket tidak dapat dipindahtangankan'),
                    _buildInstruction('5. Hubungi customer service jika ada masalah'),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ===== FOOTER =====
              pw.Divider(height: 1),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'MerbabuAccess • www.merbabuaccess.com • support@merbabuaccess.com',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Simpan file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'tiket_${booking.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInstruction(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }
}