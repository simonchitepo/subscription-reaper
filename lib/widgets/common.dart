import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.subscriptions_outlined,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              if (onAction != null && actionText != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionText!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
    BuildContext context, {
      required String title,
      required String message,
      String cancelText = 'Cancel',
      String confirmText = 'Confirm',
      bool danger = false,
    }) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: danger
              ? FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          )
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return res ?? false;
}
