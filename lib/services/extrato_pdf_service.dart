import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/format.dart';
import '../models/models.dart';

class ExtratoPdfService {
  static Future<void> share({
    required String householdName,
    required DateTime start,
    required DateTime end,
    required List<Tx> transactions,
  }) async {
    final document = pw.Document();
    final income = transactions
        .where((t) => !t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final expenses = transactions
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(householdName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Extrato financeiro', style: const pw.TextStyle(fontSize: 11)),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Text(householdName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Período: ${formatFullDate(isoDate(start))} a ${formatFullDate(isoDate(end))}'),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _summary('Entradas', income, PdfColors.green700),
              _summary('Saídas', expenses, PdfColors.red700),
              _summary('Saldo', income - expenses, income >= expenses ? PdfColors.green700 : PdfColors.red700),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.TableHelper.fromTextArray(
            headers: const ['Data', 'Descrição', 'Categoria', 'Responsável', 'Valor'],
            data: [
              for (final tx in transactions)
                [
                  formatFullDate(tx.date),
                  tx.title,
                  tx.category,
                  tx.payer,
                  '${tx.isExpense ? '-' : '+'} ${formatBRL(tx.amount)}',
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {4: pw.Alignment.centerRight},
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: .5)),
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'extrato-${isoDate(start)}-${isoDate(end)}.pdf',
    );
  }

  static pw.Widget _summary(String label, double value, PdfColor color) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(formatBRL(value), style: pw.TextStyle(fontSize: 11, color: color, fontWeight: pw.FontWeight.bold)),
            ],
          ),
        ),
      );
}
