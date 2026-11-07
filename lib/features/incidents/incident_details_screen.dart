import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/firebase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../data/models/app_user.dart';
import '../../data/models/incident.dart';
import '../../data/models/incident_status.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/incident_thumbnail.dart';
import '../../shared/widgets/status_chip.dart';
import '../auth/auth_providers.dart';
import 'incident_providers.dart';
import 'status_timeline.dart';

class IncidentDetailsScreen extends ConsumerWidget {
  const IncidentDetailsScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incident = ref.watch(incidentProvider(incidentId));
    final user = ref.watch(currentUserProvider).value;

    return incident.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Incident Details')),
        body: const Center(
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load this report',
            message: 'Check your connection and try again.',
          ),
        ),
      ),
      data: (incident) {
        if (incident == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Incident Details')),
            body: const Center(
              child: EmptyState(
                icon: Icons.delete_outline_rounded,
                title: 'Report not found',
                message:
                    'It may have been withdrawn by the person who reported it.',
              ),
            ),
          );
        }
        final canWithdraw =
            user != null &&
            incident.reporterId == user.uid &&
            incident.status == IncidentStatus.submitted;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Incident Details'),
            actions: [
              if (canWithdraw)
                PopupMenuButton<String>(
                  tooltip: 'More options',
                  onSelected: (_) => _withdraw(context, ref, incident),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'withdraw',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                        title: Text('Withdraw report'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _HeaderCard(incident: incident),
              const SizedBox(height: 24),
              const _Heading('Status Timeline'),
              const SizedBox(height: 12),
              StatusTimeline(incident: incident),
              ..._staffNotes(incident),
              const SizedBox(height: 24),
              const _Heading('Description'),
              const SizedBox(height: 8),
              Text(
                incident.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              if (incident.hasPhoto) ...[
                const SizedBox(height: 24),
                const _Heading('Attached Photo'),
                const SizedBox(height: 12),
                _AttachedPhoto(incident: incident),
              ],
              if (user != null) ...[
                const SizedBox(height: 24),
                IncidentActions(incident: incident, user: user),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _staffNotes(Incident incident) {
    final notes = incident.history.where((h) => h.note.isNotEmpty).toList();
    if (notes.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      for (final h in notes.reversed)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: h.status.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: h.status.color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${h.changedByName} · ${h.status.label} · ${shortDateTime(h.changedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: h.status.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      h.note,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  Future<void> _withdraw(
    BuildContext context,
    WidgetRef ref,
    Incident incident,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this report?'),
        content: const Text(
          'It will be removed for everyone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (!(yes ?? false) || !context.mounted) return;

    try {
      await ref.read(incidentRepositoryProvider).delete(incident.id);
      if (incident.photoPath != null) {
        // The report is gone either way; a leftover photo is only clutter.
        await ref
            .read(photoRepositoryProvider)
            .delete(incident.photoPath!)
            .catchError((_) {});
      }
      if (!context.mounted) return;
      showMessage(context, 'Report withdrawn.');
      context.pop();
    } on Exception {
      if (context.mounted) {
        showMessage(
          context,
          'Could not withdraw the report. Try again.',
          error: true,
        );
      }
    }
  }
}

/// Extra actions under the report. Empty for students; staff get the
/// status controls (added by the staff feature).
class IncidentActions extends StatelessWidget {
  const IncidentActions({
    super.key,
    required this.incident,
    required this.user,
  });

  final Incident incident;
  final AppUser user;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IncidentThumbnail(incident: incident, size: 76),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incident.location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusChip(status: incident.status),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  incident.category.icon,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  incident.category.label,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _MetaLine(
              icon: Icons.calendar_today_outlined,
              text: 'Submitted on ${fullDateTime(incident.createdAt)}',
            ),
            const SizedBox(height: 6),
            _MetaLine(
              icon: Icons.person_outline_rounded,
              text: 'Reported by ${incident.reporterName}',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );
}

class _AttachedPhoto extends StatelessWidget {
  const _AttachedPhoto({required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open photo full screen',
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => _PhotoViewer(url: incident.photoUrl!),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: incident.photoUrl!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, _) =>
                Container(height: 200, color: AppColors.primaryLight),
            errorWidget: (_, _, _) => Container(
              height: 200,
              color: AppColors.primaryLight,
              alignment: Alignment.center,
              child: const Text('Photo unavailable'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen photo with pinch to zoom.
class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
