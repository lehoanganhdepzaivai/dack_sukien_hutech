import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dack/models/campus_model.dart';
import 'package:dack/providers/app_store.dart';
import 'package:dack/repositories/local_repository.dart';

class CheckInTestMemoryRepo extends LocalRepository {
  Map<String, dynamic>? data;
  @override
  Future<void> initialize() async {}
  @override
  Future<Map<String, dynamic>?> read() async => data == null
      ? null
      : jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  @override
  Future<void> save(Map<String, dynamic> payload) async {
    data = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
  }
  @override
  Future<void> preserveRecovery() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Check-In & Attendance Logic Tests', () {
    test('CampusModel contains 2 official HUTECH campuses', () {
      expect(CampusModel.defaults.length, equals(2));
      expect(CampusModel.defaults.first.code, equals('CAMPUS_AB'));
      expect(CampusModel.defaults.last.code, equals('CAMPUS_E'));
    });

    test('Admin can check in a valid confirmed ticket', () async {
      final repo = CheckInTestMemoryRepo();
      final store = AppStore(repository: repo);
      await store.initialize();

      // Login as Admin
      await store.login('admin@gmail.com', '123');
      expect(store.isAdmin, isTrue);

      // The seeded registration 'registration-ha-teamwork' belongs to event 'teamwork-studio'
      final result = await store.checkInRegistration(
        eventId: 'teamwork-studio',
        ticketCode: 'registration-ha-teamwork',
        method: 'qr',
      );

      expect(result['success'], isTrue);
      expect(result['message'], contains('thành công'));

      // Check attendedCount grew
      expect(store.attendedCount('teamwork-studio'), equals(1));
    });

    test('Duplicate check-in on the same ticket is rejected', () async {
      final repo = CheckInTestMemoryRepo();
      final store = AppStore(repository: repo);
      await store.initialize();

      await store.login('admin@gmail.com', '123');

      // First check in
      final first = await store.checkInRegistration(
        eventId: 'teamwork-studio',
        ticketCode: 'registration-ha-teamwork',
      );
      expect(first['success'], isTrue);

      // Second check in attempt
      final second = await store.checkInRegistration(
        eventId: 'teamwork-studio',
        ticketCode: 'registration-ha-teamwork',
      );
      expect(second['success'], isFalse);
      expect(second['message'], contains('đã được điểm danh trước đó'));
    });

    test('Checking in a ticket for the wrong event is rejected', () async {
      final repo = CheckInTestMemoryRepo();
      final store = AppStore(repository: repo);
      await store.initialize();

      await store.login('admin@gmail.com', '123');

      final result = await store.checkInRegistration(
        eventId: 'flutter-lab', // Wrong event!
        ticketCode: 'registration-ha-teamwork',
      );
      expect(result['success'], isFalse);
      expect(result['message'], contains('không đúng sự kiện'));
    });

    test('Non-existent ticket code is rejected', () async {
      final repo = CheckInTestMemoryRepo();
      final store = AppStore(repository: repo);
      await store.initialize();

      await store.login('admin@gmail.com', '123');

      final result = await store.checkInRegistration(
        eventId: 'teamwork-studio',
        ticketCode: 'invalid-fake-ticket',
      );
      expect(result['success'], isFalse);
      expect(result['message'], contains('Không tìm thấy vé'));
    });
  });
}
