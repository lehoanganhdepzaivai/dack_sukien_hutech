import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/app_store.dart';
import '../widgets/common.dart';
import '../widgets/hutech_logo.dart';
import 'app_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    final location = GoRouterState.of(context).uri.path;
    final store = context.watch<AppStore>();
    return Scaffold(
      drawer: wide ? null : Drawer(child: _Sidebar(location: location)),
      appBar: wide
          ? null
          : AppBar(
              title: Text(
                store.isAdmin ? 'HUTECH Admin' : 'HUTECH Events',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => _showNotifications(context),
                  icon: Badge(
                    isLabelVisible: store.unreadNotifications > 0,
                    child: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
              ],
            ),
      body: Row(
        children: [
          if (wide) SizedBox(width: 246, child: _Sidebar(location: location)),
          Expanded(
            child: Column(
              children: [
                if (wide) _Topbar(location: location),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : store.isAdmin
          ? _AdminBottomNavigation(location: location)
          : _StudentBottomNavigation(location: location),
    );
  }
}

class _AdminBottomNavigation extends StatelessWidget {
  final String location;
  const _AdminBottomNavigation({required this.location});

  @override
  Widget build(BuildContext context) {
    final index = location.startsWith('/admin/events/new')
        ? 2
        : location.startsWith('/admin/categories')
        ? 3
        : location.startsWith('/admin/participants')
        ? 4
        : location.startsWith('/admin/events') || location.startsWith('/events')
        ? 1
        : 0;
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index,
      selectedItemColor: AppColors.blue,
      unselectedItemColor: AppColors.muted,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      onTap: (i) => context.go(
        const [
          '/admin',
          '/admin/events',
          '/admin/events/new',
          '/admin/categories',
          '/admin/participants',
        ][i],
      ),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Tổng quan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit_calendar_outlined),
          label: 'Sự kiện',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline_rounded),
          activeIcon: Icon(Icons.add_circle_rounded),
          label: 'Thêm',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          label: 'Danh mục',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.groups_outlined),
          label: 'Tham gia',
        ),
      ],
    );
  }
}

class _StudentBottomNavigation extends StatelessWidget {
  final String location;
  const _StudentBottomNavigation({required this.location});

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    currentIndex: location.startsWith('/events')
        ? 1
        : location.startsWith('/calendar')
        ? 2
        : location.startsWith('/profile')
        ? 3
        : 0,
    selectedItemColor: AppColors.blue,
    unselectedItemColor: AppColors.muted,
    onTap: (i) =>
        context.go(const ['/', '/events', '/calendar', '/profile'][i]),
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.grid_view_rounded),
        label: 'Trang chủ',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        label: 'Sự kiện',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        label: 'Lịch',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Cá nhân',
      ),
    ],
  );
}

