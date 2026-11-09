import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/hutech_app.dart';
import 'providers/app_store.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN');
  try {
    await SupabaseService.instance.initialize();
  } catch (_) {}
  final store = AppStore();
  try {
    await store.initialize();
    runApp(HutechApp(store: store));
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storage_outlined, size: 48),
                  const SizedBox(height: 20),
                  const Text(
                    'Không thể mở dữ liệu trên trình duyệt này.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Vui lòng cho phép lưu trữ trang web rồi tải lại trang.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: main, child: const Text('Thử lại')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
