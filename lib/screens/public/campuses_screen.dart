import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../models/campus_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';
import '../../widgets/event_card.dart';

class CampusesScreen extends StatefulWidget {
  const CampusesScreen({super.key});

  @override
  State<CampusesScreen> createState() => _CampusesScreenState();
}

class _CampusesScreenState extends State<CampusesScreen> {
  CampusModel? _selectedCampus;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final campuses = CampusModel.defaults;

    return ContentArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            'Cơ sở đào tạo HUTECH',
            subtitle: 'Thông tin các cơ sở, không gian tổ chức sự kiện và hướng dẫn di chuyển chi tiết.',
          ),
          const SizedBox(height: 20),

          // Danh sách các cơ sở dạng Card
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: campuses.map((campus) {
                        final isSelected = _selectedCampus?.id == campus.id;
                        final campusEvents = store.events.where(
                          (e) => campus.matchingVenues.contains(e.venue),
                        ).toList();

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildCampusCard(
                              context,
                              campus,
                              campusEvents.length,
                              isSelected,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  : Column(
                      children: campuses.map((campus) {
                        final isSelected = _selectedCampus?.id == campus.id;
                        final campusEvents = store.events.where(
                          (e) => campus.matchingVenues.contains(e.venue),
                        ).toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildCampusCard(
                            context,
                            campus,
                            campusEvents.length,
                            isSelected,
                          ),
                        );
                      }).toList(),
                    );
            },
          ),

          const SizedBox(height: 32),

          // Danh sách sự kiện tổ chức tại cơ sở được chọn (nếu có chọn)
          if (_selectedCampus != null) ...[
            SectionHeading(
              'Sự kiện tại ${_selectedCampus!.name}',
              subtitle: 'Các hoạt động đang và sắp diễn ra tại cơ sở này.',
              trailing: TextButton.icon(
                onPressed: () => setState(() => _selectedCampus = null),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Đóng'),
              ),
            ),
            const SizedBox(height: 14),
            Builder(
              builder: (context) {
                final filtered = store.events.where(
                  (e) => _selectedCampus!.matchingVenues.contains(e.venue),
                ).toList();

                if (filtered.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Hiện chưa có sự kiện nào sắp diễn ra tại cơ sở này.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, c) {
                    final crossAxisCount = c.maxWidth > 1000
                        ? 3
                        : c.maxWidth > 640
                            ? 2
                            : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return EventCard(event: filtered[index]);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampusCard(
    BuildContext context,
    CampusModel campus,
    int eventCount,
    bool isSelected,
  ) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: campus.id == 'campus-ab'
                    ? [const Color(0xFF0D47A1), const Color(0xFF1976D2)]
                    : [const Color(0xFF00695C), const Color(0xFF00897B)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      campus.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.apartment_rounded,
                    size: 72,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$eventCount sự kiện',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campus.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        campus.address,
                        style: const TextStyle(fontSize: 13, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  campus.description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hướng dẫn di chuyển & Xe buýt:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    campus.travelInstructions,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      setState(() {
                        _selectedCampus = isSelected ? null : campus;
                      });
                    },
                    child: Text(
                      isSelected
                          ? 'Ẩn danh sách sự kiện'
                          : 'Xem sự kiện tại cơ sở này ($eventCount)',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
