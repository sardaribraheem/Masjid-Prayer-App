import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Client-side, retryable cleanup for the current MVP collections.
/// The deletion marker freezes contributions; completed batches stay deleted
/// after an interruption. The user document is removed only after content.
class AccountDeletionService {
  final FirebaseFirestore _firestore;
  AccountDeletionService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> removeFirestoreData(User user) async {
    final profileRef = _firestore.collection('users').doc(user.uid);
    final profile = await profileRef.get(
      const GetOptions(source: Source.server),
    );
    final token = await user.getIdTokenResult(true);
    if (token.claims?['superAdmin'] == true ||
        ['imam', 'admin'].contains(profile.data()?['role'])) {
      throw StateError(
        'Transfer masjid management through the administrator before deleting this account.',
      );
    }
    if (profile.exists && profile.data()?['deletionRequestedAt'] == null) {
      await profileRef.update({
        'deletionRequestedAt': FieldValue.serverTimestamp(),
      });
    }
    // Delete descendants before their parent so ownership remains provable.
    await _removeOwnedGroup(
      'questions',
      user.uid,
      beforeDelete: (post) async {
        await _removeQuery(post.collection('comments'));
      },
    );
    await _removeOwnedGroup('comments', user.uid);
    await _removeOwnedGroup('events', user.uid);
    await _removeQuery(
      _firestore
          .collection('claimRequests')
          .where('imamUid', isEqualTo: user.uid),
    );
    // Failure here must stop Auth deletion. On an Auth failure after this point,
    // retrying cleanup works even though the profile is already absent.
    if (profile.exists) await profileRef.delete();
  }

  Future<void> _removeOwnedGroup(
    String group,
    String uid, {
    Future<void> Function(DocumentReference<Map<String, dynamic>>)?
    beforeDelete,
  }) async {
    final query = _firestore
        .collectionGroup(group)
        .where('createdByUid', isEqualTo: uid);
    await _removeQuery(query, beforeDelete: beforeDelete);
  }

  Future<void> _removeQuery(
    Query<Map<String, dynamic>> query, {
    Future<void> Function(DocumentReference<Map<String, dynamic>>)?
    beforeDelete,
  }) async {
    while (true) {
      final page = await query
          .limit(100)
          .get(const GetOptions(source: Source.server));
      if (page.docs.isEmpty) return;
      for (final document in page.docs) {
        if (beforeDelete != null) await beforeDelete(document.reference);
      }
      final batch = _firestore.batch();
      for (final document in page.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
  }
}
