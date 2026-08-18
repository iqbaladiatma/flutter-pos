import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

/// A titled card section with optional trailing widget (e.g. "See all").
class SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(16),
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
