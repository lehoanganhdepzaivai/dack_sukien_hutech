import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app/app_theme.dart';
import '../models/event_model.dart';
import '../providers/app_store.dart';
import 'common.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  const EventCard({super.key, required this.event});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/events/${event.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  EventImage(event.image),
                  Positioned(
                    top: 13,
                    left: 13,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .95),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .93),
                      ),
                      tooltip: store.favorites.contains(event.id)
                          ? 'Bỏ lưu sự kiện'
                          : 'Lưu sự kiện',
                      icon: Icon(
                        store.favorites.contains(event.id)
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 19,
                        color: AppColors.blue,
                      ),
                      onPressed: () {
                        if (!store.isAuthenticated) {
                          context.push('/login');
                          return;
                        }
                        runAction(
                          context,
                          () => store.toggleFavorite(event.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 13),
                    _line(
                      Icons.calendar_today_outlined,
                      '${DateFormat('dd/MM/yyyy').format(event.start)}  ·  ${DateFormat('HH:mm').format(event.start)}',
                    ),
                    const SizedBox(height: 8),
                    _line(Icons.place_outlined, event.venue),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.status.label,
                            style: const TextStyle(
                              color: Color(0xFF24846C),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(
                          'Khám phá',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.muted),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class EventGrid extends StatelessWidget {
  final List<EventModel> events;
  const EventGrid({super.key, required this.events});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: c.maxWidth > 1050
            ? 3
            : c.maxWidth > 600
            ? 2
            : 1,
        mainAxisExtent: 370,
        crossAxisSpacing: 20,
        mainAxisSpacing: 22,
      ),
      itemBuilder: (context, i) => EventCard(event: events[i]),
    ),
  );
}
