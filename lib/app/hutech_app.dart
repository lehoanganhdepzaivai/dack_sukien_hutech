import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_store.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/public/home_screen.dart';
import '../screens/public/events_screen.dart';
import '../screens/public/event_detail_screen.dart';
import '../screens/public/campuses_screen.dart';
import '../screens/student/calendar_screen.dart';
import '../screens/student/profile_screen.dart';
import '../screens/student/schedule_screen.dart';
import '../screens/student/development_screen.dart';
import '../screens/student/my_events_screen.dart';
import '../screens/student/ticket_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_events_screen.dart';
import '../screens/admin/admin_catalog_screen.dart';
import '../screens/admin/check_in_screen.dart';
import '../screens/admin/event_editor_screen.dart';
import '../widgets/common.dart';
import 'app_shell.dart';
import 'app_theme.dart';

class HutechApp extends StatefulWidget {
  final AppStore store;
  final String? initialLocation;
  const HutechApp({super.key, required this.store, this.initialLocation});
  @override
  State<HutechApp> createState() => _HutechAppState();
}

class _HutechAppState extends State<HutechApp> {
  late final GoRouter _router = GoRouter(
    initialLocation: widget.initialLocation,
    refreshListenable: widget.store,
    redirect: (context, state) {
      final path = state.uri.path;
      final adminRoute = path == '/admin' || path.startsWith('/admin/');
      final studentRoute =
          const {
            '/profile',
            '/schedule',
            '/development',
            '/my-events',
            '/favorites',
            '/calendar',
          }.contains(path) ||
          path.startsWith('/ticket/');
      final private = adminRoute || studentRoute;
      if (private && !widget.store.isAuthenticated) {
        return '/login?from=${Uri.encodeComponent(state.uri.toString())}';
      }
      if (adminRoute && !widget.store.isAdmin) {
        return '/forbidden';
      }
      if (widget.store.isAdmin && (path == '/' || studentRoute)) {
        return '/admin';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: EmptyPanel(
            title: '404 · Không tìm thấy trang',
            message: 'Đường dẫn này không tồn tại.',
            action: FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Về trang chủ'),
            ),
          ),
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            LoginScreen(returnTo: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/campuses',
            builder: (context, state) => const CampusesScreen(),
          ),
          GoRoute(
            path: '/events/:id',
            builder: (context, state) =>
                EventDetailScreen(eventId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/favorites',
            builder: (context, state) =>
                const EventsScreen(favoritesOnly: true),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/schedule',
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: '/development',
            builder: (context, state) => const DevelopmentScreen(),
          ),
          GoRoute(
            path: '/my-events',
            builder: (context, state) => const MyEventsScreen(),
          ),
          GoRoute(
            path: '/ticket/:id',
            builder: (context, state) =>
                TicketScreen(eventId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboard(),
          ),
          GoRoute(
            path: '/admin/events',
            builder: (context, state) => const AdminEventsScreen(),
          ),
          GoRoute(
            path: '/admin/events/new',
            builder: (context, state) => const EventEditorScreen(),
          ),
          GoRoute(
            path: '/admin/events/:id/edit',
            builder: (context, state) =>
                EventEditorScreen(eventId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/admin/categories',
            builder: (context, state) => const AdminCatalogScreen(),
          ),
          GoRoute(
            path: '/admin/participants',
            builder: (context, state) => const AdminParticipantsScreen(),
          ),
          GoRoute(
            path: '/admin/checkin',
            builder: (context, state) => CheckInScreen(
              initialEventId: state.uri.queryParameters['eventId'],
            ),
          ),
          GoRoute(
            path: '/forbidden',
            builder: (context, state) => const ContentArea(
              child: EmptyPanel(
                title: 'Bạn chưa có quyền truy cập',
                message: 'Khu vực này dành cho quản trị viên.',
                icon: Icons.lock_outline,
              ),
            ),
          ),
        ],
      ),
    ],
  );
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: widget.store,
    child: Consumer<AppStore>(
      builder: (context, store, _) => MaterialApp.router(
        title: 'HUTECH Event Intelligence',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: store.themeMode,
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
      ),
    ),
  );
}
