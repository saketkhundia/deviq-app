// One-shot logo generator: paints the DevIQ score-ring mark and writes
// it to assets/icon/deviq-logo.png. Run with:
//   flutter test test/gen_logo_test.dart
// Delete after regenerating.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate deviq logo', () async {
    const size = 1024.0;
    const cx = size / 2;
    const cy = size / 2;
    const radius = 400.0;
    const stroke = 96.0;

    // Load a bold sans for the <87> mark.
    final fontData = await File(
      '/usr/share/fonts/liberation/LiberationSans-Bold.ttf',
    ).readAsBytes();
    final loader = FontLoader('LogoSans')
      ..addFont(Future.value(ByteData.sublistView(fontData)));
    await loader.load();

    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()..color = const Color(0xFF000000),
    );

    double rad(double deg) => deg * math.pi / 180;

    void arc(double startDeg, double sweepDeg, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(cx, cy), radius: radius),
        rad(startDeg),
        rad(sweepDeg),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Gaps read as thin black separators (butt caps on black bg).
    // Green sweeps clockwise from just past the top; colored segments
    // sit top-right like the reference mark.
    arc(12, 264, const Color(0xFF1FAA55)); // green majority
    arc(-78, 30, const Color(0xFFF5C518)); // yellow
    arc(-42, 26, const Color(0xFFF59E0B)); // orange
    arc(-10, 16, const Color(0xFFF06423)); // red-orange

    final tp = TextPainter(
      text: const TextSpan(
        text: '<87>',
        style: TextStyle(
          fontFamily: 'LogoSans',
          fontWeight: FontWeight.w900,
          fontSize: 300,
          color: Colors.white,
          letterSpacing: -8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(cx - tp.width / 2, cy - tp.height / 2 - 10),
    );

    final pic = rec.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final out = File('assets/icon/deviq-logo.png');
    await out.create(recursive: true);
    await out.writeAsBytes(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('wrote ${out.path}');
  });
}
