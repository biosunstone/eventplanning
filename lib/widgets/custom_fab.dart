import 'package:flutter/material.dart';

class CustomFAB extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomFAB({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        foregroundColor: foregroundColor ?? Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon),
    );
  }
}