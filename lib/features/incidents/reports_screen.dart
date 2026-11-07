import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/incident_category.dart';
import '../../data/models/incident_status.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/incident_card.dart';
import '../auth/auth_providers.dart';
import 'incident_providers.dart';

/// Browse every report on campus, with search and filters.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(incidentFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(
      currentUserProvider.select((u) => u.value?.isStaff ?? false),
    );
    final filter = ref.watch(incidentFilterProvider);
    final notifier = ref.read(incidentFilterProvider.notifier);
    final results = ref.watch(filteredIncidentsProvider);

    // Keep the text box in sync when filters are cleared elsewhere.
    ref.listen(incidentFilterProvider.select((f) => f.query), (_, query) {
      if (_search.text != query) _search.text = query;
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(staff ? 'All Reports' : 'Reports'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _search,
              onChanged: notifier.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by title, place or details',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => notifier.setQuery(''),
                      ),
              ),
            ),
          ),
          if (!staff)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: false, label: Text('All campus')),
                    ButtonSegment(value: true, label: Text('My reports')),
                  ],
                  selected: {filter.mineOnly},
                  onSelectionChanged: (s) => notifier.setMineOnly(s.first),
                ),
              ),
            ),
          _ChipRow(
            children: [
              _FilterChip(
                label: 'All',
                selected: filter.status == null,
                onTap: () => notifier.setStatus(null),
              ),
              for (final s in IncidentStatus.values)
                _FilterChip(
                  label: s.label,
                  selected: filter.status == s,
                  onTap: () =>
                      notifier.setStatus(filter.status == s ? null : s),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _ChipRow(
            children: [
              for (final c in IncidentCategory.values)
                _FilterChip(
                  label: c.label,
                  icon: c.icon,
                  selected: filter.category == c,
                  outlined: true,
                  onTap: () =>
                      notifier.setCategory(filter.category == c ? null : c),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load reports',
                message: 'Check your connection and try again.',
                action: TextButton(
                  onPressed: () => ref.invalidate(allIncidentsProvider),
                  child: const Text('Retry'),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return ListView(
                    children: [
                      EmptyState(
                        icon: filter.isActive
                            ? Icons.search_off_rounded
                            : Icons.inbox_outlined,
                        title: filter.isActive
                            ? 'No matching reports'
                            : 'No reports yet',
                        message: filter.isActive
                            ? 'Try a different search or clear the filters.'
                            : 'Reports submitted on campus will show up here.',
                        action: filter.isActive
                            ? TextButton(
                                onPressed: notifier.clear,
                                child: const Text('Clear filters'),
                              )
                            : null,
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allIncidentsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Text(
                          '${items.length} ${items.length == 1 ? 'report' : 'reports'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      final incident = items[i - 1];
                      return IncidentCard(
                        incident: incident,
                        onTap: () => context.push(Routes.incident(incident.id)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.primary
        : (outlined ? AppColors.surface : AppColors.primaryLight);
    final fg = selected ? Colors.white : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: outlined && !selected
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
