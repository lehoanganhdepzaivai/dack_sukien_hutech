import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dack/config/supabase_config.dart';
import 'package:dack/providers/app_store.dart';
import 'package:dack/repositories/local_repository.dart';
import 'package:dack/services/supabase_service.dart';

class TestMemoryRepository extends LocalRepository {
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
  group('Supabase Configuration & Auth Service', () {
    test('default configuration is unconfigured without env vars', () {
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(SupabaseService.instance.isInitialized, isFalse);
    });

    test('UserRole parse maps string values accurately', () {
      expect(UserRole.parse('admin'), equals(UserRole.admin));
      expect(UserRole.parse('organizer'), equals(UserRole.organizer));
      expect(UserRole.parse('student'), equals(UserRole.student));
      expect(UserRole.parse('other'), equals(UserRole.guest));
      expect(UserRole.parse(null), equals(UserRole.guest));
    });

    test('local student registration creates active user and persists correctly', () async {
      final repo = TestMemoryRepository();
      final store = AppStore(repository: repo);
      await store.initialize();

      await store.registerLocalStudent(
        name: 'Nguyễn Văn A',
        email: 'nguyenvana@hutech.edu.vn',
        studentId: '2180601234',
        password: 'password123',
      );

      // Verify the new user can log in
      await store.login('nguyenvana@hutech.edu.vn', 'password123');
      expect(store.isAuthenticated, isTrue);
      expect(store.profile?.name, equals('Nguyễn Văn A'));
      expect(store.profile?.studentId, equals('2180601234'));
      expect(store.isAdmin, isFalse);
    });

    test('duplicate email registration is rejected', () async {
      final repo = TestMemoryRepository();
      final store = AppStore(repository: repo);
      await store.initialize();

      await store.registerLocalStudent(
        name: 'Trần Thị B',
        email: 'tranthib@hutech.edu.vn',
        studentId: '2180605678',
        password: 'password123',
      );

      expect(
        () => store.registerLocalStudent(
          name: 'Trần Thị B 2',
          email: 'tranthib@hutech.edu.vn',
          studentId: '2180609999',
          password: 'password123',
        ),
        throwsA(predicate((e) => e.toString().contains('đã được sử dụng'))),
      );
    });
  });
}
