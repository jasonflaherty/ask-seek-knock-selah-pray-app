import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../verses/domain/verse.dart';
import '../domain/prayer.dart';

/// Builds and shares a prayer as plain text or PDF. Opt-in only — prayers stay
/// private on-device until the user shares.
class PrayerShare {
  const PrayerShare();

  String plainText(Prayer prayer, List<Verse> verses) {
    final buf = StringBuffer()
      ..writeln(prayer.name)
      ..writeln('—')
      ..writeln();

    if (prayer.hasPerson) {
      buf.writeln('For: ${prayer.person}');
      buf.writeln();
    }

    buf
      ..writeln('Prayer request')
      ..writeln(prayer.request)
      ..writeln();

    if (verses.isNotEmpty) {
      buf.writeln('Scripture to pray');
      for (final v in verses) {
        buf
          ..writeln()
          ..writeln(v.ref)
          ..writeln(v.text);
        if (v.note.isNotEmpty) {
          buf.writeln('(${v.note})');
        }
      }
      buf.writeln();
    }

    buf.writeln('How I’m praying');
    buf.writeln(
      'I am asking God according to His revealed will in these Scriptures — '
      'His promises and answered prayers recorded in the Bible.',
    );

    if (prayer.isAnswered) {
      buf.writeln();
      buf.writeln('Answered');
      if (prayer.answeredNote != null && prayer.answeredNote!.isNotEmpty) {
        buf.writeln(prayer.answeredNote);
      }
    }

    buf
      ..writeln()
      ..writeln('Shared from Selah · private prayer journal');

    return buf.toString().trimRight();
  }

  Future<void> shareText(Prayer prayer, List<Verse> verses) {
    return SharePlus.instance.share(
      ShareParams(
        text: plainText(prayer, verses),
        subject: 'Prayer: ${prayer.name}',
      ),
    );
  }

  Future<void> sharePdf(Prayer prayer, List<Verse> verses) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          pw.Text(
            prayer.name,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (prayer.hasPerson) ...[
            pw.SizedBox(height: 8),
            pw.Text('For: ${prayer.person}', style: const pw.TextStyle(fontSize: 12)),
          ],
          pw.SizedBox(height: 16),
          pw.Text(
            'Prayer request',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(prayer.request, style: const pw.TextStyle(fontSize: 12, lineSpacing: 4)),
          if (verses.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Scripture to pray',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            for (final v in verses) ...[
              pw.SizedBox(height: 12),
              pw.Text(
                v.ref,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                v.text,
                style: const pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic, lineSpacing: 4),
              ),
              if (v.note.isNotEmpty)
                pw.Text(v.note, style: const pw.TextStyle(fontSize: 10)),
            ],
          ],
          pw.SizedBox(height: 20),
          pw.Text(
            'How I’m praying',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'I am asking God according to His revealed will in these Scriptures — '
            'His promises and answered prayers recorded in the Bible.',
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
          ),
          if (prayer.isAnswered) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Answered',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            if (prayer.answeredNote != null && prayer.answeredNote!.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                prayer.answeredNote!,
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
              ),
            ],
          ],
          pw.SizedBox(height: 28),
          pw.Text(
            'Shared from Selah · private prayer journal',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final safe = prayer.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final fileName =
        'selah-prayer-${safe.isEmpty ? prayer.id : safe}.pdf'.replaceAll(' ', '-');
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Prayer: ${prayer.name}',
      ),
    );
  }
}
