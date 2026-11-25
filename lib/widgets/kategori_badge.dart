import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Label jenis pajak berwarna (putih di atas warna jenis pajak).
class KategoriBadge extends StatelessWidget {
  final KategoriPajak kategori;
  final bool kecil;
  const KategoriBadge({super.key, required this.kategori, this.kecil = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: kecil ? 9 : 14, vertical: kecil ? 4 : 8),
      decoration: BoxDecoration(color: kategori.color, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kategori.icon, size: kecil ? 14 : 20, color: Colors.white),
          SizedBox(width: kecil ? 5 : 8),
          Flexible(
            child: Text(
              kecil ? kategori.singkat : kategori.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: kecil ? 12 : 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pemilih jenis pajak (kotak-kotak berwarna).
class KategoriSelector extends StatelessWidget {
  final String? terpilih;
  final ValueChanged<KategoriPajak> onPilih;
  const KategoriSelector({super.key, required this.terpilih, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      final lebar = (c.maxWidth - 16) / 3;
      return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final k in KategoriPajak.semua)
          SizedBox(
            width: lebar,
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: terpilih == k.id ? k.color : k.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: k.color, width: terpilih == k.id ? 2.5 : 1.2),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onPilih(k),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(terpilih == k.id ? Icons.check_rounded : k.icon, size: 18, color: terpilih == k.id ? Colors.white : k.color),
                        const SizedBox(width: 6),
                        Flexible(child: Text(
                          k.singkat,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: terpilih == k.id ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? cs.onSurface : k.color),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
      ],
    );
    });
  }
}
