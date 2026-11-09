import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/event_model.dart';

/// Quản lý CSDL SQLite cục bộ theo bài giảng Bài 6 (P1 & P2).
/// Hỗ trợ lưu trữ bền vững trên Mobile (Android, iOS) và Desktop (Windows, macOS, Linux).
class EventDatabaseHelper {
  EventDatabaseHelper._();
  static final EventDatabaseHelper instance = EventDatabaseHelper._();

  Database? _db;

  Future<Database?> get database async {
    if (kIsWeb) return null; // Web sử dụng IndexedDB & SharedPreferences
    _db ??= await _initDatabase();
    return _db;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = '$dbPath/hutech_events_v1.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            organization TEXT NOT NULL,
            venue TEXT NOT NULL,
            image TEXT NOT NULL,
            start TEXT NOT NULL,
            end TEXT NOT NULL,
            deadline TEXT NOT NULL,
            capacity INTEGER NOT NULL,
            status TEXT NOT NULL,
            skills TEXT NOT NULL,
            featured INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Map<String, dynamic> _toMap(EventModel event) => {
    'id': event.id,
    'title': event.title,
    'subtitle': event.subtitle,
    'description': event.description,
    'category': event.category,
    'organization': event.organization,
    'venue': event.venue,
    'image': event.image,
    'start': event.start.toIso8601String(),
    'end': event.end.toIso8601String(),
    'deadline': event.deadline.toIso8601String(),
    'capacity': event.capacity,
    'status': event.status.value,
    'skills': event.skills.join(','),
    'featured': event.featured ? 1 : 0,
  };

  EventModel _fromMap(Map<String, dynamic> map) => EventModel(
    id: map['id'] as String,
    title: map['title'] as String,
    subtitle: map['subtitle'] as String? ?? '',
    description: map['description'] as String? ?? '',
    category: map['category'] as String,
    organization: map['organization'] as String? ?? '',
    venue: map['venue'] as String,
    image: map['image'] as String? ?? '',
    start: DateTime.parse(map['start'] as String),
    end: DateTime.parse(map['end'] as String),
    deadline: DateTime.parse(map['deadline'] as String),
    capacity: (map['capacity'] as num).toInt(),
    status: EventStatus.parse(map['status'] as String?),
    skills:
        (map['skills'] as String? ?? '')
            .split(',')
            .where((s) => s.isNotEmpty)
            .toList(),
    featured: (map['featured'] as int? ?? 0) == 1,
  );

  Future<void> insertOrUpdate(EventModel event) async {
    final db = await database;
    if (db == null) return;
    await db.insert(
      'events',
      _toMap(event),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await database;
    if (db == null) return;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<EventModel>> getEvents() async {
    final db = await database;
    if (db == null) return [];
    final maps = await db.query('events');
    return maps.map(_fromMap).toList();
  }

  Future<void> syncEvents(List<EventModel> events) async {
    final db = await database;
    if (db == null) return;
    final batch = db.batch();
    batch.delete('events');
    for (final event in events) {
      batch.insert('events', _toMap(event));
    }
    await batch.commit(noResult: true);
  }
}
