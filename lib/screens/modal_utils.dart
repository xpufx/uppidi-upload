import 'package:flutter/material.dart';

/// Shows an adaptive modal dialog wrapping [child].
///
/// - On screens narrower than 600px: full-screen dialog with close AppBar
/// - On wider screens: centered dialog with 600x650 max constraints
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    useSafeArea: false,
    builder: (ctx) => LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              title: Text(title),
            ),
            body: child,
          );
        }
        return Center(
          child: SizedBox(
            width: 600,
            height: 650,
            child: Material(
              elevation: 24,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
