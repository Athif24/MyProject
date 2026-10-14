import 'package:drift/drift.dart';
import 'package:sync_daily/core/database/app_database.dart';
import 'package:sync_daily/features/projects/domain/entities/project.dart';

extension ProjectRowMapper on ProjectRow {
  Project toEntity() => Project(
        id: id,
        title: title,
        description: description,
        startDate: startDate,
        dueDate: dueDate,
        role: role,
        remoteId: remoteId,
        version: version,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: deletedAt,
      );
}

extension ProjectEntityMapper on Project {
  ProjectsCompanion toCompanion() => ProjectsCompanion(
        id: Value(id),
        title: Value(title),
        description: Value(description),
        startDate: Value(startDate),
        dueDate: Value(dueDate),
        role: Value(role),
        remoteId: Value(remoteId),
        version: Value(version),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        deletedAt: Value(deletedAt),
      );
}
