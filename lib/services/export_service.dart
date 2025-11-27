import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/note.dart';

class ExportService {
  /// Generate and share a PDF for the given note
  Future<void> downloadPdf(Note note) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                note.title.isEmpty ? 'Untitled' : note.title,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                DateFormat('MMMM d, yyyy • h:mm a').format(note.createdAt),
                style: pw.TextStyle(
                  font: font,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),
              pw.Text(
                note.body,
                style: pw.TextStyle(font: font, fontSize: 14, lineSpacing: 1.5),
              ),
            ],
          );
        },
      ),
    );

    // Use Printing package to share/print the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${_sanitizeFilename(note.title)}.pdf',
    );
  }

  String _sanitizeFilename(String title) {
    if (title.isEmpty) return 'note';
    return title
        .replaceAll(RegExp(r'[^\w\s]+'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
  }
}
