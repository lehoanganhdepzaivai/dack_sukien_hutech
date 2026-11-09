import '../models/models.dart';
import 'domain_exception.dart';

class RegistrationChange {
  const RegistrationChange({
    required this.registrations,
    required this.registration,
    this.promotions = const [],
    required this.eventStatus,
  });
  final List<RegistrationModel> registrations;
  final RegistrationModel registration;
  final List<RegistrationModel> promotions;
  RegistrationModel? get promoted => promotions.firstOrNull;
  final EventStatus eventStatus;
}

class WaitlistChange {
  const WaitlistChange({
    required this.registrations,
    required this.promotions,
    required this.eventStatus,
  });
  final List<RegistrationModel> registrations;
  final List<RegistrationModel> promotions;
  final EventStatus eventStatus;
}

class RegistrationService {
  const RegistrationService();

  /// Fill available seats before accepting a newcomer, including seats added
  /// by an administrator. The original list position breaks timestamp ties.
  WaitlistChange reconcileWaitlist({
    required EventModel event,
    required List<RegistrationModel> registrations,
    required DateTime now,
  }) {
    final count = registrations
        .where((item) => item.eventId == event.id && item.occupiesSeat)
        .length;
    final available = event.capacity - count;
    final canPromote =
        now.isBefore(event.start) &&
        [
          EventStatus.registrationOpen,
          EventStatus.full,
          EventStatus.registrationClosed,
        ].contains(event.status);
    final queue =
        registrations.indexed
            .where(
              (item) =>
                  item.$2.eventId == event.id &&
                  item.$2.status == RegistrationStatus.waitlisted,
            )
            .toList()
          ..sort((a, b) {
            final chronological = a.$2.createdAt.compareTo(b.$2.createdAt);
            return chronological == 0 ? a.$1.compareTo(b.$1) : chronological;
          });
    final promotions = canPromote && available > 0
        ? queue
              .take(available)
              .map(
                (item) =>
                    item.$2.copyWith(status: RegistrationStatus.confirmed),
              )
              .toList()
        : <RegistrationModel>[];
    final promotedById = {for (final item in promotions) item.id: item};
    return WaitlistChange(
      registrations: registrations
          .map((item) => promotedById[item.id] ?? item)
          .toList(),
      promotions: promotions,
      eventStatus: _statusAfterSeatChange(
        event,
        count + promotions.length,
        now,
      ),
    );
  }

  EventStatus _statusAfterSeatChange(
    EventModel event,
    int count,
    DateTime now,
  ) {
    if (!event.isRegistrationOpen) return event.status;
    if (!now.isBefore(event.deadline)) return EventStatus.registrationClosed;
    return count >= event.capacity
        ? EventStatus.full
        : EventStatus.registrationOpen;
  }

  RegistrationChange register({
    required EventModel event,
    required String userId,
    required List<RegistrationModel> registrations,
    required DateTime now,
    required String id,
  }) {
    if (!event.isRegistrationOpen) {
      throw const DomainException('Sự kiện hiện không nhận đăng ký.');
    }
    if (!now.isBefore(event.deadline) || !now.isBefore(event.start)) {
      throw const DomainException('Đã hết thời hạn đăng ký sự kiện.');
    }
    if (event.capacity <= 0) {
      throw const DomainException('Sức chứa sự kiện chưa hợp lệ.');
    }
    final active = registrations.where(
      (item) =>
          item.userId == userId &&
          item.eventId == event.id &&
          item.status != RegistrationStatus.canceled,
    );
    if (active.isNotEmpty) {
      throw const DomainException(
        'Bạn đã đăng ký hoặc đã ở danh sách chờ của sự kiện này.',
      );
    }
    final waitlist = reconcileWaitlist(
      event: event,
      registrations: registrations,
      now: now,
    );
    final count = waitlist.registrations
        .where((item) => item.eventId == event.id && item.occupiesSeat)
        .length;
    final record = RegistrationModel(
      id: id,
      eventId: event.id,
      userId: userId,
      status: count < event.capacity
          ? RegistrationStatus.confirmed
          : RegistrationStatus.waitlisted,
      createdAt: now,
    );
    final result = [...waitlist.registrations, record];
    return RegistrationChange(
      registrations: result,
      registration: record,
      promotions: waitlist.promotions,
      eventStatus: count + (record.occupiesSeat ? 1 : 0) >= event.capacity
          ? EventStatus.full
          : EventStatus.registrationOpen,
    );
  }

  RegistrationChange cancel({
    required EventModel event,
    required String userId,
    required List<RegistrationModel> registrations,
    required DateTime now,
  }) {
    final own = registrations
        .where(
          (item) =>
              item.userId == userId &&
              item.eventId == event.id &&
              (item.status == RegistrationStatus.confirmed ||
                  item.status == RegistrationStatus.waitlisted),
        )
        .toList();
    if (own.isEmpty) {
      throw const DomainException('Không tìm thấy lượt đăng ký có thể hủy.');
    }
    if (!now.isBefore(event.start) && event.status != EventStatus.canceled) {
      throw const DomainException('Không thể hủy khi sự kiện đã bắt đầu.');
    }
    final original = own.last;
    final canceled = original.copyWith(status: RegistrationStatus.canceled);
    var result = registrations
        .map((item) => item.id == original.id ? canceled : item)
        .toList();
    var promotions = <RegistrationModel>[];
    if (original.occupiesSeat) {
      final waitlist = reconcileWaitlist(
        event: event,
        registrations: result,
        now: now,
      );
      result = waitlist.registrations;
      promotions = waitlist.promotions;
    }
    final count = result
        .where((item) => item.eventId == event.id && item.occupiesSeat)
        .length;
    return RegistrationChange(
      registrations: result,
      registration: canceled,
      promotions: promotions,
      eventStatus: _statusAfterSeatChange(event, count, now),
    );
  }
}
