import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Where an incident is in its lifecycle. Staff move it forward in order.
enum IncidentStatus {
  submitted(
    'Submitted',
    AppColors.submitted,
    AppColors.submittedBg,
    Icons.error_outline_rounded,
  ),
  inProgress(
    'In Progress',
    AppColors.inProgress,
    AppColors.inProgressBg,
    Icons.schedule_rounded,
  ),
  resolved(
    'Resolved',
    AppColors.resolved,
    AppColors.resolvedBg,
    Icons.check_circle_outline_rounded,
  );

  const IncidentStatus(this.label, this.color, this.background, this.icon);

  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  static IncidentStatus fromName(String? name) =>
      IncidentStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => IncidentStatus.submitted,
      );

  /// Statuses a staff member may move this incident to next.
  List<IncidentStatus> get nextOptions =>
      IncidentStatus.values.where((s) => s.index > index).toList();

  bool get isFinal => this == IncidentStatus.resolved;
}
