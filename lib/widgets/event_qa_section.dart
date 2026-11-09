import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app/app_theme.dart';
import '../providers/app_store.dart';
import 'common.dart';

class EventQASection extends StatefulWidget {
  final String eventId;
  const EventQASection({super.key, required this.eventId});

  @override
  State<EventQASection> createState() => _EventQASectionState();
}

class _EventQASectionState extends State<EventQASection> {
  final _questionController = TextEditingController();
  final Map<int, TextEditingController> _replyControllers = {};
  int? _replyingToQuestionIndex;

  // Danh sách câu hỏi mẫu / cục bộ cho sự kiện
  late final List<Map<String, dynamic>> _questions = [
    {
      'id': 1,
      'authorName': 'Nguyễn Hoàng Anh',
      'authorRole': 'Sinh viên',
      'question': 'Sự kiện này có được tính điểm rèn luyện không ạ?',
      'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
      'isPinned': true,
      'answers': [
        {
          'authorName': 'Ban Tổ Chức',
          'authorRole': 'Ban tổ chức',
          'answer': 'Chào bạn, sự kiện được cộng 5 điểm rèn luyện mục II sau khi bạn điểm danh vé thành công nhé!',
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
        }
      ],
    },
    {
      'id': 2,
      'authorName': 'Lê Minh Quân',
      'authorRole': 'Sinh viên',
      'question': 'Em cần mang theo laptop cá nhân để thực hành không ban tổ chức?',
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      'isPinned': false,
      'answers': [],
    },
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _replyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submitQuestion(String authorName) {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _questions.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'authorName': authorName,
        'authorRole': 'Sinh viên',
        'question': text,
        'createdAt': DateTime.now(),
        'isPinned': false,
        'answers': [],
      });
      _questionController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã gửi câu hỏi của bạn đến ban tổ chức.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submitAnswer(int questionIndex, String authorName, String role) {
    final controller = _replyControllers[questionIndex];
    if (controller == null) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      final answers = _questions[questionIndex]['answers'] as List;
      answers.add({
        'authorName': authorName,
        'authorRole': role,
        'answer': text,
        'createdAt': DateTime.now(),
      });
      controller.clear();
      _replyingToQuestionIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isAuthenticated = store.isAuthenticated;
    final currentUser = store.profile;
    final canModerate = store.isAdmin || store.isOrganizer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(
          'Hỏi đáp sự kiện (Q&A)',
          subtitle: 'Giao lưu và giải đáp thắc mắc trực tiếp cùng ban tổ chức.',
        ),
        const SizedBox(height: 16),

        // Form đặt câu hỏi
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isAuthenticated)
                  const Text(
                    'Đăng nhập tài khoản sinh viên để đặt câu hỏi cho sự kiện.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  )
                else ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.blue.withValues(alpha: 0.15),
                        child: Text(
                          (currentUser?.name.isNotEmpty ?? false)
                              ? currentUser!.name[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        currentUser?.name ?? 'Sinh viên',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _questionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Nhập câu hỏi của bạn về sự kiện...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _submitQuestion(currentUser?.name ?? 'Sinh viên HUTECH'),
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Gửi câu hỏi'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Danh sách câu hỏi
        if (_questions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Chưa có câu hỏi nào. Hãy là người đầu tiên đặt câu hỏi!',
              style: TextStyle(color: AppColors.muted),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final q = _questions[index];
              final bool isPinned = q['isPinned'] == true;
              final DateTime createdAt = q['createdAt'];
              final timeStr = DateFormat('HH:mm · dd/MM').format(createdAt);
              final List answers = q['answers'] as List;

              _replyControllers.putIfAbsent(index, () => TextEditingController());

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isPinned
                      ? const BorderSide(color: Color(0xFFBA8412), width: 1.5)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (isPinned)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBA8412).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.push_pin, size: 14, color: Color(0xFFBA8412)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đã ghim',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFBA8412),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            q['authorName'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                          if (canModerate)
                            IconButton(
                              icon: Icon(
                                isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                                size: 18,
                                color: isPinned ? const Color(0xFFBA8412) : AppColors.muted,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: isPinned ? 'Bỏ ghim' : 'Ghim thông báo',
                              onPressed: () => setState(() => q['isPinned'] = !isPinned),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        q['question'] as String,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 12),

                      // Danh sách câu trả lời
                      if (answers.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: answers.map((ans) {
                              final ansTime = DateFormat('HH:mm · dd/MM').format(ans['createdAt']);
                              final isOrg = ans['authorRole'] != 'Sinh viên';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 2,
                                      children: [
                                        Text(
                                          ans['authorName'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isOrg ? AppColors.blue : null,
                                          ),
                                        ),
                                        if (isOrg)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.blue.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'BTC',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.blue,
                                              ),
                                            ),
                                          ),
                                        Text(
                                          ansTime,
                                          style: const TextStyle(fontSize: 10, color: AppColors.muted),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ans['answer'] as String,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Nút trả lời (cho Admin/BTC hoặc người dùng đăng nhập)
                      if (isAuthenticated) ...[
                        const SizedBox(height: 8),
                        if (_replyingToQuestionIndex != index)
                          TextButton.icon(
                            onPressed: () => setState(() => _replyingToQuestionIndex = index),
                            icon: const Icon(Icons.reply, size: 16),
                            label: const Text('Trả lời', style: TextStyle(fontSize: 12)),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _replyControllers[index],
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập câu trả lời...',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () => _submitAnswer(
                                    index,
                                    canModerate ? 'Ban Tổ Chức' : (currentUser?.name ?? 'Sinh viên'),
                                    canModerate ? 'Ban tổ chức' : 'Sinh viên',
                                  ),
                                  child: const Text('Gửi'),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => _replyingToQuestionIndex = null),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
