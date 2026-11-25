import 'package:intl/intl.dart';

class DateFormatter {
  static const _l = 'id_ID';

  static String tanggalPanjang(DateTime d) => DateFormat('EEEE, d MMMM yyyy', _l).format(d);
  static String tanggalPendek(DateTime d) => DateFormat('d MMM yyyy', _l).format(d);
  static String tanggalAngka(DateTime d) => DateFormat('dd/MM/yyyy', _l).format(d);
  static String jam(DateTime d) => DateFormat('HH:mm', _l).format(d);
  static String tanggalJam(DateTime d) => DateFormat('dd/MM/yyyy HH:mm:ss', _l).format(d);
  static String tanggalJamPendek(DateTime d) => DateFormat('dd/MM/yy HH:mm', _l).format(d);
  static String hariSingkat(DateTime d) => DateFormat('E', _l).format(d);
  static String bulanTahun(DateTime d) => DateFormat('MMMM yyyy', _l).format(d);
  static String kodeFile(DateTime d) => DateFormat('yyyyMMdd', _l).format(d);

  static DateTime awalHari(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime hariBerikutnya(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String sapaan([DateTime? now]) {
    final h = (now ?? DateTime.now()).hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  static String labelHari(DateTime d) {
    final now = DateTime.now();
    if (sameDay(d, now)) return 'Hari Ini';
    if (sameDay(d, now.subtract(const Duration(days: 1)))) return 'Kemarin';
    return tanggalPanjang(d);
  }
}
