import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../data/models/incident.dart';
import '../../data/models/incident_status.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/primary_button.dart';
import 'update_status_controller.dart';

/// Staff-only card on the details screen for moving a report forward.
class StatusUpdatePanel extends ConsumerWidget {
  const StatusUpdatePanel({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (incident.status.isFinal) {
      final done = incident.history.lastWhere(
        (h) => h.status == IncidentStatus.resolved,
        orElse: () => incident.history.last,
      );
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.resolvedBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.resolved),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Resolved by ${done.changedByName} on ${fullDateTime(done.changedAt)}.',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Staff actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Update the status so the reporter knows what is happening.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            for (final next in incident.status.nextOptions) ...[
              _StatusButton(
                status: next,
                primary: next == incident.status.nextOptions.first,
                onPressed: () => _openSheet(context, next),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, IncidentStatus status) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _UpdateStatusSheet(incident: incident, status: status),
    );
    if ((updated ?? false) && context.mounted) {
      showMessage(context, 'Status updated to ${status.label}.');
    }
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.primary,
    required this.onPressed,
  });

  final IncidentStatus status;
  final bool primary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = 'Mark as ${status.label}';
    final icon = status == IncidentStatus.resolved
        ? Icons.check_circle_outline_rounded
        : Icons.play_circle_outline_rounded;
    if (primary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

/// Bottom sheet that confirms a status change and takes an optional note.
class _UpdateStatusSheet extends ConsumerStatefulWidget {
  const _UpdateStatusSheet({required this.incident, required this.status});

  final Incident incident;
  final IncidentStatus status;

  @override
  ConsumerState<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends ConsumerState<_UpdateStatusSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final ok = await ref
        .read(updateStatusControllerProvider.notifier)
        .change(widget.incident, widget.status, note: _note.text);
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(updateStatusControllerProvider, (_, next) {
      if (next.hasError) {
        showMessage(context, next.error.toString(), error: true);
      }
    });
    final saving = ref.watch(updateStatusControllerProvider).isLoading;
    final s = widget.status;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mark as ${s.label}?',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '"${widget.incident.title}" will move from ${widget.incident.status.label} to ${s.label}. '
            'The reporter will see this on their timeline.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            maxLines: 3,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Note for the reporter (optional)',
              hintText: s == IncidentStatus.resolved
                  ? 'e.g. The tap was replaced this afternoon.'
                  : 'e.g. A technician has been assigned.',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(label: 'Confirm', loading: saving, onPressed: _confirm),
          const SizedBox(height: 4),
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
