import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/masjid_provider.dart';
import '../providers/prayer_reminder_provider.dart';

/// Keep reminders synchronized independently of which tab is open.
class PrayerReminderBinding extends StatefulWidget {
  final Widget child;
  final String locale;
  const PrayerReminderBinding({
    super.key,
    required this.child,
    required this.locale,
  });
  @override
  State<PrayerReminderBinding> createState() => _PrayerReminderBindingState();
}

class _PrayerReminderBindingState extends State<PrayerReminderBinding>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _configure() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      unawaited(
        context.read<PrayerReminderProvider>().configure(
          context.read<MasjidProvider>().selectedMasjid ??
              AppData.selectedMasjid,
          widget.locale,
        ),
      );
    }
  });
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(covariant PrayerReminderBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale) _configure();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(context.read<PrayerReminderProvider>().refresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<MasjidProvider>();
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
