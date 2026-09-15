import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/event_provider.dart';
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
  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final masjidId = AppData.selectedMasjid?.id ?? '';
    if (masjidId.isNotEmpty) {
      await context.read<EventProvider>().loadEvents(masjidId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final masjidId = AppData.selectedMasjid?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.eventManagementTitle)),
        backgroundColor: ColorPalette.primary,
        elevation: 2,
      ),
      floatingActionButton: masjidId.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showEventDialog(context),
              backgroundColor: ColorPalette.primary,
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
    final events =
        context.watch<EventProvider>().getEventsByMasjid(masjidId);

    if (events.isEmpty) {
      return EmptyState(
        icon: Icons.event_outlined,
        title: appLocalization.t(AppStrings.noEvents),
        subtitle: appLocalization.t(AppStrings.eventsWillAppearHere),
        actionLabel: appLocalization.t(AppStrings.createEvent),
        onAction: () => _showEventDialog(context),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return _EventCard(
            event: event,
            onEditTap: () => _showEventDialog(context, existing: event),
            onDeleteTap: () => _confirmDelete(context, event),
          );
        },
      ),
    );
  }

  /// Confirm delete with a dialog
  Future<void> _confirmDelete(BuildContext context, Event event) async {
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

    final masjidId = AppData.selectedMasjid?.id ?? '';
    final success =
        await context.read<EventProvider>().deleteEvent(masjidId, event.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? appLocalization.t(AppStrings.eventDeleted)
              : appLocalization.t(AppStrings.errorOccurredMsg),
        ),
        backgroundColor:
            success ? ColorPalette.success : ColorPalette.error,
      ),
    );
  }

  /// Show dialog to add or edit an event
  Future<void> _showEventDialog(BuildContext context, {Event? existing}) async {
    final result = await showDialog<Event>(
      context: context,
      builder: (_) => _EventFormDialog(existing: existing),
    );

    if (result == null || !mounted) return;

    final masjidId = AppData.selectedMasjid?.id ?? '';
    final masjidName = AppData.selectedMasjid?.name ?? '';

    final eventToSave = Event(
      id: existing?.id ?? '',
      title: result.title,
      description: result.description,
      masjidId: masjidId,
      masjidName: masjidName,
      eventDate: result.eventDate,
      startTime: result.startTime,
      endTime: result.endTime,
      location: result.location,
      category: result.category,
    );

    final provider = context.read<EventProvider>();
    final success = existing == null
        ? await provider.addEvent(eventToSave)
        : await provider.updateEvent(masjidId, eventToSave);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? appLocalization.t(AppStrings.changesSaved)
              : appLocalization.t(AppStrings.errorOccurredMsg),
        ),
        backgroundColor:
            success ? ColorPalette.success : ColorPalette.error,
      ),
    );
  }
}

/// Card displaying an event in the admin events list
class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  const _EventCard({
    required this.event,
    required this.onEditTap,
    required this.onDeleteTap,
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
                      color: ColorPalette.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      event.category!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  _formatDate(event.eventDate),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${event.startTime} - ${event.endTime}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
            if (event.location != null && event.location!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.location!,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.grey),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEditTap,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(appLocalization.t(AppStrings.edit)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorPalette.primary,
                      side: BorderSide(color: ColorPalette.primary),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// Dialog form for creating or editing an event
class _EventFormDialog extends StatefulWidget {
  final Event? existing;

  const _EventFormDialog({this.existing});

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

  static const _categories = ['Class', 'Talk', 'Gathering', 'Lecture'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _locationController =
        TextEditingController(text: existing?.location ?? '');
    _categoryController =
        TextEditingController(text: existing?.category ?? '');
    _eventDate = existing?.eventDate ?? DateTime.now();
    _startTime = _parseTime(existing?.startTime) ??
        const TimeOfDay(hour: 10, minute: 0);
    _endTime = _parseTime(existing?.endTime) ??
        const TimeOfDay(hour: 12, minute: 0);
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
      final period =
          rest.length > 1 ? rest[1].toUpperCase() : 'AM';
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

  void _save() {
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
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
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
                  decoration: InputDecoration(
                    labelText: appLocalization.t(AppStrings.eventTitle),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: appLocalization.t(AppStrings.eventDescription),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
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
                      onPressed: _pickDate,
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
                      onPressed: () => _pickTime(isStart: true),
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
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(appLocalization.t(AppStrings.pick)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
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
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          ))
                      .toList(),
                  onChanged: (value) {
                    _categoryController.text = value ?? '';
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(appLocalization.t(AppStrings.cancel)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.primary,
          ),
          child: Text(appLocalization.t(AppStrings.save)),
        ),
      ],
    );
  }
}
