import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/models/incident_status.dart';
import '../../shared/widgets/incident_card.dart';
import '../../shared/widgets/role_badge.dart';
import '../../shared/widgets/summary_tile.dart';
import '../../shared/widgets/user_avatar.dart';
import '../auth/auth_providers.dart';
import '../incidents/incident_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final summary = ref.watch(mySummaryProvider);
    final mine = ref.watch(myIncidentsProvider).value ?? const [];

    void openMine({IncidentStatus? status}) {
      ref.read(incidentFilterProvider.notifier)
        ..clear()
        ..setMineOnly(true)
        ..setStatus(status);
      context.go(Routes.reports);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ProfileCard(user: user),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  count: summary.total,
                  label: 'Total Reports',
                  icon: Icons.description_outlined,
                  color: AppColors.primary,
                  background: AppColors.primaryLight,
                  onTap: openMine,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryTile(
                  count: summary.inProgress,
                  label: 'In Progress',
                  icon: Icons.schedule_rounded,
                  color: AppColors.tileBlueIcon,
                  background: AppColors.tileBlue,
                  onTap: () => openMine(status: IncidentStatus.inProgress),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SummaryTile(
                  count: summary.resolved,
                  label: 'Resolved',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.resolved,
                  background: AppColors.resolvedBg,
                  onTap: () => openMine(status: IncidentStatus.resolved),
                ),
              ),
            ],
          ),
          if (mine.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Reports',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(onPressed: openMine, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 8),
            for (final incident in mine.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IncidentCard(
                  incident: incident,
                  onTap: () => context.push(Routes.incident(incident.id)),
                ),
              ),
          ],
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Access level'),
                  subtitle: Text(
                    user.isStaff
                        ? 'Staff: you can review reports and update their status.'
                        : 'Student: you can submit reports and track their progress.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to report or track issues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (yes ?? false) await ref.read(authControllerProvider.notifier).signOut();
  }
}

/// Avatar, name, role and department, as on the "My Reports" mockup.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(user: user, size: 60),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RoleBadge(role: user.role),
                    ],
                  ),
                  if (user.department.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _InfoLine(
                      icon: Icons.school_outlined,
                      text: user.department,
                    ),
                  ],
                  if (user.campus.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _InfoLine(
                      icon: Icons.location_on_outlined,
                      text: user.campus,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
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
