import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/event_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/shared/empty_state.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

/// Admin screen for managing masjid events (CRUD)
class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    // Defer past the first frame: loadEvents() notifies synchronously, which
    // would otherwise trigger "setState() called during build".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    if (masjidId.isNotEmpty) {
      await context.read<EventProvider>().loadEvents(
        masjidId,
        includePending: true,
        statusFilter: _filter == 'all' ? null : _filter,
      );
    }
  }

  void _changeFilter(String value) {
    setState(() => _filter = value);
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isSuperAdmin &&
        authProvider.currentUser?.canManageMasjid(AppData.selectedMasjid?.id) !=
            true) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLocalization.t(AppStrings.eventManagementTitle)),
        ),
        body: Center(
          child: Text(appLocalization.t('manager_approval_required')),
        ),
      );
    }
    final masjidId = AppData.selectedMasjid?.id ?? '';

    return Scaffold(
      bottomNavigationBar: context.watch<EventProvider>().hasMore
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton(
                  onPressed: context.watch<EventProvider>().loadingMore
                      ? null
                      : context.read<EventProvider>().loadMore,
                  child: Text(appLocalization.t('load_more')),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.eventManagementTitle)),
        actions: [
          IconButton(
            tooltip: appLocalization.t(AppStrings.refresh),
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: masjidId.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showEventDialog(context),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              icon: const Icon(Icons.add),
              label: Text(appLocalization.t(AppStrings.createEvent)),
            ),
      body: masjidId.isEmpty
          ? Center(child: Text(appLocalization.t(AppStrings.noMasjidSelected2)))
          : context.watch<EventProvider>().isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildEventsList(context, masjidId),
    );
  }

  Widget _buildEventsList(BuildContext context, String masjidId) {
    final provider = context.watch<EventProvider>();
    final allEvents = provider.getEventsByMasjid(masjidId);
    final events = switch (_filter) {
      'pending' => provider.getPendingEventsByMasjid(masjidId),
      'approved' => provider.getApprovedEventsByMasjid(masjidId),
      _ => allEvents,
    };

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: appLocalization.t('all_events'),
                selected: _filter == 'all',
                onTap: () => _changeFilter('all'),
              ),
              _FilterChip(
                label: appLocalization.t('pending'),
                selected: _filter == 'pending',
                onTap: () => _changeFilter('pending'),
              ),
              _FilterChip(
                label: appLocalization.t('approved'),
                selected: _filter == 'approved',
                onTap: () => _changeFilter('approved'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.error != null)
            EmptyState(
              icon: Icons.cloud_off_outlined,
              title: appLocalization.t('feed_error'),
              actionLabel: appLocalization.t(AppStrings.refresh),
              onAction: _loadEvents,
            )
          else if (events.isEmpty)
            EmptyState(
              icon: Icons.event_outlined,
              title: appLocalization.t(AppStrings.noEvents),
              subtitle: appLocalization.t('events_empty_detail'),
            ),
          ...events.map(
            (event) => _EventCard(
              event: event,
              onEditTap: () => _showEventDialog(context, existing: event),
              onDeleteTap: () => _confirmDelete(context, event),
              onApproveTap: () =>
                  _updateEventStatus(context, event, EventStatus.approved),
              onRejectTap: () =>
                  _updateEventStatus(context, event, EventStatus.rejected),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEventStatus(
    BuildContext context,
    Event event,
    EventStatus status,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    final success = await context.read<EventProvider>().updateEventStatus(
      AppData.selectedMasjid?.id ?? '',
      event.id,
      status,
    );

    if (!mounted || scaffoldMessenger == null) return;
    await _loadEvents();
    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          appLocalization.t(success ? 'changes_saved' : 'feed_error'),
        ),
        backgroundColor: success ? ColorPalette.success : ColorPalette.error,
      ),
    );
  }

  /// Confirm delete with a dialog
  Future<void> _confirmDelete(BuildContext context, Event event) async {
    final eventProvider = context.read<EventProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final masjidId = AppData.selectedMasjid?.id ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appLocalization.t(AppStrings.deleteEvent)),
        content: Text(event.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appLocalization.t(AppStrings.cancel)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.error,
            ),
            child: Text(appLocalization.t(AppStrings.delete)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success = await eventProvider.deleteEvent(masjidId, event.id);

    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? appLocalization.t(AppStrings.eventDeleted)
              : appLocalization.t(AppStrings.errorOccurredMsg),
        ),
        backgroundColor: success ? ColorPalette.success : ColorPalette.error,
      ),
    );
  }

  /// The dialog submits before closing, keeping drafts when a write fails.
  Future<void> _showEventDialog(BuildContext context, {Event? existing}) async {
    final provider = context.read<EventProvider>();
    final auth = context.read<AuthProvider>();
    final masjid = AppData.selectedMasjid;
    final user = auth.currentUser;
    if (masjid == null || user == null) return;
    final result = await showDialog<Event>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventFormDialog(
        existing: existing,
        onSubmit: (draft) async {
          if (auth.currentUser?.id != user.id) return false;
          final event = Event(
            id: existing?.id ?? '',
            title: draft.title,
            description: draft.description,
            masjidId: masjid.id,
            masjidName: masjid.name,
            eventDate: draft.eventDate,
            startTime: draft.startTime,
            endTime: draft.endTime,
            location: draft.location,
            category: draft.category,
            mediaUrl: draft.mediaUrl,
            mediaType: draft.mediaType,
            status: existing?.status ?? EventStatus.approved,
            createdByUid: existing != null ? existing.createdByUid : user.id,
            createdByName: existing != null
                ? existing.createdByName
                : user.username,
          );
          return existing == null
              ? provider.addEvent(event)
              : provider.updateEvent(masjid.id, event);
        },
      ),
    );
    if (result != null && context.mounted) {
      await _loadEvents();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalization.t(AppStrings.changesSaved))),
      );
    }
  }
}

