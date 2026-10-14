import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localization.dart';

class MemberVerificationScreen extends StatefulWidget {
  final String masjidId;
  const MemberVerificationScreen({super.key, required this.masjidId});
  @override
  State<MemberVerificationScreen> createState() =>
      _MemberVerificationScreenState();
}

class _MemberVerificationScreenState extends State<MemberVerificationScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _requests;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _requests = FirebaseFirestore.instance
        .collection('users')
        .where('masjidId', isEqualTo: widget.masjidId)
        .where('verificationStatus', isEqualTo: 'pending')
        .limit(50)
        .snapshots();
  }

  Future<void> _review(
    DocumentReference<Map<String, dynamic>> ref,
    bool approve,
  ) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.update({
        'role': approve ? 'verified_muqtaddi' : 'muqtaddi',
        'verificationStatus': approve ? 'approved' : 'rejected',
        'eventPermission': approve ? 'approval_required' : 'none',
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLocalization.t('verification_review_failed')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isSuperAdmin &&
        auth.currentUser?.canManageMasjid(widget.masjidId) != true) {
      return Scaffold(
        appBar: AppBar(title: Text(appLocalization.t('review_members'))),
        body: Center(
          child: Text(appLocalization.t('manager_approval_required')),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(appLocalization.t('review_members'))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _requests,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(appLocalization.t('request_load_failed')),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text(appLocalization.t('no_pending_members')));
          }
          return ListView(
            children: snapshot.data!.docs
                .map(
                  (doc) => ListTile(
                    title: Text(doc.data()['username'] as String? ?? ''),
                    subtitle: Text(doc.data()['email'] as String? ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: appLocalization.t('approve'),
                          onPressed: _saving
                              ? null
                              : () => _review(doc.reference, true),
                          icon: const Icon(Icons.check),
                        ),
                        IconButton(
                          tooltip: appLocalization.t('reject'),
                          onPressed: _saving
                              ? null
                              : () => _review(doc.reference, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
