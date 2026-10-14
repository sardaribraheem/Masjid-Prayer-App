import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_data.dart';
import '../providers/masjid_provider.dart';
import '../providers/location_provider.dart';
import '../l10n/app_localization.dart';
import '../l10n/app_strings.dart';
import '../widgets/shared/empty_state.dart';
import 'main_navigation_screen.dart';

class MasjidSelectionScreen extends StatefulWidget {
  final bool isPicker;
  const MasjidSelectionScreen({super.key, this.isPicker = false});
  @override
  State<MasjidSelectionScreen> createState() => _MasjidSelectionScreenState();
}

class _MasjidSelectionScreenState extends State<MasjidSelectionScreen> {
  final _search = TextEditingController();
  bool _selecting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MasjidProvider>().searchQuery = '';
        context.read<MasjidProvider>().loadMasjids();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _location() async {
    final location = context.read<LocationProvider>();
    final masjids = context.read<MasjidProvider>();
    final found = await location.requestLocation();
    if (!mounted) return;
    if (found) {
      await masjids.loadMasjidsWithLocation(
        location.latitude!,
        location.longitude!,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalization.t('location_optional'))),
      );
    }
  }

  Future<void> _select(Masjid masjid) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      await context.read<MasjidProvider>().selectMasjid(masjid);
      if (!mounted) return;
      if (widget.isPicker) {
        Navigator.pop(context, masjid);
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _selecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalization.t('feed_error'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MasjidProvider>();
    final location = context.watch<LocationProvider>();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(appLocalization.t(AppStrings.selectMasjid))),
      body: RefreshIndicator(
        onRefresh: provider.loadMasjids,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(
              appLocalization.t('choose_masjid_heading'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              appLocalization.t('choose_masjid_subtitle'),
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _search,
              onChanged: (value) => provider.searchQuery = value,
              decoration: InputDecoration(
                hintText: appLocalization.t(AppStrings.searchMasjidByName),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: appLocalization.t('clear'),
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _search.clear();
                    provider.searchQuery = '';
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: location.isLoading ? null : _location,
                icon: const Icon(Icons.my_location, size: 20),
                label: Text(
                  appLocalization.t(
                    location.isLoading
                        ? AppStrings.gettingYourLocation
                        : 'use_location',
                  ),
                ),
              ),
            ),
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.error != null)
              EmptyState(
                icon: Icons.cloud_off_outlined,
                title: appLocalization.t('feed_error'),
                actionLabel: appLocalization.t(AppStrings.refresh),
                onAction: provider.loadMasjids,
              )
            else if (provider.filteredMasjids.isEmpty)
              EmptyState(
                icon: Icons.mosque_outlined,
                title: appLocalization.t(AppStrings.noMasjidsFound),
                subtitle: appLocalization.t(AppStrings.tryAdjustingYourSearch),
                actionLabel: appLocalization.t(AppStrings.refresh),
                onAction: provider.loadMasjids,
              )
            else
              ...provider.filteredMasjids.map(
                (masjid) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      leading: Icon(
                        Icons.mosque_outlined,
                        color: scheme.primary,
                        size: 28,
                      ),
                      title: Text(
                        appLocalization.isRTL && masjid.nameUrdu.isNotEmpty
                            ? masjid.nameUrdu
                            : masjid.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(masjid.location),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selecting ? null : () => _select(masjid),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