/// Card displaying an event in the admin events list
class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;
  final VoidCallback? onApproveTap;
  final VoidCallback? onRejectTap;

  const _EventCard({
    required this.event,
    required this.onEditTap,
    required this.onDeleteTap,
    this.onApproveTap,
    this.onRejectTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (event.category != null && event.category!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      event.category!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  _formatDate(event.eventDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${event.startTime} – ${event.endTime}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.location!,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              event.description,
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (event.status == EventStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApproveTap,
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(appLocalization.t('approve')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRejectTap,
                      icon: const Icon(Icons.close, size: 18),
                      label: Text(appLocalization.t('reject')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorPalette.error,
                        side: BorderSide(color: ColorPalette.error),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditTap,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(appLocalization.t(AppStrings.edit)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDeleteTap,
                    icon: const Icon(Icons.delete, size: 18),
                    label: Text(appLocalization.t(AppStrings.delete)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPalette.error,
                      side: BorderSide(color: ColorPalette.error),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/// Dialog form for creating or editing an event
class _EventFormDialog extends StatefulWidget {
  final Event? existing;

  final Future<bool> Function(Event)? onSubmit;
  const _EventFormDialog({this.existing, this.onSubmit});

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _categoryController;
  late DateTime _eventDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  final _formKey = GlobalKey<FormState>();

  static const _categories = ['Taleem', 'Dars', 'Jammat', 'Gasht', 'Other'];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _locationController = TextEditingController(text: existing?.location ?? '');
    _categoryController = TextEditingController(
      text: _categories.contains(existing?.category)
          ? existing!.category
          : 'Other',
    );
    _eventDate = existing?.eventDate ?? DateTime.now();
    _startTime =
        _parseTime(existing?.startTime) ?? const TimeOfDay(hour: 10, minute: 0);
    _endTime =
        _parseTime(existing?.endTime) ?? const TimeOfDay(hour: 12, minute: 0);
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final cleaned = timeStr.trim();
      final parts = cleaned.split(':');
      if (parts.length != 2) return null;
      int hour = int.parse(parts[0]);
      final rest = parts[1].split(' ');
      final minute = int.parse(rest[0]);
      final period = rest.length > 1 ? rest[1].toUpperCase() : 'AM';
      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return null;
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(1, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final result = Event(
      id: widget.existing?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      masjidId: '',
      masjidName: '',
      eventDate: _eventDate,
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      mediaUrl: widget.existing?.mediaUrl,
      mediaType: widget.existing?.mediaType,
    );
    if (_endTime.hour * 60 + _endTime.minute <=
        _startTime.hour * 60 + _startTime.minute) {
      setState(() => _error = appLocalization.t('event_time_invalid'));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final success = widget.onSubmit == null || await widget.onSubmit!(result);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, result);
      } else {
        setState(() => _error = appLocalization.t('feed_error'));
      }
    } catch (_) {
      if (mounted) setState(() => _error = appLocalization.t('feed_error'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          isEdit
              ? appLocalization.t(AppStrings.editEvent)
              : appLocalization.t(AppStrings.createEvent),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    enabled: !_saving,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: appLocalization.t(AppStrings.eventTitle),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? appLocalization.t(AppStrings.fieldRequired)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_saving,
                    maxLength: 4000,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: appLocalization.t(AppStrings.eventDescription),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? appLocalization.t(AppStrings.fieldRequired)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  // Date picker
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${appLocalization.t(AppStrings.eventDate)}: ${_eventDate.month}/${_eventDate.day}/${_eventDate.year}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(appLocalization.t(AppStrings.pick)),
                      ),
                    ],
                  ),
                  // Time pickers
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${appLocalization.t(AppStrings.start)}: ${_formatTime(_startTime)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _pickTime(isStart: true),
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(appLocalization.t(AppStrings.pick)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${appLocalization.t(AppStrings.end)}: ${_formatTime(_endTime)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => _pickTime(isStart: false),
                        icon: const Icon(Icons.access_time, size: 16),
                        label: Text(appLocalization.t(AppStrings.pick)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    enabled: !_saving,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: appLocalization.t(AppStrings.eventLocation),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categories.contains(_categoryController.text)
                        ? _categoryController.text
                        : null,
                    decoration: InputDecoration(
                      labelText: appLocalization.t(AppStrings.eventCategory),
                      border: const OutlineInputBorder(),
                    ),
                    items: _categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(appLocalization.t(c.toLowerCase())),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) {
                            _categoryController.text = value ?? '';
                          },
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: Text(appLocalization.t(AppStrings.cancel)),
          ),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              appLocalization.t(_saving ? 'submitting' : AppStrings.save),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared form used by the verified member's proposal action.
Future<Event?> showEventProposalForm(
  BuildContext context, {
  required Future<bool> Function(Event) onSubmit,
}) => showDialog<Event>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _EventFormDialog(onSubmit: onSubmit),
);
