import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/masjid_claim_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localization.dart';
import '../repositories/masjid_repository.dart';
import '../theme/app_theme.dart';

/// Super Admin Dashboard for reviewing and approving/rejecting claim requests.
class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AuthProvider>().isSuperAdmin) {
        context.read<MasjidClaimProvider>().loadPendingRequests();
      }
    });
  }

  Future<void> _approve(ClaimRequest request) async {
    if (context.read<MasjidClaimProvider>().isLoading) return;
    final claimProvider = context.read<MasjidClaimProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await claimProvider.approveRequest(request.id);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(success ? 'Request approved!' : 'Failed to approve'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _reject(ClaimRequest request) async {
    if (context.read<MasjidClaimProvider>().isLoading) return;
    final success = await context.read<MasjidClaimProvider>().rejectRequest(
      request.id,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Request rejected' : 'Failed to reject'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().isSuperAdmin) {
      return Scaffold(
        body: Center(
          child: Text(appLocalization.t('super_admin_access_required')),
        ),
      );
    }
    final provider = context.watch<MasjidClaimProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin'),
        backgroundColor: ColorPalette.primary,
        elevation: 0,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(appLocalization.t('request_load_failed')),
                  TextButton(
                    onPressed: provider.loadPendingRequests,
                    child: Text(appLocalization.t('refresh')),
                  ),
                ],
              ),
            )
          : provider.pendingRequests.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'No pending requests',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: provider.loadPendingRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = provider.pendingRequests[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: ColorPalette.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.imamName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      request.imamEmail,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  request.status,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          if (request.isNewMasjidRequest) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.mosque,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'New Masjid: ${request.masjidName ?? "Unknown"}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Location: ${request.masjidLocation ?? "Unknown"}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Claiming masjid ID: ${request.masjidId ?? "Unknown"}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _reject(request),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _approve(request),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
