import 'package:sync_daily/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications();

  /// Jumlah notifikasi belum dibaca (badge lonceng).
  Stream<int> watchUnreadCount();

  Future<void> upsertNotification(AppNotification notification);

  Future<void> markRead(String id);

  Future<void> markAllRead();

  Future<void> softDeleteNotification(String id);
}
