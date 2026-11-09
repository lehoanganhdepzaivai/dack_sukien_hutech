import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../models/event_model.dart';

class EventFeedbackDialog extends StatefulWidget {
  final EventModel event;
  final void Function(int rating, int content, int speaker, int org, String comment) onSubmit;

  const EventFeedbackDialog({
    super.key,
    required this.event,
    required this.onSubmit,
  });

  @override
  State<EventFeedbackDialog> createState() => _EventFeedbackDialogState();
}

class _EventFeedbackDialogState extends State<EventFeedbackDialog> {
  int _overallRating = 5;
  int _contentRating = 5;
  int _speakerRating = 5;
  int _orgRating = 5;
  final _commentController = TextEditingController();

  Widget _buildStarRating(String label, int current, void Function(int) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            final star = index + 1;
            return IconButton(
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(),
              icon: Icon(
                star <= current ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFE89E14),
              ),
              onPressed: () => onSelect(star),
            );
          }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE89E14).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.rate_review_outlined, color: Color(0xFFBA8412)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Khảo sát & Đánh giá sự kiện',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.event.title,
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _buildStarRating('1. Mức độ hài lòng chung:', _overallRating, (v) => setState(() => _overallRating = v)),
                const SizedBox(height: 14),
                _buildStarRating('2. Chất lượng nội dung & kiến thức:', _contentRating, (v) => setState(() => _contentRating = v)),
                const SizedBox(height: 14),
                _buildStarRating('3. Diễn giả / Báo cáo viên:', _speakerRating, (v) => setState(() => _speakerRating = v)),
                const SizedBox(height: 14),
                _buildStarRating('4. Công tác tổ chức & hỗ trợ:', _orgRating, (v) => setState(() => _orgRating = v)),
                const SizedBox(height: 18),
                const Text(
                  'Ý kiến đóng góp hoặc gợi ý cải thiện:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Nhập nhận xét hoặc cảm nghĩ của bạn sau sự kiện...',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Bỏ qua'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        widget.onSubmit(
                          _overallRating,
                          _contentRating,
                          _speakerRating,
                          _orgRating,
                          _commentController.text.trim(),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Gửi đánh giá'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
