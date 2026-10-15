import 'package:flutter/material.dart';

/// One cluster of bars that share an x-axis label.
class ChartGroup {
  const ChartGroup({
    required this.label,
    required this.values,
    required this.semanticsLabel,
  });

  final String label;
  final List<int> values;
  final String semanticsLabel;
}

class ChartSeries {
  const ChartSeries({required this.name, required this.color});

  final String name;
  final Color color;
}

/// Vertical bar chart. Scrolls sideways when there are many groups.
class MetricBarChart extends StatelessWidget {
  const MetricBarChart({
    super.key,
    required this.groups,
    required this.series,
    required this.formatAxis,
  });

  final List<ChartGroup> groups;
  final List<ChartSeries> series;
  final String Function(int value) formatAxis;

  static const double _plotHeight = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final scale = textScaler.scale(1).clamp(1.0, 2.5);
    final labelHeight = textScaler.scale(20) * 2;
    final groupWidth = 72.0 * scale;
    final chartHeight = _plotHeight + 8 + labelHeight;
    final maxValue = _maxValue(groups);
    final axisTop = formatAxis(maxValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (series.length > 1) ...[
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [for (final item in series) _LegendItem(series: item)],
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  height: _plotHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        axisTop,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Text(
                        formatAxis(0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final group in groups)
                        _GroupColumn(
                          group: group,
                          series: series,
                          maxValue: maxValue,
                          plotHeight: _plotHeight,
                          labelHeight: labelHeight,
                          width: groupWidth,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static int _maxValue(List<ChartGroup> groups) {
    var maxValue = 0;
    for (final group in groups) {
      for (final value in group.values) {
        if (value > maxValue) maxValue = value;
      }
    }
    return maxValue;
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.series});

  final ChartSeries series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: series.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(series.name, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _GroupColumn extends StatelessWidget {
  const _GroupColumn({
    required this.group,
    required this.series,
    required this.maxValue,
    required this.plotHeight,
    required this.labelHeight,
    required this.width,
  });

  final ChartGroup group;
  final List<ChartSeries> series;
  final int maxValue;
  final double plotHeight;
  final double labelHeight;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final axisMax = maxValue == 0 ? 1 : maxValue;
    return Semantics(
      container: true,
      label: group.semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              Container(
                height: plotHeight,
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < series.length; i++) ...[
                      if (i > 0) const SizedBox(width: 3),
                      Expanded(
                        child: _Bar(
                          value: i < group.values.length ? group.values[i] : 0,
                          maxValue: axisMax,
                          color: series[i].color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: labelHeight,
                child: Text(
                  group.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final int value;
  final int maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (value <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        final fraction = (value / maxValue).clamp(0.0, 1.0);
        final height = (constraints.maxHeight * fraction).clamp(
          2.0,
          constraints.maxHeight,
        );
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal bars, one per tag name.
class TagTotalChart extends StatelessWidget {
  const TagTotalChart({super.key, required this.tags});

  final List<({String name, int count})> tags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = tags.fold<int>(
      1,
      (max, tag) => tag.count > max ? tag.count : max,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tag in tags) ...[
          Semantics(
            container: true,
            label:
                '${tag.name}, ${tag.count} '
                '${tag.count == 1 ? 'petition' : 'petitions'}',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tag.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('${tag.count}', style: theme.textTheme.labelLarge),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width =
                          (constraints.maxWidth * tag.count / maxCount).clamp(
                            2.0,
                            constraints.maxWidth,
                          );
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: width,
                          height: 12,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
