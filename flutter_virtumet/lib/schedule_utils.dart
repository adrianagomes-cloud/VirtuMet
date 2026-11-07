import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleData {
  final List<int> days;
  final int startMinutes;
  final int endMinutes;

  const ScheduleData({
    required this.days,
    required this.startMinutes,
    required this.endMinutes,
  });

  bool get isValid =>
      days.isNotEmpty &&
      startMinutes >= 0 &&
      endMinutes > startMinutes &&
      endMinutes <= 24 * 60;

  factory ScheduleData.fromMap(Map<String, dynamic> data) {
    final rawDays = data['diasSemana'];
    final days = rawDays is Iterable
        ? rawDays
            .map((value) => value is num ? value.toInt() : int.tryParse('$value'))
            .whereType<int>()
            .where((day) => day >= 1 && day <= 7)
            .toSet()
            .toList()
        : <int>[];
    return ScheduleData(
      days: days,
      startMinutes: (data['horaInicioMinutos'] as num?)?.toInt() ?? -1,
      endMinutes: (data['horaFinMinutos'] as num?)?.toInt() ?? -1,
    );
  }

  Map<String, dynamic> toMap() => {
        'diasSemana': days,
        'horaInicioMinutos': startMinutes,
        'horaFinMinutos': endMinutes,
      };

  String get displayText {
    if (!isValid) return 'Horario por definir';
    final dayText = days.map((day) => weekdayNames[day]!).join(' / ');
    return '$dayText ${formatMinutes(startMinutes)} - ${formatMinutes(endMinutes)}';
  }
}

const Map<int, String> weekdayNames = {
  1: 'Lun',
  2: 'Mar',
  3: 'Mié',
  4: 'Jue',
  5: 'Vie',
  6: 'Sáb',
  7: 'Dom',
};

String formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = minutes % 60;
  final suffix = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
}

bool schedulesOverlap(ScheduleData first, ScheduleData second) {
  if (!first.isValid || !second.isValid) return false;
  final sameDay = first.days.any(second.days.contains);
  return sameDay &&
      first.startMinutes < second.endMinutes &&
      second.startMinutes < first.endMinutes;
}

String scheduleConflictMessage(
  String newSportName,
  String existingSportName,
  ScheduleData newSchedule,
  ScheduleData existingSchedule,
) {
  final days = newSchedule.days
      .where(existingSchedule.days.contains)
      .map((day) => weekdayNames[day]!)
      .join(', ');
  return '$newSportName se solapa con $existingSportName el $days '
      '(${formatMinutes(newSchedule.startMinutes)} - '
      '${formatMinutes(newSchedule.endMinutes)}).';
}

Timestamp? timestampFrom(dynamic value) {
  if (value is Timestamp) return value;
  if (value is DateTime) return Timestamp.fromDate(value);
  return null;
}
