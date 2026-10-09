import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/app_data.dart';
import '../providers/masjid_claim_provider.dart';
import '../repositories/masjid_repository.dart';
import '../theme/app_theme.dart';

/// Screen for Imam to claim an existing masjid or register a new one.
class ClaimMasjidScreen extends StatefulWidget {
  const ClaimMasjidScreen({super.key});

  @override
  State<ClaimMasjidScreen> createState() => _ClaimMasjidScreenState();
}

class _ClaimMasjidScreenState extends State<ClaimMasjidScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  List<Masjid> _allMasjids = [];
  List<Masjid> _searchResults = [];
  bool _showRegistrationForm = false;
  bool _isLoadingResults = false;

  @override
  void initState() {
    super.initState();
    _loadMasjids();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadMasjids() async {
    setState(() => _isLoadingResults = true);
    final repo = MasjidRepository();
    _allMasjids = await repo.getAllMasjids();
    if (_allMasjids.isEmpty) {
      _allMasjids = List.from(AppData.allMasjids);
    }
    if (mounted) setState(() => _isLoadingResults = false);
  }

  void _searchMasjids(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _searchResults = _allMasjids
          .where(
            (m) =>
                m.name.toLowerCase().contains(q) ||
                m.location.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  Future<void> _submitClaim(Masjid masjid) async {
    if (context.read<MasjidClaimProvider>().isLoading) return;
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      return;
    }

    final provider = context.read<MasjidClaimProvider>();
    final success = await provider.claimMasjid(
      masjidId: masjid.id,
      imamUid: user.uid,
      imamName: user.displayName ?? user.email ?? 'Unknown',
      imamEmail: user.email ?? '',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Claim request submitted! Super admin will review it.'
                : 'Failed to submit claim: ${provider.error ?? ""}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  Future<void> _submitNewMasjid() async {
    if (context.read<MasjidClaimProvider>().isLoading) return;
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final provider = context.read<MasjidClaimProvider>();
    final success = await provider.registerNewMasjid(
      imamUid: user.uid,
      imamName: user.displayName ?? user.email ?? 'Unknown',
      imamEmail: user.email ?? '',
      masjidName: _nameController.text.trim(),
      masjidLocation: _locationController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Registration request submitted! Super admin will review it.'
                : 'Failed to submit: ${provider.error ?? ""}',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim or Register Masjid'),
        backgroundColor: ColorPalette.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search existing masjids
            Text(
              'Search for your masjid',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Type masjid name or area...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchMasjids,
            ),
            const SizedBox(height: 16),

            if (_isLoadingResults)
              const Center(child: CircularProgressIndicator()),

            // Search results
            ..._searchResults.map(
              (masjid) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(
                    Icons.mosque,
                    color: ColorPalette.primary,
                  ),
                  title: Text(masjid.name),
                  subtitle: Text(masjid.location),
                  trailing: ElevatedButton(
                    onPressed: () => _submitClaim(masjid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorPalette.primary,
                    ),
                    child: const Text('Claim'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Toggle registration form
            Row(
              children: [
                Text(
                  "Can't find your masjid?",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_showRegistrationForm)
              ElevatedButton.icon(
                onPressed: () => setState(() => _showRegistrationForm = true),
                icon: const Icon(Icons.add),
                label: const Text('Register New Masjid'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.secondary,
                ),
              )
            else ...[
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Masjid Name',
                  prefixIcon: const Icon(Icons.mosque),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location/Area',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitNewMasjid,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Registration Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
