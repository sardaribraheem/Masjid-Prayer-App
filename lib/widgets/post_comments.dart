import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localization.dart';

/// Comments are loaded only when a reader opens a post's discussion.
class PostComments extends StatefulWidget {
  final String masjidId;
  final String postId;
  const PostComments({super.key, required this.masjidId, required this.postId});
  @override
  State<PostComments> createState() => _PostCommentsState();
}

class _PostCommentsState extends State<PostComments> {
  final _text = TextEditingController();
  bool _open = false;
  bool _saving = false;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;
  String label(String en, String ur) => appLocalization.isRTL ? ur : en;
  CollectionReference<Map<String, dynamic>> get _comments => FirebaseFirestore
      .instance
      .collection('masjids')
      .doc(widget.masjidId)
      .collection('questions')
      .doc(widget.postId)
      .collection('comments');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = context.read<AuthProvider>().currentUser;
    final text = _text.text.trim();
    if (_saving || user == null || text.isEmpty || text.length > 1000) return;
    setState(() => _saving = true);
    try {
      await _comments.add({
        'text': text,
        'createdByUid': user.id,
        'userName': user.username,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) _text.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              label(
                'Could not send comment. Please try again.',
                'تبصرہ نہیں بھیجا جا سکا۔ دوبارہ کوشش کریں۔',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.postId.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(label('Comments', 'تبصرے')),
          onPressed: () => setState(() {
            _open = !_open;
            _stream = _open
                ? _comments
                      .orderBy('timestamp', descending: true)
                      .limit(30)
                      .snapshots()
                : null;
          }),
        ),
        if (_open) ...[
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  label('Could not load comments.', 'تبصرے لوڈ نہیں ہو سکے۔'),
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(data['userName'] as String? ?? ''),
                    subtitle: Text(data['text'] as String? ?? ''),
                  );
                }).toList(),
              );
            },
          ),
          if (context.watch<AuthProvider>().isLoggedIn) ...[
            TextField(
              controller: _text,
              enabled: !_saving,
              maxLength: 1000,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: label('Write a comment', 'تبصرہ لکھیں'),
              ),
            ),
            TextButton(
              onPressed: _saving ? null : _send,
              child: Text(
                label(
                  _saving ? 'Sending…' : 'Send',
                  _saving ? 'بھیجا جا رہا ہے…' : 'بھیجیں',
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
