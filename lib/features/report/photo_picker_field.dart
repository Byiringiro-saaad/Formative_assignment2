import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import 'submit_report_controller.dart';

/// Dashed "Tap to add photos" box. Once a photo is chosen it shows a preview
/// with buttons to replace or remove it.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.photo,
    required this.picker,
    required this.onChanged,
    required this.onError,
    this.enabled = true,
  });

  final PickedPhoto? photo;
  final ImagePicker picker;
  final ValueChanged<PickedPhoto?> onChanged;
  final ValueChanged<String> onError;
  final bool enabled;

  Future<void> _choose(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      // Resizing and re-encoding on the device keeps uploads small and fast.
      final file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > AppConfig.maxPhotoBytes) {
        onError('That photo is too large. Please choose one under 5 MB.');
        return;
      }
      final dot = file.name.lastIndexOf('.');
      final ext = dot == -1
          ? 'jpg'
          : file.name.substring(dot + 1).toLowerCase();
      onChanged(PickedPhoto(bytes: bytes, extension: ext));
    } on Exception {
      onError(
        'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}. '
        'Check the app has permission.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = photo;
    if (current == null) {
      return CustomPaint(
        painter: _DashedBorderPainter(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? () => _choose(context) : null,
            child: const SizedBox(
              height: 96,
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap to add photos',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.memory(
            current.bytes,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _OverlayButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Replace photo',
                  onTap: enabled ? () => _choose(context) : null,
                ),
                const SizedBox(width: 8),
                _OverlayButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Remove photo',
                  onTap: enabled ? () => onChanged(null) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
