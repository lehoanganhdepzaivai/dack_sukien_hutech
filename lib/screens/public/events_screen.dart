import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/event_card.dart';

class EventsScreen extends StatefulWidget {
  final bool favoritesOnly;
  const EventsScreen({super.key, this.favoritesOnly = false});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final TextEditingController _search;
  int _limit = 9;
  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: context.read<AppStore>().search);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final events = store.visibleEvents
        .where((e) => !widget.favoritesOnly || store.favorites.contains(e.id))
        .toList();
    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            widget.favoritesOnly
                ? 'Những trải nghiệm bạn đã lưu'
                : 'Khám phá sự kiện',
            subtitle: 'Tìm một hoạt động phù hợp với sở thích và lịch của bạn.',
          ),
          const SizedBox(height: 26),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, c) => Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: c.maxWidth > 850 ? c.maxWidth * .34 : c.maxWidth,
                      child: TextField(
                        controller: _search,
                        onChanged: (v) {
                          store.setFilters(search: v);
                          setState(() => _limit = 9);
                        },
                        decoration: const InputDecoration(
                          hintText: 'Tìm tên sự kiện, chủ đề...',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: c.maxWidth > 850 ? c.maxWidth * .22 : c.maxWidth,
                      child: DropdownButtonFormField<String>(
                        initialValue: store.categoryFilter.isEmpty
                            ? ''
                            : store.categoryFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Chủ đề'),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Tất cả chủ đề'),
                          ),
                          ...store.categories.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => store.setFilters(category: v),
                      ),
                    ),
                    SizedBox(
                      width: c.maxWidth > 850 ? c.maxWidth * .22 : c.maxWidth,
                      child: DropdownButtonFormField<String>(
                        initialValue: store.venueFilter.isEmpty
                            ? ''
                            : store.venueFilter,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Địa điểm',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Tất cả địa điểm'),
                          ),
                          ...store.venues.map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (v) => store.setFilters(venue: v),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _search.clear();
                        store.setFilters(
                          search: '',
                          category: '',
                          venue: '',
                          sort: 'soonest',
                        );
                      },
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Đặt lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 24,
            runSpacing: 12,
            children: [
              Text(
                '${events.length} sự kiện phù hợp',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: store.sortOrder,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Sắp xếp'),
                  items: const [
                    DropdownMenuItem(
                      value: 'soonest',
                      child: Text('Sắp diễn ra'),
                    ),
                    DropdownMenuItem(
                      value: 'recommended',
                      child: Text('Phù hợp với tôi'),
                    ),
                    DropdownMenuItem(value: 'title', child: Text('Tên A → Z')),
                  ],
                  onChanged: (v) => store.setFilters(sort: v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 23),
          if (events.isEmpty)
            EmptyPanel(
              title: widget.favoritesOnly
                  ? 'Chưa có sự kiện đã lưu'
                  : 'Không tìm thấy sự kiện',
              message:
                  'Thử thay đổi bộ lọc hoặc quay lại khi có hoạt động mới.',
              icon: Icons.search_off_rounded,
            )
          else
            EventGrid(events: events.take(_limit).toList()),
          if (events.length > _limit)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: OutlinedButton(
                  onPressed: () => setState(() => _limit += 9),
                  child: const Text('Xem thêm sự kiện'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
