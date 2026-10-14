import 'package:drift/native.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/core/di/injection.dart';

/// Menyiapkan get_it dengan database Drift in-memory untuk pengujian.
Future<AppDatabase> setUpInMemoryDependencies() async {
  await getIt.reset();
  final database = AppDatabase(NativeDatabase.memory());
  await configureDependencies(database: database);
  return database;
}
