import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_launcher_service.dart';

class AppIconWidget extends ConsumerWidget {
  const AppIconWidget({
    super.key,
    required this.packageName,
    required this.appName,
    this.size = 36,
    this.fallbackIcon,
  });

  final String packageName;
  final String appName;
  final double size;
  final IconData? fallbackIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconAsync = ref.watch(appIconProvider(packageName));

    return iconAsync.when(
      data: (bytes) {
        if (bytes != null && bytes.isNotEmpty) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.22),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildFallback(),
            ),
          );
        }
        return _buildFallback();
      },
      loading: () => _buildFallback(),
      error: (_, __) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    if (fallbackIcon != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: Colors.white24, width: 1.0),
        ),
        child: Center(
          child: Icon(
            fallbackIcon,
            size: size * 0.55,
            color: Colors.white,
          ),
        ),
      );
    }
    final char = appName.isNotEmpty ? appName[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: Colors.white24, width: 1.0),
      ),
      child: Center(
        child: Text(
          char,
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
