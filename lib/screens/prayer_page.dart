import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/auth_provider.dart';
import '../providers/masjid_provider.dart';
import '../services/firebase_service.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../utils/prayer_schedule.dart';
import '../widgets/shared/empty_state.dart';
import 'admin_panel_screen.dart';

class PrayerPage extends StatefulWidget {
  const PrayerPage({super.key});
  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage> {
  Timer? _timer;
  String? _masjidId;
  Stream<Masjid?>? _stream;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id =
        (context.watch<MasjidProvider>().selectedMasjid ??
                AppData.selectedMasjid)
            ?.id;
    if (id != _masjidId) {
      _masjidId = id;
      _stream = id == null ? null : FirebaseService().getMasjidStream(id);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String name(String value) => appLocalization.t(value.toLowerCase());

  String _remainingText(Duration remaining) {
    final minutes = remaining.inMinutes % 60;
    final minuteLabel = appLocalization.t(
      minutes == 1 ? AppStrings.minuteRemaining : AppStrings.minutesRemaining,
    );
    if (remaining.inHours == 0) return '$minutes $minuteLabel';
    final hours = remaining.inHours;
    final hourLabel = appLocalization.t(
      hours == 1 ? AppStrings.hourRemaining : AppStrings.hoursRemaining,
    );
    return '$hours $hourLabel · $minutes $minuteLabel';
  }

  Widget _prayerIcon(String prayerName, {double size = 24, Color? color}) {
    final (icon, lightColor, darkColor) = switch (prayerName.toLowerCase()) {
      'fajr' || 'sunrise' => (
        Icons.wb_twilight_rounded,
        const Color(0xFFA56918),
        const Color(0xFFEBC582),
      ),
      'dhuhr' => (
        Icons.wb_sunny_outlined,
        const Color(0xFF926514),
        const Color(0xFFF1D37B),
      ),
      'asr' => (
        Icons.brightness_6_outlined,
        const Color(0xFFA46424),
        const Color(0xFFE7B578),
      ),
      'maghrib' || 'sunset' => (
        Icons.wb_twilight_rounded,
        const Color(0xFFB45D3B),
        const Color(0xFFEEAA8A),
      ),
      'isha' => (
        Icons.dark_mode_outlined,
        const Color(0xFF526B9B),
        const Color(0xFFAABFE6),
      ),
      'jummah' => (
        Icons.mosque_outlined,
        const Color(0xFF1B5E47),
        const Color(0xFFA2D9BA),
      ),
      _ => (
        Icons.schedule_outlined,
        const Color(0xFF1B5E47),
        const Color(0xFFA2D9BA),
      ),
    };
    return ExcludeSemantics(
      child: Icon(
        icon,
        size: size,
        color:
            color ??
            (Theme.of(context).brightness == Brightness.dark
                ? darkColor
                : lightColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appLocalization,
    builder: (context, _) => _buildLocalized(context),
  );

  Widget _buildLocalized(BuildContext context) {
    final selected =
        context.watch<MasjidProvider>().selectedMasjid ??
        AppData.selectedMasjid;
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalization.t(AppStrings.prayerTimes)),
        actions: [
          if (auth.currentUser?.canManageMasjid(selected?.id) == true)
            IconButton(
              tooltip: appLocalization.t(AppStrings.editPrayerTimes),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              ),
            ),
        ],
      ),
      body: StreamBuilder<Masjid?>(
        stream: _stream,
        initialData: selected,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_outlined,
              title: appLocalization.t('feed_error'),
              actionLabel: appLocalization.t(AppStrings.refresh),
              onAction: () => setState(
                () => _stream = FirebaseService().getMasjidStream(_masjidId!),
              ),
            );
          }
          final masjid = snapshot.data;
          if (masjid == null) {
            return EmptyState(
              icon: Icons.mosque_outlined,
              title: appLocalization.t(AppStrings.noMasjidSelected),
            );
          }
          final now = DateTime.now();
          final prayers = [...masjid.prayerTimes];
          if (now.weekday == DateTime.friday &&
              parsePrayerMinutes(masjid.jummahTime ?? '') != null) {
            prayers.removeWhere((p) => p.name.toLowerCase() == 'dhuhr');
            prayers.add(PrayerTime(name: 'Jummah', time: masjid.jummahTime!));
          }
          prayers.sort(
            (a, b) => (parsePrayerMinutes(a.time) ?? 1440).compareTo(
              parsePrayerMinutes(b.time) ?? 1440,
            ),
          );
          final next = nextPrayer(prayers, now);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                appLocalization.isRTL && masjid.nameUrdu.isNotEmpty
                    ? masjid.nameUrdu
                    : masjid.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                masjid.location,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (next == null)
                EmptyState(
                  icon: Icons.schedule,
                  title: appLocalization.t('prayer_unavailable'),
                  subtitle: appLocalization.t('prayer_unavailable_detail'),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E47),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _prayerIcon(next.prayer.name, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              appLocalization.t(AppStrings.nextPrayer),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name(next.prayer.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        next.prayer.time,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _remainingText(next.at.difference(now)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),
              Text(
                appLocalization.t(AppStrings.allPrayers),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...prayers.map(
                (prayer) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          _prayerIcon(prayer.name),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name(prayer.name),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              parsePrayerMinutes(prayer.time) == null
                                  ? appLocalization.t(AppStrings.notSet)
                                  : prayer.time,
                              textDirection: TextDirection.ltr,
                              textAlign: appLocalization.isRTL
                                  ? TextAlign.start
                                  : TextAlign.end,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
