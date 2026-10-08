import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:selah/app/theme.dart';

double _relLuminance(Color c) {
  double channel(double v) {
    final s = v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return s;
  }

  final r = channel(c.r);
  final g = channel(c.g);
  final b = channel(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color a, Color b) {
  final l1 = _relLuminance(a);
  final l2 = _relLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void expectContrast(Color fg, Color bg, double min, String label) {
  final ratio = contrastRatio(fg, bg);
  expect(
    ratio,
    greaterThanOrEqualTo(min),
    reason: '$label: $ratio < $min (fg=$fg bg=$bg)',
  );
}

void main() {
  group('WCAG contrast — light theme', () {
    test('text and control pairs meet section 8.0 minimums', () {
      expectContrast(AppTheme.lightOnSurface, AppTheme.lightSurface, 7.0, 'primary text on page');
      expectContrast(AppTheme.lightOnSurface, AppTheme.lightCard, 7.0, 'primary text on card');
      expectContrast(AppTheme.lightOnSurfaceVariant, AppTheme.lightSurface, 4.5, 'secondary text on page');
      expectContrast(AppTheme.lightOnSurfaceVariant, AppTheme.lightCard, 4.5, 'secondary text on card');
      expectContrast(AppTheme.lightPrimary, AppTheme.lightSurface, 4.5, 'accent text on page');
      expectContrast(AppTheme.lightOnPrimary, AppTheme.lightPrimary, 4.5, 'button label on primary');
      expectContrast(SelahPalette.light.answeredBadgeFg, SelahPalette.light.answeredBadgeBg, 4.5, 'answered badge');
      expectContrast(AppTheme.lightOutline, AppTheme.lightSurface, 3.0, 'control border on page');
      expectContrast(AppTheme.lightError, AppTheme.lightSurface, 4.5, 'error text on page');
      expectContrast(AppTheme.lightOnSurface, SelahPalette.light.verseSurface, 4.5, 'scripture on verseSurface');
    });
  });

  group('WCAG contrast — dark theme', () {
    test('text and control pairs meet section 8.0 minimums', () {
      expectContrast(AppTheme.darkOnSurface, AppTheme.darkSurface, 7.0, 'primary text on page');
      expectContrast(AppTheme.darkOnSurface, AppTheme.darkCard, 7.0, 'primary text on card');
      expectContrast(AppTheme.darkOnSurfaceVariant, AppTheme.darkSurface, 4.5, 'secondary text on page');
      expectContrast(AppTheme.darkOnSurfaceVariant, AppTheme.darkCard, 4.5, 'secondary text on card');
      expectContrast(AppTheme.darkPrimary, AppTheme.darkSurface, 4.5, 'accent text on page');
      expectContrast(AppTheme.darkOnPrimary, AppTheme.darkPrimary, 4.5, 'button label on primary');
      expectContrast(SelahPalette.dark.answeredBadgeFg, SelahPalette.dark.answeredBadgeBg, 4.5, 'answered badge');
      expectContrast(AppTheme.darkOutline, AppTheme.darkSurface, 3.0, 'control border on page');
      expectContrast(AppTheme.darkError, AppTheme.darkSurface, 4.5, 'error text on page');
      expectContrast(AppTheme.darkOnSurface, SelahPalette.dark.verseSurface, 4.5, 'scripture on verseSurface');
    });
  });

  test('theme data builds without error', () {
    expect(AppTheme.light.extensions[SelahPalette], isA<SelahPalette>());
    expect(AppTheme.dark.extensions[SelahPalette], isA<SelahPalette>());
  });
}
