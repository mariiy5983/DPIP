/// A card widget that highlights an available app update.
library;

import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

/// Displays a summary card for an available update.
///
/// Shows [title], [description], and an optional [onViewDetails] callback.
/// The card uses a gradient derived from the current theme's primary color.
class UpdateCard extends StatelessWidget {
  /// The update title (typically the version name).
  final String title;

  /// A brief description of what changed in this update.
  final String description;

  /// Called when the user taps to view full release details.
  ///
  /// When `null`, no interactive affordance is shown.
  final VoidCallback? onViewDetails;

  /// Creates an [UpdateCard] with the given [title] and [description].
  const UpdateCard({
    super.key,
    required this.title,
    required this.description,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.theme.primaryColor;
    final bodyMedium = context.texts.bodyMedium;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: .circular(20),
          gradient: LinearGradient(
            begin: .topLeft,
            end: .bottomRight,
            colors: [primary.withValues(alpha: 0.1), primary.withValues(alpha: 0.3)],
          ),
        ),
        child: Padding(
          padding: const .all(20),
          child: Row(
            crossAxisAlignment: .start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.new_releases, size: 28, color: primary),
                        const SizedBox(width: 10),
                        Text(
                          title,
                          style: context.texts.titleLarge?.copyWith(
                            fontWeight: .bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: bodyMedium?.copyWith(
                        color: bodyMedium.color?.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  shape: .circle,
                ),
                child: const Icon(
                  Icons.update,
                  size: 48,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
