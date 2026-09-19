import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hostel_management_system/models/student_model.dart';
import 'package:hostel_management_system/models/fee_model.dart';
import 'package:hostel_management_system/models/room_model.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> generateAndPrintHostelReport({
    required List<StudentModel> students,
    required List<RoomModel> rooms,
    required List<FeeModel> fees,
  }) async {
    final pdf = pw.Document();

    // Calculate some basic stats
    int totalCapacity = rooms.fold(0, (sum, item) => sum + item.capacity);
    int totalOccupied = rooms.fold(0, (sum, item) => sum + item.occupantStudentIds.length);
    double totalFeesExpected = fees.fold(0.0, (sum, item) => sum + item.totalAmount);
    double totalFeesCollected = fees.fold(0.0, (sum, item) => sum + item.paidAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Hostel Management System', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            pw.Text('Executive Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Students: ${students.length}'),
                    pw.Text('Total Rooms: ${rooms.length}'),
                    pw.Text('Occupancy: $totalOccupied / $totalCapacity'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Fees Expected: ₹${totalFeesExpected.toStringAsFixed(0)}'),
                    pw.Text('Total Fees Collected: ₹${totalFeesCollected.toStringAsFixed(0)}'),
                    pw.Text('Total Pending: ₹${(totalFeesExpected - totalFeesCollected).toStringAsFixed(0)}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            
            pw.Text('Student Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Table.fromTextArray(
              headers: ['Name', 'Course', 'Room', 'Phone'],
              data: students.map((s) => [
                s.name, 
                s.course, 
                s.roomNumber != null ? '${s.hostelBlock}-${s.roomNumber}' : 'Unassigned',
                s.phoneNumber
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Hostel_Status_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
