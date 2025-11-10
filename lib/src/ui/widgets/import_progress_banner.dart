import 'package:flutter/material.dart';

class ImportProgressBanner extends StatelessWidget {
  const ImportProgressBanner({
    super.key,
    required this.message,
    this.showCancel = true,
    this.onCancel,
    this.progress = 0.0,
  });

  final String message;
  final bool showCancel;
  final VoidCallback? onCancel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primaryContainer;
    final onColor = theme.colorScheme.onPrimaryContainer;
    final clampedProgress = progress.clamp(0.0, 1.0);
    final hasDeterminateProgress = clampedProgress > 0;
    return Card(
      color: color,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: hasDeterminateProgress ? clampedProgress : null,
            minHeight: 4,
            backgroundColor: color.withValues(alpha: (color.a * 0.35).clamp(0.0, 1.0)),
            valueColor: AlwaysStoppedAnimation<Color>(onColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(color: onColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showCancel && onCancel != null) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(foregroundColor: onColor),
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
