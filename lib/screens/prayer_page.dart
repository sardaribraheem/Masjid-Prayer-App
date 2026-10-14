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
import '../widgets/app_icon.dart';
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
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E47),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppIcon('prayer', color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              appLocalization.t(AppStrings.nextPrayer),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        name(next.prayer.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        next.prayer.time,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${next.at.difference(now).inHours} ${appLocalization.t(AppStrings.hoursRemaining)} · ${next.at.difference(now).inMinutes % 60} ${appLocalization.t(AppStrings.minutesRemaining)}',
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
              Card(
                child: Column(
                  children: prayers
                      .map(
                        (prayer) => ListTile(
                          leading: AppIcon(
                            [
                                  'sunrise',
                                  'sunset',
                                ].contains(prayer.name.toLowerCase())
                                ? 'sun'
                                : 'prayer',
                            color: scheme.primary,
                          ),
                          title: Text(name(prayer.name)),
                          trailing: Text(
                            parsePrayerMinutes(prayer.time) == null
                                ? appLocalization.t(AppStrings.notSet)
                                : prayer.time,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
