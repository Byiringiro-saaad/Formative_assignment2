import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/app_user.dart';
import '../../data/models/incident.dart';
import '../../data/models/incident_status.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/incident_card.dart';
import '../../shared/widgets/summary_tile.dart';
import '../../shared/widgets/user_avatar.dart';
import '../auth/auth_providers.dart';
import '../incidents/incident_providers.dart';
import '../notifications/activity_providers.dart';

/// Landing tab: greeting, the "Report an Issue" call to action, a summary of
/// report counts and the most recent reports.
///
/// Students see their own reports; staff see the whole campus.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final staff = user.isStaff;
    final summary = ref.watch(
      staff ? campusSummaryProvider : mySummaryProvider,
    );
    final recent = ref.watch(
      staff ? allIncidentsProvider : myIncidentsProvider,
    );

    void openReports({IncidentStatus? status}) {
      ref.read(incidentFilterProvider.notifier)
        ..clear()
        ..setMineOnly(!staff)
        ..setStatus(status);
      context.go(Routes.reports);
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref
              ..invalidate(allIncidentsProvider)
              ..invalidate(myIncidentsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _Greeting(user: user),
              const SizedBox(height: 20),
              _HeroCard(
                staff: staff,
                onReport: () => context.push(Routes.report),
                onReview: () => openReports(status: IncidentStatus.submitted),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: staff ? 'Campus Summary' : 'Report Summary',
                onSeeAll: () => openReports(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SummaryTile(
                      count: summary.total,
                      label: staff ? 'All Reports' : 'My Reports',
                      icon: Icons.description_outlined,
                      color: AppColors.primary,
                      background: AppColors.primaryLight,
                      onTap: () => openReports(),
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
                      onTap: () =>
                          openReports(status: IncidentStatus.inProgress),
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
                      onTap: () => openReports(status: IncidentStatus.resolved),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SummaryTile(
                      count: summary.submitted,
                      label: 'Submitted',
                      icon: Icons.error_rounded,
                      color: AppColors.danger,
                      background: AppColors.dangerBg,
                      onTap: () =>
                          openReports(status: IncidentStatus.submitted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: staff ? 'Latest on Campus' : 'Recent Reports',
                onSeeAll: () => openReports(),
              ),
              const SizedBox(height: 12),
              recent.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => const EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Could not load reports',
                  message: 'Check your connection and pull down to try again.',
                ),
                data: (items) => _RecentList(
                  incidents: items.take(3).toList(),
                  staff: staff,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadActivityCountProvider);
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${user.firstName} 👋', style: text.headlineMedium),
              const SizedBox(height: 10),
              Text(
                user.isStaff
                    ? 'Keep our campus running.'
                    : 'Help make our campus safer.',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                user.isStaff
                    ? 'Review new reports and update their progress.'
                    : 'Report issues and track their resolution.',
                style: text.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: unread > 0 ? '$unread new updates' : 'Updates',
          style: IconButton.styleFrom(backgroundColor: AppColors.surface),
          onPressed: () => context.push(Routes.activity),
          icon: Badge(
            isLabelVisible: unread > 0,
            smallSize: 9,
            backgroundColor: AppColors.danger,
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.go(Routes.profile),
          child: UserAvatar(user: user, size: 48),
        ),
      ],
    );
  }
}

/// Purple banner with the main call to action.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.staff,
    required this.onReport,
    required this.onReview,
  });

  final bool staff;
  final VoidCallback onReport;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroStart, AppColors.heroEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            top: 0,
            child: Icon(
              Icons.account_balance_rounded,
              size: 96,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staff ? 'New reports\nneed review' : 'See an issue\non campus?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                staff
                    ? 'Pick up submitted reports and keep\nstudents informed.'
                    : 'Report it and help improve\nour learning environment.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: staff ? onReview : onReport,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            staff
                                ? Icons.fact_check_outlined
                                : Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            staff ? 'Review Reports' : 'Report an Issue',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});

  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.incidents, required this.staff});

  final List<Incident> incidents;
  final bool staff;

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: staff ? 'No reports yet' : 'You have no reports yet',
        message: staff
            ? 'New reports from students will appear here.'
            : 'When you report an issue, you can follow its progress here.',
      );
    }
    return Column(
      children: [
        for (final incident in incidents)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IncidentCard(
              incident: incident,
              onTap: () => context.push(Routes.incident(incident.id)),
            ),
          ),
      ],
    );
  }
}
