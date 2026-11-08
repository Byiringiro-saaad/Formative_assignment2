import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/time_ago.dart';
import '../../data/models/incident_status.dart';
import '../../shared/widgets/empty_state.dart';
import '../auth/auth_providers.dart';
import 'activity_providers.dart';

/// Feed of status updates on the student's reports (or new reports, for staff).
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the feed clears the unread dot.
    Future.microtask(
      () => ref.read(lastSeenActivityProvider.notifier).markSeen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(
      currentUserProvider.select((u) => u.value?.isStaff ?? false),
    );
    final items = ref.watch(activityProvider);

    return Scaffold(
      appBar: AppBar(title: Text(staff ? 'New Reports' : 'Updates')),
      body: items.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Nothing new yet',
                message: staff
                    ? 'Reports submitted by students will appear here.'
                    : 'When staff update one of your reports, you will see it here.',
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                final s = item.change.status;
                final headline = staff
                    ? '${item.incident.anonymous ? 'Someone' : item.incident.reporterName} reported "${item.incident.title}"'
                    : switch (s) {
                        IncidentStatus.inProgress =>
                          '"${item.incident.title}" is now in progress',
                        IncidentStatus.resolved =>
                          '"${item.incident.title}" was resolved',
                        IncidentStatus.submitted =>
                          '"${item.incident.title}" was submitted',
                      };
                return Card(
                  child: ListTile(
                    onTap: () =>
                        context.push(Routes.incident(item.incident.id)),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: s.background,
                      child: Icon(s.icon, color: s.color, size: 20),
                    ),
                    title: Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (item.change.note.isNotEmpty) item.change.note,
                        timeAgo(item.change.changedAt),
                      ].join('\n'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    isThreeLine: item.change.note.isNotEmpty,
                  ),
                );
              },
            ),
    );
  }
}