class _Sidebar extends StatelessWidget {
  final String location;
  const _Sidebar({required this.location});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.go(store.isAdmin ? '/admin' : '/'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(23, 25, 20, 25),
                child: Row(
                  children: [
                    const HutechLogoMark(size: 52),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HUTECH',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w900,
                                fontSize: 21,
                                letterSpacing: .5,
                              ),
                            ),
                            Text(
                              'EVENT INTELLIGENCE',
                              style: TextStyle(
                                fontSize: 8,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
              child: Text(
                store.isAdmin ? 'TRUNG TÂM QUẢN TRỊ' : 'KHÔNG GIAN CỦA BẠN',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                children: store.isAdmin
                    ? _adminNavigation(context)
                    : _studentNavigation(context, store),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE9F4FB), Color(0xFFFFF8D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      store.isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : Icons.wb_sunny_outlined,
                      color: AppColors.blue,
                      size: 25,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      store.isAdmin
                          ? 'Toàn quyền quản lý sự kiện, danh mục và người tham gia.'
                          : 'Một trải nghiệm mới.\nMột phiên bản tốt hơn.',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.6,
                        fontSize: 13,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Đổi giao diện sáng / tối',
                    onPressed: () => store.setThemeMode(
                      Theme.of(context).brightness == Brightness.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
                    icon: const Icon(Icons.contrast_rounded, size: 20),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () async {
                        if (store.isAuthenticated) {
                          final ok = await confirmAction(
                            context,
                            'Đăng xuất?',
                            'Bạn có thể đăng nhập lại để tiếp tục quản lý hoạt động.',
                          );
                          if (ok && context.mounted) {
                            await runAction(context, store.logout);
                          }
                        } else {
                          context.go('/login');
                        }
                      },
                      icon: Icon(
                        store.isAuthenticated
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        size: 18,
                      ),
                      label: Text(
                        store.isAuthenticated ? 'Đăng xuất' : 'Đăng nhập',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _adminNavigation(BuildContext context) => [
    _nav(
      context,
      'Tổng quan quản trị',
      Icons.dashboard_outlined,
      '/admin',
      exact: true,
    ),
    _nav(
      context,
      'Sự kiện & hình ảnh',
      Icons.edit_calendar_outlined,
      '/admin/events',
      excludedPrefixes: const ['/admin/events/new'],
    ),
    _nav(
      context,
      'Thêm sự kiện',
      Icons.add_circle_outline_rounded,
      '/admin/events/new',
      exact: true,
    ),
    _nav(context, 'Danh mục', Icons.category_outlined, '/admin/categories'),
    _nav(
      context,
      'Người tham gia',
      Icons.groups_outlined,
      '/admin/participants',
    ),
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Text(
        'XEM TRANG CÔNG KHAI',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 10,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    _nav(context, 'Khám phá sự kiện', Icons.open_in_new_rounded, '/events'),
  ];

  List<Widget> _studentNavigation(BuildContext context, AppStore store) => [
    _nav(context, 'Trang chủ', Icons.grid_view_rounded, '/', exact: true),
    _nav(context, 'Khám phá sự kiện', Icons.explore_outlined, '/events'),
    _nav(context, 'Lịch của tôi', Icons.calendar_month_outlined, '/calendar'),
    _nav(
      context,
      'Sự kiện đã lưu',
      Icons.bookmark_border_rounded,
      '/favorites',
      count: store.favorites.length,
    ),
    _nav(
      context,
      'Vé tham gia',
      Icons.confirmation_number_outlined,
      '/my-events',
    ),
    const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Text(
        'PHÁT TRIỂN BẢN THÂN',
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 10,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    _nav(
      context,
      'Lộ trình & kỹ năng',
      Icons.auto_graph_rounded,
      '/development',
    ),
    _nav(context, 'Lịch học', Icons.school_outlined, '/schedule'),
    _nav(context, 'Hồ sơ cá nhân', Icons.person_outline_rounded, '/profile'),
  ];

  Widget _nav(
    BuildContext context,
    String label,
    IconData icon,
    String route, {
    bool exact = false,
    int count = 0,
    List<String> excludedPrefixes = const [],
  }) {
    final excluded = excludedPrefixes.any(location.startsWith);
    final selected =
        !excluded &&
        (exact
            ? location == route
            : location == route || location.startsWith('$route/'));
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected
            ? AppColors.blue.withValues(alpha: .09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
              Navigator.pop(context);
            }
            context.go(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppColors.blue : AppColors.muted,
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.blue : null,
                    ),
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count',
                    style: const TextStyle(color: AppColors.blue, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Topbar extends StatelessWidget {
  final String location;
  const _Topbar({required this.location});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 34),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: AppColors.blue, size: 20),
          const SizedBox(width: 11),
          if (MediaQuery.sizeOf(context).width >= 1280)
            const Text(
              'Kết nối trải nghiệm. Kiến tạo tương lai.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          const Spacer(),
          SizedBox(
            width: 245,
            child: TextField(
              onSubmitted: (s) {
                store.setFilters(search: s);
                context.go('/events');
              },
              decoration: const InputDecoration(
                hintText: 'Tìm sự kiện bạn quan tâm...',
                hintStyle: TextStyle(fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'Thông báo',
            onPressed: () => _showNotifications(context),
            icon: Badge(
              isLabelVisible: store.unreadNotifications > 0,
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.muted,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(height: 32, width: 1, color: AppColors.border),
          const SizedBox(width: 18),
          InkWell(
            onTap: () => context.go(
              store.isAdmin
                  ? '/admin'
                  : store.isAuthenticated
                  ? '/profile'
                  : '/login',
            ),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: const Color(0xFFFFF0B8),
                  child: Text(
                    store.profile?.name
                            .split(' ')
                            .last
                            .substring(0, 1)
                            .toUpperCase() ??
                        'H',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.profile?.name ?? 'Chào bạn',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      store.isAdmin
                          ? 'Quản trị viên'
                          : store.isAuthenticated
                          ? 'Sinh viên HUTECH'
                          : 'Đăng nhập',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showNotifications(BuildContext context) {
  final store = context.read<AppStore>();
  showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Thông báo'),
      content: SizedBox(
        width: 420,
        child: store.notifications.isEmpty
            ? const Text('Bạn chưa có thông báo mới.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: store.notifications.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.blue,
                  ),
                  title: Text(
                    store.notifications[i],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
  if (store.isAuthenticated) {
    store.markNotificationsRead();
  }
}
