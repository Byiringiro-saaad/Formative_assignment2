import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/incident.dart';

/// The incident's photo, or its category icon when there is no photo.
class IncidentThumbnail extends StatelessWidget {
  const IncidentThumbnail({super.key, required this.incident, this.size = 72});

  final Incident incident;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: Icon(
        incident.category.icon,
        color: AppColors.primary,
        size: size * 0.42,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: size,
        height: size,
        child: incident.hasPhoto
            ? CachedNetworkImage(
                imageUrl: incident.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}
