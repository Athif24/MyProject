import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sync_daily/core/database/app_database.dart';

void main() {
  test('SQLite berjalan dan melaporkan versinya', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final version = await db.sqliteVersion();
    expect(version, isNotEmpty);
    expect(RegExp(r'^\d+\.\d+').hasMatch(version), isTrue);
  });
}
