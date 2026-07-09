import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Announces a screen/route to VoiceOver / TalkBack.
class A11yScreen extends StatelessWidget {
  final String label;
  final Widget child;

  const A11yScreen({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: label,
      child: child,
    );
  }
}

/// Wraps interactive controls with consistent VoiceOver / TalkBack labels.
class A11yButton extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;
  final bool enabled;
  final bool selected;

  const A11yButton({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.enabled = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      hint: hint,
      child: ExcludeSemantics(child: child),
    );
  }
}

class A11yHeader extends StatelessWidget {
  final String label;
  final Widget child;

  const A11yHeader({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }
}

class A11yTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const A11yTextField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      hint: hint,
      child: child,
    );
  }
}

class A11yImage extends StatelessWidget {
  final String label;
  final Widget child;

  const A11yImage({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(child: child),
    );
  }
}

class A11yLiveStatus extends StatelessWidget {
  final String message;
  final Widget child;

  const A11yLiveStatus({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: child,
    );
  }
}

/// Circular / icon-only control with an accessibility label.
class A11yIconButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget child;

  const A11yIconButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return A11yButton(
      label: label,
      enabled: onTap != null,
      child: GestureDetector(onTap: onTap, child: child),
    );
  }
}

void announceForAccessibility(BuildContext context, String message) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}
