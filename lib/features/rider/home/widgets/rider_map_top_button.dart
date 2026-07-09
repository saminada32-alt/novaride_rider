import 'package:flutter/material.dart';
import '../../../../core/widgets/a11y.dart';

class RiderMapTopButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final String semanticsLabel;

  const RiderMapTopButton({
    super.key,
    required this.child,
    required this.onTap,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return A11yIconButton(
      label: semanticsLabel,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
