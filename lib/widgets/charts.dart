import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';

const _tanpaJudul = AxisTitles(sideTitles: SideTitles(showTitles: false));

double _maxY(List<int> values) {
  final m = values.fold<int>(0, math.max);
  return math.max(4, m + 1).toDouble();
}

double _interval(double maxY) => maxY <= 6 ? 1 : (maxY / 4).ceilToDouble();

Widget _judulKiri(double v, double interval, TextStyle style) {
  if (v % interval != 0) return const SizedBox.shrink();
  return Text(v.toInt().toString(), style: style);
}

/// Grafik batang (dipakai untuk tren 7 hari).
class BarTrenChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  final double height;
  const BarTrenChart({super.key, required this.values, required this.labels, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7));
    final maxY = _maxY(values);
    final interval = _interval(maxY);
    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: cs.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: _tanpaJudul,
            rightTitles: _tanpaJudul,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: interval,
                getTitlesWidget: (v, meta) => _judulKiri(v, interval, style),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[i], style: style),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: values.length > 10 ? 8 : 18,
                  color: cs.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: cs.primaryContainer.withValues(alpha: 0.35),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// Grafik garis (dipakai untuk rekap bulanan per hari).
class LineTrenChart extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  final double height;
  const LineTrenChart({super.key, required this.values, required this.labels, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.7));
    final maxY = _maxY(values);
    final interval = _interval(maxY);
    final n = values.length;
    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: math.max(1, n - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: cs.outlineVariant.withValues(alpha: 0.5), strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: _tanpaJudul,
            rightTitles: _tanpaJudul,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: interval,
                getTitlesWidget: (v, meta) => _judulKiri(v, interval, style),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (v != i.toDouble() || i < 0 || i >= labels.length) return const SizedBox.shrink();
                  final tampil = i == 0 || (i + 1) % 5 == 0;
                  if (!tampil) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(labels[i], style: style));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < n; i++) FlSpot(i.toDouble(), values[i].toDouble())],
              isCurved: true,
              curveSmoothness: 0.2,
              preventCurveOverShooting: true,
              color: cs.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: cs.primary.withValues(alpha: 0.15)),
            ),
          ],
        ),
      ),
    );
  }
}

class PieItem {
  final String label;
  final int value;
  final Color color;
  const PieItem(this.label, this.value, this.color);
}

/// Pie chart + legenda (dipakai untuk breakdown status dan jenis pajak).
class LegendPieChart extends StatelessWidget {
  final List<PieItem> items;
  const LegendPieChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final total = items.fold<int>(0, (a, b) => a + b.value);
    final aktif = items.where((e) => e.value > 0).toList();
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 44,
              sections: [
                for (final e in aktif)
                  PieChartSectionData(
                    value: e.value.toDouble(),
                    color: e.color,
                    radius: 58,
                    title: '${e.value}',
                    titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final e in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(e.label, style: tt.bodyMedium)),
                Text(
                  '${e.value}  (${total == 0 ? 0 : (e.value * 100 / total).round()}%)',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class StatusPieChart extends StatelessWidget {
  final Map<String, int> counts;
  const StatusPieChart({super.key, required this.counts});

  @override
  Widget build(BuildContext context) => LegendPieChart(
        items: [for (final e in counts.entries) PieItem(e.key, e.value, StatusSurat.color(e.key))],
      );
}

class KategoriPieChart extends StatelessWidget {
  final Map<String, int> counts; // id kategori -> jumlah
  const KategoriPieChart({super.key, required this.counts});

  @override
  Widget build(BuildContext context) => LegendPieChart(
        items: [
          for (final k in KategoriPajak.semua)
            if ((counts[k.id] ?? 0) > 0) PieItem(k.label, counts[k.id]!, k.color),
        ],
      );
}
