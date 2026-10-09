import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/utils/announce.dart';

/// Slowly fades petition names in and out while the silence timer runs.
class FadingPetitionName extends StatefulWidget {
  const FadingPetitionName({super.key, required this.name});

  final String? name;

  @override
  State<FadingPetitionName> createState() => _FadingPetitionNameState();
}

class _FadingPetitionNameState extends State<FadingPetitionName>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  String? _shown;
  String? _pending;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _shown = widget.name;
    if (_shown != null) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _announce(_shown!);
      });
    }
  }

  @override
  void didUpdateWidget(FadingPetitionName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name == oldWidget.name) return;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      setState(() {
        _shown = widget.name;
        _pending = null;
      });
      _controller.value = widget.name == null ? 0 : 1;
      if (widget.name != null) _announce(widget.name!);
      return;
    }
    if (widget.name == null) {
      _pending = null;
      _controller.reverse();
      return;
    }
    if (_shown == null) {
      setState(() => _shown = widget.name);
      _controller.forward(from: 0);
      _announce(widget.name!);
      return;
    }
    _pending = widget.name;
    _controller.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _shown = _pending;
        _pending = null;
      });
      if (_shown != null) {
        _controller.forward();
        _announce(_shown!);
      }
    });
  }

  void _announce(String name) {
    if (!mounted) return;
    announceForAccessibility(context, name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = _shown;
    if (text == null) {
      return const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: _opacity,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontFamily: AppTheme.scriptureFont,
          fontWeight: FontWeight.w400,
          height: 1.3,
        ),
      ),
    );
  }
}
