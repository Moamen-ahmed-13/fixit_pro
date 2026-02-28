import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';

/// Usage: Navigator.pushNamed(context, '/chat', arguments: {'orderId': 'xxx', 'otherName': 'اسم الطرف التاني'})
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _chatId {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['orderId'] as String? ?? '';
  }

  String get _otherName {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['otherName'] as String? ?? 'المحادثة';
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _chatId.isEmpty) return;
    setState(() => _sending = true);
    _msgCtrl.clear();

    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update last message on chat doc
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .set({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'orderId': _chatId,
    }, SetOptions(merge: true));

    setState(() => _sending = false);

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        foregroundColor: AppColors.textMain,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('👨‍🔧', style: TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherName,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const Text(
                  'متاح',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // ── Messages ──────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(_chatId)
                    .collection('messages')
                    .orderBy('createdAt')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) return _EmptyChat();

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      final isMe = data['senderId'] == uid;
                      final ts = data['createdAt'] as Timestamp?;
                      final time = ts != null
                          ? '${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}'
                          : '';

                      // Show date separator
                      bool showDate = false;
                      if (i == 0) {
                        showDate = true;
                      } else {
                        final prevData =
                            docs[i - 1].data() as Map<String, dynamic>;
                        final prevTs =
                            prevData['createdAt'] as Timestamp?;
                        if (prevTs != null && ts != null) {
                          final prev = prevTs.toDate();
                          final curr = ts.toDate();
                          if (prev.day != curr.day) showDate = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDate && ts != null)
                            _DateDivider(date: ts.toDate()),
                          _MessageBubble(
                            text: data['text'] as String? ?? '',
                            isMe: isMe,
                            time: time,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // ── Quick Replies ─────────────────────────────────────────
            _QuickReplies(
              onTap: (text) {
                _msgCtrl.text = text;
                _send();
              },
            ),

            // ── Input ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgCard2,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        textDirection: TextDirection.rtl,
                        maxLines: null,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AppColors.textMain,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'اكتب رسالة...',
                          hintStyle: TextStyle(
                            fontFamily: 'Cairo',
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sending ? null : _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _sending
                            ? AppColors.textMuted
                            : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;

  const _MessageBubble(
      {required this.text, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) const SizedBox(width: 48),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topRight: const Radius.circular(18),
                  topLeft: const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                border: Border.all(
                  color: isMe
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13,
                      color: AppColors.textMain,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    String label;
    if (diff == 0) label = 'اليوم';
    else if (diff == 1) label = 'أمس';
    else label = '${date.day}/${date.month}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textMuted,
                )),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  final Function(String) onTap;
  const _QuickReplies({required this.onTap});

  static const _replies = [
    '👍 تمام',
    '⏰ كنت تاخرت شوية',
    '🔧 خلصت',
    '💰 كاش معاك؟',
    '📍 أنا في الطريق',
  ];

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        color: AppColors.bgDark,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemCount: _replies.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => onTap(_replies[i]),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgCard2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                _replies[i],
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
}

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💬', style: TextStyle(fontSize: 52)),
            SizedBox(height: 16),
            Text(
              'ابدأ المحادثة مع الفني',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
}
