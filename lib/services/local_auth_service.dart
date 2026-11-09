import 'domain_exception.dart';

/// Offline prototype authentication only. These user-authorized test accounts
/// are not a security boundary. Supabase Auth replaces this in the next phase.
class LocalAuthService {
  const LocalAuthService();
  String signIn(String email, String password) {
    final normalized = email.trim().toLowerCase();
    if (password != '123') {
      throw const DomainException('Email hoặc mật khẩu chưa chính xác.');
    }
    return switch (normalized) {
      'ha@gmail.com' => 'student-ha',
      'admin@gmail.com' => 'admin',
      _ => throw const DomainException('Email hoặc mật khẩu chưa chính xác.'),
    };
  }

  String roleFor(String? userId) {
    if (userId == null) return 'guest';
    if (userId == 'admin') return 'admin';
    if (userId == 'organizer' || userId.startsWith('organizer_')) return 'organizer';
    if (userId == 'student-ha' || userId.startsWith('student_')) return 'student';
    return 'student';
  }
}
