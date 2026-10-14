import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/converters/enum_converters.dart';

/// Notifikasi tersimpan di HP. Pengingat/deadline/acara dibuat lokal.
@DataClassName('AppNotificationRow')
class AppNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get type => text().map(const NotificationTypeConverter())();
  TextColumn get title => text()();
  TextColumn get body => text().nullable()();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  DateTimeColumn get scheduledAt => dateTime().nullable()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
