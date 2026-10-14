import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notifications/data/database/app_notifications_table.dart';

part 'notifications_dao.g.dart';

@DriftAccessor(tables: [AppNotifications])
class NotificationsDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationsDaoMixin {
  NotificationsDao(super.db);

  Stream<List<AppNotificationRow>> watchNotifications() {
    final query = select(appNotifications)
      ..where((n) => n.deletedAt.isNull())
      ..orderBy([(n) => OrderingTerm.desc(n.createdAt)]);
    return query.watch();
  }

  Stream<int> watchUnreadCount() {
    final count = appNotifications.id.count();
    final query = selectOnly(appNotifications)
      ..addColumns([count])
      ..where(appNotifications.deletedAt.isNull() &
          appNotifications.isRead.equals(false));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<void> upsertNotification(AppNotificationsCompanion companion) {
    return into(appNotifications).insertOnConflictUpdate(companion);
  }

  Future<void> markRead(String id, DateTime now) {
    return (update(appNotifications)..where((n) => n.id.equals(id))).write(
      AppNotificationsCompanion(
        isRead: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markAllRead(DateTime now) {
    return (update(appNotifications)
          ..where((n) => n.isRead.equals(false) & n.deletedAt.isNull()))
        .write(
      AppNotificationsCompanion(
        isRead: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> softDeleteNotification(String id, DateTime now) {
    return (update(appNotifications)..where((n) => n.id.equals(id))).write(
      AppNotificationsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }
}
