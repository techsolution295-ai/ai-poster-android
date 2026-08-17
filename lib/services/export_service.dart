import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Output format for exports.
enum ExportFormat { png, jpg }

/// Renders a poster (a [RepaintBoundary] identified by a [GlobalKey]) to a
/// high-resolution image and handles saving / sharing.
///
/// Because all layer geometry is normalised, capturing the same preview at a
/// higher pixel ratio yields a crisp full-resolution poster.
class ExportService {
  ExportService._();
  static final ExportService instance = ExportService._();

  /// Captures the boundary as raw PNG bytes at [targetWidth] logical pixels.
  Future<Uint8List> capturePng({
    required GlobalKey boundaryKey,
    required int targetWidth,
  }) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) {
      throw StateError('Export boundary is not mounted.');
    }
    final boundary = ctx.findRenderObject() as RenderRepaintBoundary;

    // Scale so the exported width matches the requested target.
    final logicalWidth = boundary.size.width;
    var pixelRatio = targetWidth / logicalWidth;
    // Guard against absurd ratios that could exhaust memory.
    pixelRatio = pixelRatio.clamp(0.5, 12.0);

    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode image.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Captures and encodes to the requested [format]. PNG is returned as-is;
  /// JPG is re-encoded from the raw pixels for smaller files.
  Future<Uint8List> capture({
    required GlobalKey boundaryKey,
    required int targetWidth,
    ExportFormat format = ExportFormat.png,
  }) async {
    final png = await capturePng(boundaryKey: boundaryKey, targetWidth: targetWidth);
    if (format == ExportFormat.png) return png;

    final decoded = img.decodePng(png);
    if (decoded == null) return png;
    // Flatten transparency onto white for JPG (no alpha channel).
    final jpg = img.encodeJpg(decoded, quality: 92);
    return Uint8List.fromList(jpg);
  }

  /// Saves image bytes to the device gallery. Returns true on success.
  Future<bool> saveToGallery(Uint8List bytes, {required String fileName}) async {
    try {
      await Gal.putImageBytes(bytes, name: fileName);
      return true;
    } catch (e) {
      // Fall back to writing a file then saving by path.
      try {
        final path = await _writeTemp(bytes, fileName);
        await Gal.putImage(path);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  /// Shares image bytes via the OS share sheet.
  Future<void> share(Uint8List bytes, {required String fileName, String? text}) async {
    final path = await _writeTemp(bytes, fileName);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], text: text),
    );
  }

  /// Opens the native system print dialog with the poster fitted to the page.
  Future<void> printPoster(Uint8List bytes, {required String fileName}) async {
    final decoded = img.decodeImage(bytes);
    var pageFormat = PdfPageFormat.a4;

    if (decoded != null && decoded.width > 0 && decoded.height > 0) {
      const margin = 36.0;
      final printableWidth = PdfPageFormat.a4.width - (margin * 2);
      final printableHeight = printableWidth * (decoded.height / decoded.width);
      pageFormat = PdfPageFormat(
        PdfPageFormat.a4.width,
        printableHeight + (margin * 2),
        marginAll: margin,
      );
    }

    final image = pw.MemoryImage(bytes);
    final docName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

    await Printing.layoutPdf(
      name: docName,
      format: pageFormat,
      onLayout: (PdfPageFormat format) async {
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            pageFormat: format,
            build: (context) => pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
          ),
        );
        return doc.save();
      },
    );
  }

  Future<String> _writeTemp(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
