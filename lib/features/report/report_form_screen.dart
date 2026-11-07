import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/campus_locations.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/incident_category.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/labeled_field.dart';
import '../../shared/widgets/primary_button.dart';
import 'photo_picker_field.dart';
import 'submit_report_controller.dart';

/// Lets the camera or gallery be swapped out in tests.
final imagePickerProvider = Provider<ImagePicker>((ref) => ImagePicker());

class ReportFormScreen extends ConsumerStatefulWidget {
  const ReportFormScreen({super.key});

  @override
  ConsumerState<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends ConsumerState<ReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _otherLocation = TextEditingController();

  IncidentCategory? _category;
  String? _location;
  PickedPhoto? _photo;
  var _showCategoryError = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _otherLocation.dispose();
    super.dispose();
  }

  String get _resolvedLocation => _location == otherLocation
      ? _otherLocation.text.trim()
      : (_location ?? '');

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _showCategoryError = _category == null);
    if (!formValid || _category == null) return;
    FocusScope.of(context).unfocus();

    final incident = await ref
        .read(submitReportControllerProvider.notifier)
        .submit(
          ReportDraft(
            category: _category!,
            title: _title.text,
            description: _description.text,
            location: _resolvedLocation,
            photo: _photo,
          ),
        );
    if (incident == null || !mounted) return;
    showMessage(context, 'Report submitted. We will keep you posted.');
    context.pushReplacement(Routes.incident(incident.id));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(submitReportControllerProvider, (_, next) {
      if (next.hasError) {
        showMessage(context, next.error.toString(), error: true);
      }
    });
    final submitting = ref.watch(submitReportControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Incident')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // A Column (not a lazy ListView) keeps every field built, so
          // validate() checks fields that are scrolled off screen too.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel('Select a category'),
                const SizedBox(height: 10),
                _CategoryGrid(
                  selected: _category,
                  onSelected: (c) => setState(() {
                    _category = c;
                    _showCategoryError = false;
                  }),
                ),
                if (_showCategoryError)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'Choose the category that best fits the issue.',
                      style: TextStyle(color: AppColors.danger, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 24),
                LabeledField(
                  label: 'Title',
                  hint: 'Briefly describe the issue...',
                  controller: _title,
                  validator: Validators.text(field: 'Title', min: 3, max: 80),
                  maxLength: 80,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                LabeledField(
                  label: 'Description',
                  hint:
                      'Provide more details about the issue...\n'
                      'e.g. what happened, when, impact, etc.',
                  controller: _description,
                  validator: Validators.text(
                    field: 'Description',
                    min: 10,
                    max: 1000,
                  ),
                  maxLines: 5,
                  minLines: 4,
                  maxLength: 1000,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                const _SectionLabel('Location'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _location,
                  isExpanded: true,
                  hint: const Text(
                    'Where is the issue?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  validator: (v) => v == null ? 'Choose a location.' : null,
                  items: [
                    for (final place in [...campusLocations, otherLocation])
                      DropdownMenuItem(value: place, child: Text(place)),
                  ],
                  onChanged: (v) => setState(() => _location = v),
                ),
                if (_location == otherLocation) ...[
                  const SizedBox(height: 12),
                  LabeledField(
                    label: 'Describe the location',
                    hint: 'e.g. Block B, Room 204',
                    controller: _otherLocation,
                    validator: Validators.text(
                      field: 'Location',
                      min: 2,
                      max: 80,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
                const SizedBox(height: 24),
                const Text.rich(
                  TextSpan(
                    text: 'Add a photo ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(
                        text: '(optional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                PhotoPickerField(
                  photo: _photo,
                  picker: ref.read(imagePickerProvider),
                  enabled: !submitting,
                  onChanged: (p) => setState(() => _photo = p),
                  onError: (m) => showMessage(context, m, error: true),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Submit Report',
                  loading: submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}

/// Three-column grid of category buttons, as in the mockup.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});

  final IncidentCategory? selected;
  final ValueChanged<IncidentCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        for (final c in IncidentCategory.values)
          _CategoryButton(
            category: c,
            selected: c == selected,
            onTap: () => onSelected(c),
          ),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final IncidentCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: category.label,
      child: Material(
        color: selected ? AppColors.primary : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.icon, color: fg, size: 24),
              const SizedBox(height: 6),
              Text(
                category.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
