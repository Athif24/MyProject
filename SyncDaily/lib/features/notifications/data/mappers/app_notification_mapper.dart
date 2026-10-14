import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/notifications/domain/entities/app_notification.dart';

extension AppNotificationRowMapper on AppNotificationRow {
  AppNotification toEntity() => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        entityType: entityType,
        entityId: entityId,
        scheduledAt: scheduledAt,
        isRead: isRead,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension AppNotificationEntityMapper on AppNotification {
  AppNotificationsCompanion toCompanion() => AppNotificationsCompanion(
        id: Value(id),
        type: Value(type),
        title: Value(title),
        body: Value(body),
        entityType: Value(entityType),
        entityId: Value(entityId),
        scheduledAt: Value(scheduledAt),
        isRead: Value(isRead),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}
