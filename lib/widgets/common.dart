import 'dart:convert';

import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class EventImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  const EventImage(this.source, {super.key, this.fit = BoxFit.cover});
  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext c, Object e, StackTrace? s) => Container(
      color: const Color(0xFFE4EDF7),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 36, color: AppColors.blue),
          SizedBox(height: 8),
          Text('Chưa có hình ảnh'),
        ],
      ),
    );
    try {
      if (source.startsWith('data:image/')) {
        return Image.memory(
          base64Decode(source.split(',').last),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: fallback,
        );
      }
      if (source.startsWith('https://')) {
        return Image.network(
          source,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: fallback,
        );
      }
      return Image.asset(
        source,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: fallback,
      );
    } catch (_) {
      return fallback(context, Exception(), null);
    }
  }
}

class ContentArea extends StatelessWidget {
  final Widget child;
  const ContentArea({super.key, required this.child});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 700 ? 18 : 32,
          ),
          child: child,
        ),
      ),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionHeading(this.title, {super.key, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 16,
    runSpacing: 8,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ],
      ),
      ?trailing,
    ],
  );
}

class EmptyPanel extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final Widget? action;
  const EmptyPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.explore_outlined,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.blue.withValues(alpha: .08),
              child: Icon(icon, size: 32, color: AppColors.blue),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    ),
  );
}

class LabelPill extends StatelessWidget {
  final String text;
  final Color color;
  const LabelPill(this.text, {super.key, this.color = AppColors.blue});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}

Future<void> runAction(
  BuildContext context,
  Future<dynamic> Function() action, {
  String? success,
}) async {
  try {
    final result = await action();
    if (!context.mounted) return;
    if (success != null || result is String) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success ?? result as String)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFAD3841),
        ),
      );
    }
  }
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message, {
  String cancelLabel = 'Quay lại',
  String confirmLabel = 'Xác nhận',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;
