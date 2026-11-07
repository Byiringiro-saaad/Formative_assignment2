import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../data/models/incident.dart';
import '../../data/models/incident_status.dart';

/// Three-step horizontal timeline: Submitted, In Progress, Resolved.
class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    const steps = IncidentStatus.values;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: _Step(status: steps[i], incident: incident),
          ),
          if (i < steps.length - 1)
            Container(
              width: 28,
              height: 2,
              margin: const EdgeInsets.only(top: 13),
              color: incident.status.index > i
                  ? AppColors.primary
                  : AppColors.border,
            ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.status, required this.incident});

  final IncidentStatus status;
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final reached = incident.status.index >= status.index;
    final current = incident.status == status;
    final at = incident.reachedAt(status);

    return Semantics(
      label: '${status.label}: ${reached ? 'done' : 'pending'}',
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? AppColors.primary : AppColors.surface,
              border: Border.all(
                color: reached ? AppColors.primary : AppColors.border,
                width: 2,
              ),
              boxShadow: current
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              reached && !current ? Icons.check_rounded : _icon(status),
              size: 16,
              color: reached ? Colors.white : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: current
                  ? AppColors.primary
                  : (reached ? AppColors.textPrimary : AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            at == null ? '—' : shortDateTime(at),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _icon(IncidentStatus s) => switch (s) {
    IncidentStatus.submitted => Icons.send_rounded,
    IncidentStatus.inProgress => Icons.autorenew_rounded,
    IncidentStatus.resolved => Icons.check_rounded,
  };
}
