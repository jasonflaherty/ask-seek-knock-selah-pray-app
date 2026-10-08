import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Announces [message] to screen readers using the current view.
void announceForAccessibility(BuildContext context, String message) {
  if (!context.mounted) return;
  if (!MediaQuery.supportsAnnounceOf(context)) return;
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  ).ignore();
}

extension on Future<void> {
  void ignore() {
    // Fire-and-forget; errors are non-fatal for a11y announcements.
    then((_) {}, onError: (_) {});
  }
}

/// Fallback when no [BuildContext] is available (e.g. after pop).
void announceMessage(String message) {
  final view = ui.PlatformDispatcher.instance.implicitView;
  if (view == null) return;
  SemanticsService.sendAnnouncement(
    view,
    message,
    ui.TextDirection.ltr,
  ).ignore();
}
