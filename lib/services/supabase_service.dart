import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'domain_exception.dart';

enum UserRole {
  guest,
  student,
  organizer,
  admin;

  String get code => name;

  String get label => switch (this) {
    guest => 'Khách',
    student => 'Sinh viên',
    organizer => 'Ban tổ chức',
    admin => 'Quản trị viên',
  };

  static UserRole parse(String? value) => switch (value?.toLowerCase()) {
    'admin' => UserRole.admin,
    'organizer' => UserRole.organizer,
    'student' => UserRole.student,
    _ => UserRole.guest,
  };
}

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;
  bool get isConfigured => SupabaseConfig.isConfigured;

  SupabaseClient? get client {
    if (!_initialized || !isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<bool> initialize() async {
    if (_initialized) return true;
    if (!isConfigured) {
      debugPrint('[SupabaseService] Backend Supabase chưa cấu hình. Dùng kho dữ liệu cục bộ.');
      return false;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        // ignore: deprecated_member_use
        anonKey: SupabaseConfig.publishableKey,
      );
      _initialized = true;
      debugPrint('[SupabaseService] Đã kết nối Supabase thành công.');
      return true;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi kết nối Supabase: $e');
      return false;
    }
  }

  User? get currentUser => client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // ---------------------------------------------------------------------------
  // AUTHENTICATION
  // ---------------------------------------------------------------------------

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final sb = client;
    if (sb == null) {
      throw const DomainException('Chưa kết nối máy chủ Supabase.');
    }

    if (!SupabaseConfig.isValidHutechEmail(email)) {
      throw const DomainException('Vui lòng sử dụng địa chỉ email sinh viên HUTECH.');
    }

    try {
      final res = await sb.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null ? {'full_name': fullName.trim()} : null,
      );
      return res;
    } on AuthException catch (e) {
      throw DomainException(e.message);
    } catch (e) {
      throw DomainException('Lỗi đăng ký tài khoản: $e');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final sb = client;
    if (sb == null) {
      throw const DomainException('Chưa kết nối máy chủ Supabase.');
    }

    try {
      final res = await sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return res;
    } on AuthException catch (e) {
      throw DomainException(e.message);
    } catch (e) {
      throw DomainException('Lỗi đăng nhập: $e');
    }
  }

  Future<void> signOut() async {
    final sb = client;
    if (sb == null) return;
    try {
      await sb.auth.signOut();
    } catch (_) {}
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final sb = client;
    if (sb == null) {
      throw const DomainException('Chưa kết nối máy chủ Supabase.');
    }
    try {
      await sb.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw DomainException(e.message);
    } catch (e) {
      throw DomainException('Lỗi gửi email khôi phục mật khẩu: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    final sb = client;
    if (sb == null) {
      throw const DomainException('Chưa kết nối máy chủ Supabase.');
    }
    try {
      await sb.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw DomainException(e.message);
    } catch (e) {
      throw DomainException('Lỗi cập nhật mật khẩu mới: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ROLES & PROFILE
  // ---------------------------------------------------------------------------

  Future<List<UserRole>> fetchCurrentUserRoles() async {
    final sb = client;
    final user = currentUser;
    if (sb == null || user == null) return [UserRole.guest];

    try {
      final res = await sb
          .from('user_roles')
          .select('roles(code)')
          .eq('user_id', user.id);

      final roles = <UserRole>[];
      for (final item in (res as List)) {
        final roleData = item['roles'] as Map<String, dynamic>?;
        if (roleData != null) {
          final code = roleData['code'] as String?;
          roles.add(UserRole.parse(code));
        }
      }
      return roles.isEmpty ? [UserRole.student] : roles;
    } catch (e) {
      debugPrint('[SupabaseService] Lỗi lấy vai trò người dùng: $e');
      return [UserRole.student];
    }
  }

  // ---------------------------------------------------------------------------
  // STORAGE (ẢNH SỰ KIỆN, AVATAR, TÀI LIỆU)
  // ---------------------------------------------------------------------------

  Future<String> uploadEventImage({
    required String fileName,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final sb = client;
    if (sb == null) {
      throw const DomainException('Chưa kết nối máy chủ Supabase Storage.');
    }

    // Giới hạn 5MB
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw const DomainException('Dung lượng ảnh không được vượt quá 5MB.');
    }

    try {
      final path = 'events/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await sb.storage.from('event-images').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );
      final publicUrl = sb.storage.from('event-images').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw DomainException('Lỗi tải ảnh lên Supabase Storage: $e');
    }
  }
}
