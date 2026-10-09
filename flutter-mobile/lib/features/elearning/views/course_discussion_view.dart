import 'dart:async';

import 'package:flutter/material.dart';
import '../models/elearning_model.dart';
import '../repositories/elearning_repository.dart';

const Color _discussionGreen = Color(0xFF059669);
const Color _discussionBackground = Color(0xFFF8FAFC);

class CourseDiscussionView extends StatefulWidget {
  final int courseId;
  final String courseTitle;
  final String authToken;
  final ElearningRepository repository;

  const CourseDiscussionView({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.authToken,
    required this.repository,
  });

  @override
  State<CourseDiscussionView> createState() => _CourseDiscussionViewState();
}

class _CourseDiscussionViewState extends State<CourseDiscussionView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<CourseMessage> _messages = [];
  Timer? _refreshTimer;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isFetching = false;
  bool _hasLoaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _loadMessages(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_isFetching || (silent && !_hasLoaded)) return;
    _isFetching = true;
    final wasNearBottom =
        !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            120;
    if (!_hasLoaded) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final messages = await widget.repository.getCourseMessages(
        widget.authToken,
        widget.courseId,
      );
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
        _isLoading = false;
        _hasLoaded = true;
        _loadError = null;
      });
      if (wasNearBottom) _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      _isFetching = false;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await widget.repository.sendCourseMessage(
        widget.authToken,
        widget.courseId,
        body,
      );
      if (!mounted) return;
      _messageController.clear();
      await _loadMessages();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _discussionBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diskusi Kursus',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              widget.courseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_isLoading && !_hasLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: _discussionGreen),
      );
    }
    if (_loadError != null && !_hasLoaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, color: Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              Text(_loadError!, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_loadError != null && _hasLoaded)
          Material(
            color: const Color(0xFFFFF7ED),
            child: ListTile(
              dense: true,
              leading: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFEA580C),
              ),
              title: Text(_loadError!, style: const TextStyle(fontSize: 12)),
            ),
          ),
        Expanded(
          child: _messages.isEmpty
              ? ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    Center(
                      child: Icon(
                        Icons.forum_outlined,
                        size: 42,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: Text(
                        'Belum ada diskusi.\nMulai percakapan di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _buildMessageBubble(_messages[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(CourseMessage message) {
    final own = message.isOwn;
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: own ? _discussionGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(own ? 16 : 4),
            bottomRight: Radius.circular(own ? 4 : 16),
          ),
          border: own ? null : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!own) ...[
              Text(
                message.authorName,
                style: const TextStyle(
                  color: _discussionGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.body,
              style: TextStyle(
                color: own ? Colors.white : const Color(0xFF1E293B),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: own ? Colors.white70 : const Color(0xFF94A3B8),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Tulis pesan diskusi...',
                  counterText: '',
                  filled: true,
                  fillColor: _discussionBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              tooltip: 'Kirim pesan',
              style: IconButton.styleFrom(
                backgroundColor: _discussionGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final local = dateTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
