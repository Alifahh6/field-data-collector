import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../widgets/app_feedback.dart';
import '../widgets/custom_button.dart';

/// Layar tanda tangan digital penerima. Mengembalikan path file PNG, atau null jika dibatalkan.
class TandaTanganScreen extends StatefulWidget {
  final String namaPenerima;
  const TandaTanganScreen({super.key, this.namaPenerima = ''});

  @override
  State<TandaTanganScreen> createState() => _TandaTanganScreenState();
}

class _TandaTanganScreenState extends State<TandaTanganScreen> {
  final _kunci = GlobalKey();
  final List<List<Offset>> _goresan = [];
  bool _menyimpan = false;

  Future<void> _simpan() async {
    if (_goresan.isEmpty) {
      AppSnack.tampil(context, 'Tanda tangan masih kosong', tipe: SnackType.peringatan);
      return;
    }
    setState(() => _menyimpan = true);
    try {
      final boundary = _kunci.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'ttd'));
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, 'ttd_${DateTime.now().millisecondsSinceEpoch}.png'));
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
      if (mounted) Navigator.pop(context, file.path);
    } catch (_) {
      if (mounted) {
        setState(() => _menyimpan = false);
        AppSnack.tampil(context, 'Tanda tangan gagal disimpan', tipe: SnackType.galat);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tanda Tangan Penerima')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            children: [
              Text(
                widget.namaPenerima.isEmpty
                    ? 'Minta penerima menandatangani di kotak putih di bawah.'
                    : 'Minta ${widget.namaPenerima} menandatangani di kotak putih di bawah.',
                style: tt.bodyLarge,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: RepaintBoundary(
                    key: _kunci,
                    child: Container(
                      color: Colors.white,
                      child: GestureDetector(
                        onPanStart: (d) => setState(() => _goresan.add([d.localPosition])),
                        onPanUpdate: (d) => setState(() => _goresan.last.add(d.localPosition)),
                        child: CustomPaint(
                          painter: _TtdPainter(_goresan),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Hapus',
                      icon: Icons.delete_sweep_rounded,
                      kind: ButtonKind.outlined,
                      onPressed: () => setState(_goresan.clear),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Simpan',
                      icon: Icons.check_rounded,
                      loading: _menyimpan,
                      onPressed: _simpan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TtdPainter extends CustomPainter {
  final List<List<Offset>> goresan;
  _TtdPainter(this.goresan);

  @override
  void paint(Canvas canvas, Size size) {
    final garisBantu = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(24, size.height - 48), Offset(size.width - 24, size.height - 48), garisBantu);
    if (goresan.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(text: 'Tanda tangan di sini', style: TextStyle(color: Color(0xFFB0BEC5), fontSize: 18)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2 - tp.height / 2));
    }
    final pena = Paint()
      ..color = const Color(0xFF0D1B3E)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final g in goresan) {
      if (g.length == 1) {
        canvas.drawCircle(g.first, 1.6, Paint()..color = pena.color);
        continue;
      }
      final path = Path()..moveTo(g.first.dx, g.first.dy);
      for (final o in g.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, pena);
    }
  }

  @override
  bool shouldRepaint(covariant _TtdPainter old) => true;
}
