double toDoubleSafe(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value.toString());
  return parsed ?? fallback;
}

int toIntSafe(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  final parsed = int.tryParse(value.toString());
  return parsed ?? fallback;
}

bool toBoolSafe(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    if (value == 'true' || value == '1' || value == 't') return true;
    if (value == 'false' || value == '0' || value == 'f') return false;
  }
  return fallback;
}