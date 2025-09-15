import "package:flutter/material.dart";
import "../error/plant_analysis_exceptions.dart";

/// Reusable error display widget
class ErrorDisplayWidget extends StatelessWidget {
  final PlantAnalysisException exception;
  final VoidCallback? onRetry;
  final String? actionText;

  const ErrorDisplayWidget({
    super.key,
    required this.exception,
    this.onRetry,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              const Text(
                "Hata",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exception.message,
            style: const TextStyle(color: Colors.red),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(actionText ?? "Tekrar Dene"),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error banner widget for small spaces
class ErrorBannerWidget extends StatelessWidget {
  final PlantAnalysisException exception;
  final VoidCallback? onDismiss;

  const ErrorBannerWidget({
    super.key,
    required this.exception,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exception.message,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
