import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../application/metrics_providers.dart';
import '../domain/journal_metrics.dart';
import 'metric_bar_chart.dart';

class MetricsScreen extends ConsumerStatefulWidget {
  const MetricsScreen({super.key});

  @override
  ConsumerState<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends ConsumerState<MetricsScreen> {
  static const _usageChoices = [7, 14, 30];
  int _usageDays = 14;

  @override
  Widget build(BuildContext context) {
    final prayers = ref.watch(prayerMetricsProvider);
    final sessions = ref.watch(usageSessionsProvider);
    final now = ref.watch(clockProvider).now();

    return Scaffold(
      appBar: AppBar(title: const Text('Metrics')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.maxContentWidth,
            ),
            child: prayers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const _LoadFailure(),
              data: (metrics) => sessions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => const _LoadFailure(),
                data: (rows) => ListView(
                  padding: const EdgeInsets.all(AppTheme.screenPadding),
                  children: [
                    _PrayerSection(metrics: metrics),
                    const SizedBox(height: 16),
                    _TagSection(metrics: metrics),
                    const SizedBox(height: 16),
                    _UsageSection(
                      sessions: rows,
                      now: now,
                      days: _usageDays,
                      onDays: (days) => setState(() => _usageDays = days),
                      choices: _usageChoices,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Could not load metrics'));
  }
}

class _PrayerSection extends StatelessWidget {
  const _PrayerSection({required this.metrics});

  final PrayerMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final answeredColor = theme.brightness == Brightness.dark
        ? const Color(0xFF8FB4D4)
        : const Color(0xFF8A6232);
    final weekFormat = DateFormat('MMM d');
    final hasPrayers = metrics.active + metrics.answered > 0;

    return _MetricCard(
      title: 'Active and answered',
      subtitle: 'Petitions over the last 8 weeks.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${metrics.active} active · ${metrics.answered} answered',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          if (!hasPrayers)
            Text('No petitions yet.', style: theme.textTheme.bodyMedium)
          else
            MetricBarChart(
              series: [
                ChartSeries(name: 'Active', color: activeColor),
                ChartSeries(name: 'Answered', color: answeredColor),
              ],
              formatAxis: (value) => '$value',
              groups: [
                for (final week in metrics.weeks)
                  ChartGroup(
                    label: weekFormat.format(week.weekStart),
                    values: [week.active, week.answered],
                    semanticsLabel:
                        'Week of ${weekFormat.format(week.weekStart)}: '
                        '${week.active} active, ${week.answered} answered',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TagSection extends StatelessWidget {
  const _TagSection({required this.metrics});

  final PrayerMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _MetricCard(
      title: 'Tags',
      subtitle: 'How many petitions use each tag.',
      child: metrics.tags.isEmpty
          ? Text('No tags yet.', style: theme.textTheme.bodyMedium)
          : TagTotalChart(
              tags: [
                for (final tag in metrics.tags)
                  (name: tag.name, count: tag.count),
              ],
            ),
    );
  }
}

class _UsageSection extends StatelessWidget {
  const _UsageSection({
    required this.sessions,
    required this.now,
    required this.days,
    required this.onDays,
    required this.choices,
  });

  final List<AppSession> sessions;
  final DateTime now;
  final int days;
  final ValueChanged<int> onDays;
  final List<int> choices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = usageByDay(sessions, now: now, days: days);
    final total = series.fold<Duration>(
      Duration.zero,
      (sum, day) => sum + day.open,
    );
    final dayFormat = DateFormat('M/d');

    return _MetricCard(
      title: 'Time open',
      subtitle: 'How long the app has been open on this device.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${formatOpenDuration(total)} in the last $days days',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in choices)
                choice == days
                    ? FilledButton(
                        onPressed: () => onDays(choice),
                        child: Text('$choice days'),
                      )
                    : OutlinedButton(
                        onPressed: () => onDays(choice),
                        child: Text('$choice days'),
                      ),
            ],
          ),
          const SizedBox(height: 16),
          MetricBarChart(
            series: [
              ChartSeries(name: 'Open', color: theme.colorScheme.primary),
            ],
            formatAxis: (seconds) =>
                formatOpenDuration(Duration(seconds: seconds)),
            groups: [
              for (final day in series)
                ChartGroup(
                  label: dayFormat.format(day.day),
                  values: [day.open.inSeconds],
                  semanticsLabel:
                      '${dayFormat.format(day.day)}: '
                      '${formatOpenDuration(day.open)} open',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
