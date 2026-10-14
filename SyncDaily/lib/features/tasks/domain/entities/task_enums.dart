/// Jenis item. Nilai sama dengan token API (`type`).
enum TaskType { task, event, reminder, milestone }

/// Status pengerjaan. Token API memakai snake_case (`in_progress`),
/// sedangkan nama enum Dart memakai camelCase agar lolos lint.
enum TaskStatus {
  todo('todo'),
  inProgress('in_progress'),
  done('done');

  const TaskStatus(this.apiValue);

  final String apiValue;

  static TaskStatus fromApiValue(String value) =>
      values.firstWhere((status) => status.apiValue == value);
}

/// Prioritas. Nilai sama dengan token API (`priority`).
enum TaskPriority { low, medium, high }

/// Frekuensi pengulangan. Nilai sama dengan token API (`recurrence.frequency`).
enum RecurrenceFrequency { daily, weekly, monthly, yearly }

/// Hari dalam seminggu (index 0 = Senin), dipakai untuk aturan mingguan.
enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }
