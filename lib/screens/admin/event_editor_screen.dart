import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/app_theme.dart';
import '../../models/event_model.dart';
import '../../providers/app_store.dart';
import '../../widgets/common.dart';

class EventEditorScreen extends StatefulWidget {
  const EventEditorScreen({super.key, this.eventId});
  final String? eventId;

  @override
  State<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends State<EventEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _description = TextEditingController();
  final _organization = TextEditingController();
  final _capacity = TextEditingController(text: '100');
  final Set<String> _skills = {};
  String _category = '';
  String _venue = '';
  String _image = 'assets/images/technology.png';
  late DateTime _start;
  late DateTime _end;
  late DateTime _deadline;
  EventStatus _status = EventStatus.registrationOpen;
  bool _featured = true;
  bool _loaded = false;
  bool _missing = false;
  bool _saving = false;
  bool _picking = false;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final day = DateTime.now().add(const Duration(days: 7));
    _start = DateTime(day.year, day.month, day.day, 9);
    _end = _start.add(const Duration(hours: 2));
    _deadline = _start.subtract(const Duration(days: 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final store = context.read<AppStore>();
    _category = store.categories.firstOrNull ?? '';
    _venue = store.venues.firstOrNull ?? '';
    if (widget.eventId != null) {
      final event = store.eventById(widget.eventId!);
      if (event == null) {
        _missing = true;
      } else {
        _title.text = event.title;
        _subtitle.text = event.subtitle;
        _description.text = event.description;
        _organization.text = event.organization;
        _capacity.text = '${event.capacity}';
        _category = event.category;
        _venue = event.venue;
        _image = event.image;
        _start = event.start;
        _end = event.end;
        _deadline = event.deadline;
        _status = event.status;
        _featured = event.featured;
        _skills.addAll(event.skills);
      }
    }
    _loaded = true;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _subtitle,
      _description,
      _organization,
      _capacity,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Vui lòng nhập thông tin này.'
      : null;

  Future<void> _chooseImage() async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;
      if (await file.length() > 2 * 1024 * 1024) {
        throw const FormatException('Ảnh phải nhỏ hơn hoặc bằng 2 MB.');
      }
      final bytes = await file.readAsBytes();
      final mime = _mime(bytes);
      if (mime == null) {
        throw const FormatException(
          'Chỉ hỗ trợ ảnh PNG, JPG hoặc WebP hợp lệ.',
        );
      }
      if (!mounted) return;
      setState(() {
        _image = 'data:$mime;base64,${base64Encode(bytes)}';
        _featured = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã chọn ảnh và bật banner trang chủ. Lưu sự kiện để áp dụng.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('FormatException: ', ''),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _mime(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP') {
      return 'image/webp';
    }
    return null;
  }

  Future<void> _pickDate(String field, bool time) async {
    final current = field == 'start'
        ? _start
        : field == 'end'
        ? _end
        : _deadline;
    DateTime? value;
    if (time) {
      final result = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(current),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );
      if (result != null) {
        value = DateTime(
          current.year,
          current.month,
          current.day,
          result.hour,
          result.minute,
        );
      }
    } else {
      final now = DateTime.now();
      final earliest = current.year < now.year - 5
          ? current.year
          : now.year - 5;
      final latest = current.year > now.year + 10
          ? current.year
          : now.year + 10;
      final result = await showDatePicker(
        context: context,
        initialDate: current,
        firstDate: DateTime(earliest),
        lastDate: DateTime(latest, 12, 31),
      );
      if (result != null) {
        value = DateTime(
          result.year,
          result.month,
          result.day,
          current.hour,
          current.minute,
        );
      }
    }
    if (value == null || !mounted) return;
    setState(() {
      switch (field) {
        case 'start':
          _start = value!;
        case 'end':
          _end = value!;
        default:
          _deadline = value!;
      }
      _dateError = null;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      setState(
        () => _dateError = 'Thời gian kết thúc phải sau thời gian bắt đầu.',
      );
      return;
    }
    if (_deadline.isAfter(_start)) {
      setState(
        () =>
            _dateError = 'Hạn đăng ký phải trước hoặc bằng thời gian bắt đầu.',
      );
      return;
    }
    if (_category.isEmpty || _venue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục và địa điểm.')),
      );
      return;
    }
    if (_status == EventStatus.canceled && widget.eventId != null) {
      final approved = await confirmAction(
        context,
        'Lưu sự kiện ở trạng thái đã hủy?',
        'Những người đã đăng ký sẽ nhận được thông báo hủy sự kiện.',
      );
      if (!approved || !mounted) return;
    }
    setState(() {
      _saving = true;
      _dateError = null;
    });
    try {
      await context.read<AppStore>().saveEvent(
        EventModel(
          id: widget.eventId ?? '',
          title: _title.text.trim(),
          subtitle: _subtitle.text.trim(),
          description: _description.text.trim(),
          category: _category,
          organization: _organization.text.trim(),
          venue: _venue,
          image: _image,
          start: _start,
          end: _end,
          deadline: _deadline,
          capacity: int.parse(_capacity.text.trim()),
          status: _status,
          skills: _skills.toList(),
          featured: _featured,
        ),
      );
      if (!mounted) return;
      final visibleToStudents = ![
        EventStatus.draft,
        EventStatus.pending,
        EventStatus.archived,
      ].contains(_status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            visibleToStudents
                ? 'Đã lưu sự kiện và hình ảnh. Sinh viên đã có thể xem.'
                : 'Đã lưu sự kiện và hình ảnh. Trạng thái này hiện chỉ admin xem được.',
          ),
        ),
      );
      context.go('/admin/events');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    if (_missing) {
      return ContentArea(
        child: EmptyPanel(
          title: 'Không tìm thấy sự kiện',
          message: 'Sự kiện có thể đã thay đổi hoặc không còn trong danh sách.',
          action: FilledButton(
            onPressed: () => context.go('/admin/events'),
            child: const Text('Về quản lý sự kiện'),
          ),
        ),
      );
    }
    final categories = {
      ...store.categories,
      if (_category.isNotEmpty) _category,
    }.toList();
    final venues = {...store.venues, if (_venue.isNotEmpty) _venue}.toList();
    final skills = {...store.skills, ..._skills}.toList();
    return ContentArea(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: _saving ? null : () => context.go('/admin/events'),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Quản lý sự kiện'),
            ),
            const SizedBox(height: 16),
            SectionHeading(
              widget.eventId == null ? 'Tạo sự kiện mới' : 'Chỉnh sửa sự kiện',
              subtitle: 'Chuẩn bị thông tin, hình ảnh và thời gian tổ chức.',
              trailing: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Đang lưu...' : 'Lưu sự kiện'),
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final main = Column(
                  children: [
                    _card('Thông tin sự kiện', Icons.edit_note_outlined, [
                      TextFormField(
                        controller: _title,
                        validator: _required,
                        maxLength: 160,
                        decoration: const InputDecoration(
                          labelText: 'Tên sự kiện *',
                          hintText: 'Tên ngắn gọn, thể hiện chủ đề chính',
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _subtitle,
                        validator: _required,
                        maxLength: 260,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả ngắn *',
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _description,
                        validator: _required,
                        minLines: 6,
                        maxLines: 14,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung chi tiết *',
                          alignLabelWithHint: true,
                          hintText: 'Nội dung, đối tượng tham gia, chương trình và quyền lợi...',
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _organization,
                        validator: _required,
                        decoration: InputDecoration(
                          labelText: 'Đơn vị tổ chức *',
                          suffixIcon: PopupMenuButton<String>(
                            tooltip: 'Chọn khoa / viện',
                            icon: const Icon(Icons.arrow_drop_down),
                            onSelected: (value) =>
                                setState(() => _organization.text = value),
                            itemBuilder: (_) => store.faculties
                                .map(
                                  (value) => PopupMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        initialValue: _category.isEmpty ? null : _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Danh mục *',
                        ),
                        validator: _required,
                        items: categories
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _category = value ?? ''),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _card(
                      'Thời gian & địa điểm',
                      Icons.calendar_month_outlined,
                      [
                        _dateField('Bắt đầu', 'start', _start),
                        const SizedBox(height: 18),
                        _dateField('Kết thúc', 'end', _end),
                        const SizedBox(height: 18),
                        _dateField('Hạn đăng ký', 'deadline', _deadline),
                        const SizedBox(height: 20),
                        if (_dateError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _dateError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        DropdownButtonFormField<String>(
                          initialValue: _venue.isEmpty ? null : _venue,
                          isExpanded: true,
                          validator: _required,
                          decoration: const InputDecoration(
                            labelText: 'Địa điểm *',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          items: venues
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _venue = value ?? ''),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _capacity,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sức chứa *',
                            suffixText: 'người',
                          ),
                          validator: (value) {
                            final capacity = int.tryParse(value?.trim() ?? '');
                            return capacity == null || capacity <= 0
                                ? 'Nhập số nguyên lớn hơn 0.'
                                : null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _card(
                      'Kỹ năng có thể phát triển',
                      Icons.auto_awesome_outlined,
                      [
                        const Text(
                          'Chọn các kỹ năng thực sự liên quan đến nội dung sự kiện.',
                          style: TextStyle(color: AppColors.muted, height: 1.5),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills
                              .map(
                                (skill) => FilterChip(
                                  label: Text(skill),
                                  selected: _skills.contains(skill),
                                  onSelected: (selected) => setState(() {
                                    selected
                                        ? _skills.add(skill)
                                        : _skills.remove(skill);
                                  }),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                );
                final side = Column(
                  children: [
                    _card('Hình ảnh sự kiện', Icons.image_outlined, [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: EventImage(_image),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _picking ? null : _chooseImage,
                          icon: const Icon(
                            Icons.upload_file_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _picking ? 'Đang chọn ảnh...' : 'Chọn ảnh từ máy',
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'PNG, JPG hoặc WebP · Tối đa 2 MB\nTỷ lệ đề xuất 16:9.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Thư viện hình ảnh',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ['technology', 'community', 'music']
                            .map(
                              (name) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () => setState(
                                      () => _image = 'assets/images/$name.png',
                                    ),
                                    borderRadius: BorderRadius.circular(9),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(9),
                                        border: Border.all(
                                          color:
                                              _image ==
                                                  'assets/images/$name.png'
                                              ? AppColors.blue
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: AspectRatio(
                                        aspectRatio: 1.4,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: EventImage(
                                            'assets/images/$name.png',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _card('Thiết lập hiển thị', Icons.tune_rounded, [
                      DropdownButtonFormField<EventStatus>(
                        initialValue: _status,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Trạng thái',
                        ),
                        items: EventStatus.values
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(
                          () => _status = value ?? EventStatus.draft,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Sự kiện nổi bật',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Text(
                          'Đưa vào banner trang chủ khi đã công bố.',
                          style: TextStyle(fontSize: 12, height: 1.5),
                        ),
                        value: _featured,
                        onChanged: (value) => setState(() => _featured = value),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Bản nháp và sự kiện chờ duyệt chỉ hiển thị trong phần quản trị. Chọn “Đang mở đăng ký” khi đã sẵn sàng nhận sinh viên.',
                          style: TextStyle(fontSize: 12, height: 1.7),
                        ),
                      ),
                    ]),
                  ],
                );
                if (constraints.maxWidth < 1000) {
                  return Column(
                    children: [main, const SizedBox(height: 20), side],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: main),
                    const SizedBox(width: 22),
                    Expanded(flex: 4, child: side),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Đang lưu...' : 'Lưu sự kiện'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.blue, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    ),
  );

  Widget _dateField(String label, String field, DateTime value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            flex: 3,
            child: OutlinedButton.icon(
              onPressed: () => _pickDate(field, false),
              icon: const Icon(Icons.event_outlined, size: 17),
              label: Text(
                '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: () => _pickDate(field, true),
              icon: const Icon(Icons.schedule, size: 17),
              label: Text(
                '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
