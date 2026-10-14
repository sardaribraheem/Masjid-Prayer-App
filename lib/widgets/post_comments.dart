import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localization.dart';
import 'app_icon.dart';

class PostComments extends StatefulWidget {
  final String masjidId;
  final String postId;
  const PostComments({super.key, required this.masjidId, required this.postId});
  @override
  State<PostComments> createState() => _PostCommentsState();
}

class _PostCommentsState extends State<PostComments>
    with AutomaticKeepAliveClientMixin<PostComments> {
  @override
  bool get wantKeepAlive => _open;
  final _text = TextEditingController();
  bool _open = false;
  bool _saving = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _browsingOlder = false;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _older = [];
  QuerySnapshot<Map<String, dynamic>>? _head;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  String label(String en, String ur) => appLocalization.isRTL ? ur : en;
  CollectionReference<Map<String, dynamic>> get _comments => FirebaseFirestore
      .instance
      .collection('masjids')
      .doc(widget.masjidId)
      .collection('questions')
      .doc(widget.postId)
      .collection('comments');
  Query<Map<String, dynamic>> get _query => _comments
      .orderBy('timestamp', descending: true)
      .orderBy(FieldPath.documentId, descending: true);
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _refresh() {
    _browsingOlder = false;
    _older.clear();
    _cursor = null;
    _head = null;
    _hasMore = false;
    _stream = _query.limit(31).snapshots();
  }

  Future<void> _more() async {
    if (_loadingMore || _cursor == null || _head == null) return;
    final cursor = _cursor!;
    setState(() {
      _browsingOlder = true;
      _loadingMore = true;
      _stream = Stream.value(_head!);
    });
    try {
      final page = await _query.startAfterDocument(cursor).limit(31).get();
      if (!mounted) return;
      setState(() {
        _older.addAll(page.docs.take(30));
        _hasMore = page.docs.length > 30;
        if (_older.isNotEmpty) _cursor = _older.last;
      });
    } catch (_) {
      if (mounted) _error();
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _error() => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(appLocalization.t('feed_error'))));
  Future<void> _send() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final text = _text.text.trim();
    if (_saving ||
        !auth.isLoggedIn ||
        user == null ||
        text.isEmpty ||
        text.length > 1000) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _comments.add({
        'text': text,
        'createdByUid': user.id,
        'userName': user.username,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _text.clear();
        setState(_refresh);
      }
    } catch (_) {
      if (mounted) _error();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(DocumentReference<Map<String, dynamic>> ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label('Delete comment?', 'تبصرہ حذف کریں؟')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLocalization.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(appLocalization.t('delete_content')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.delete();
      if (mounted) setState(_refresh);
    } catch (_) {
      if (mounted) _error();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = context.watch<AuthProvider>();
    if (widget.postId.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          icon: const AppIcon('community', size: 18),
          label: Text(label('Comments', 'تبصرے')),
          onPressed: () => setState(() {
            _open = !_open;
            if (_open) {
              _refresh();
            } else {
              _stream = null;
            }
            updateKeepAlive();
          }),
        ),
        if (_open) ...[
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return TextButton(
                  onPressed: () => setState(_refresh),
                  child: Text(appLocalization.t('feed_error')),
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final head = snapshot.data!;
              _head = head;
              if (!_browsingOlder && !_loadingMore) {
                _hasMore = head.docs.length > 30;
                _cursor = head.docs.take(30).lastOrNull;
              }
              final docs = [...head.docs.take(30), ..._older];
              final unique = {for (final doc in docs) doc.id: doc}.values;
              return Column(
                children: [
                  if (unique.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(appLocalization.t('no_comments')),
                    ),
                  ...unique.map((doc) {
                    final data = doc.data();
                    final canDelete =
                        auth.isLoggedIn &&
                        (data['createdByUid'] == auth.currentUser?.id ||
                            auth.currentUser?.canManageMasjid(
                                  widget.masjidId,
                                ) ==
                                true ||
                            auth.isSuperAdmin);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        data['userName'] as String? ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(data['text'] as String? ?? ''),
                      trailing: canDelete
                          ? IconButton(
                              tooltip: appLocalization.t('delete_content'),
                              onPressed: () => _delete(doc.reference),
                              icon: const Icon(Icons.delete_outline, size: 20),
                            )
                          : null,
                    );
                  }),
                  if (_hasMore || _loadingMore)
                    TextButton(
                      onPressed: _loadingMore ? null : _more,
                      child: Text(appLocalization.t('load_more')),
                    ),
                ],
              );
            },
          ),
          if (auth.isLoggedIn) ...[
            TextField(
              controller: _text,
              enabled: !_saving,
              maxLength: 1000,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: label('Write a comment', 'تبصرہ لکھیں'),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: _saving ? null : _send,
                child: Text(
                  label(
                    _saving ? 'Sending…' : 'Send',
                    _saving ? 'بھیجا جا رہا ہے…' : 'بھیجیں',
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
