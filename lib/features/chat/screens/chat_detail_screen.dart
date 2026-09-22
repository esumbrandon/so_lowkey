import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/utils/platform_adaptive.dart';
import '../../../core/widgets/adaptive_loading.dart';
import '../controllers/chat_controller.dart';
import '../models/message_model.dart';
import '../widgets/graceful_exit_dialog.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String connectionId;
  final String peerAlias;

  const ChatDetailScreen({
    super.key,
    required this.connectionId,
    this.peerAlias = 'So-Lowkey Companion',
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  // Tracks message IDs we've already animated so we only run each once
  final Set<String> _animatedIds = {};

  // Optimistic local messages for instantaneous zero-latency flight animations
  final List<MessageModel> _optimisticMessages = [];

  // Controllers for send button & input field spring interactions
  late final AnimationController _sendIconController;
  late final AnimationController _sendButtonScaleController;
  late final AnimationController _inputFieldScaleController;

  late final Animation<double> _sendButtonScale;
  late final Animation<double> _inputFieldScale;

  @override
  void initState() {
    super.initState();

    _sendIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _sendButtonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _sendButtonScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.80)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.80, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(_sendButtonScaleController);

    _inputFieldScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _inputFieldScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.97)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_inputFieldScaleController);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendIconController.dispose();
    _sendButtonScaleController.dispose();
    _inputFieldScaleController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    AppHaptics.light();

    // Trigger tactile recoil animations on input box and send button
    _sendButtonScaleController.forward(from: 0.0);
    _inputFieldScaleController.forward(from: 0.0);

    // Capture text and clear the input immediately so the text appears
    // to have lifted right out of the message box
    _messageController.clear();

    final myId = isSupabaseConfigured
        ? Supabase.instance.client.auth.currentUser?.id ?? 'me'
        : mockUserId;

    // Create optimistic message for instant flight animation
    final tempId = 'optimistic_${DateTime.now().microsecondsSinceEpoch}';
    final optimisticMsg = MessageModel(
      id: tempId,
      connectionId: widget.connectionId,
      senderId: myId,
      content: trimmed,
      isGracefulExit: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _optimisticMessages.add(optimisticMsg);
      _isSending = true;
    });

    _sendIconController.forward();
    _scrollToBottom(animated: true);

    try {
      await ref
          .read(chatControllerProvider)
          .sendMessage(connectionId: widget.connectionId, content: trimmed);
    } catch (_) {
      if (mounted) {
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send message. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        _sendIconController.reverse();
        setState(() => _isSending = false);
      }
    }
  }

  void _showGracefulExit() {
    GracefulExitDialog.showAdaptive(context, ref, widget.connectionId);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.connectionId));
    final myId = isSupabaseConfigured
        ? Supabase.instance.client.auth.currentUser?.id
        : mockUserId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: const AdaptiveBackButton(fallbackLocation: '/connections'),
        title: Text(widget.peerAlias),
        actions: [
          IconButton(
            icon: const Icon(Icons.spa_outlined),
            tooltip: 'Graceful Exit',
            onPressed: _showGracefulExit,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const ChatMessagesSkeleton(),
              error: (err, st) => const Center(
                child: Text(
                  'Could not load this conversation.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              data: (serverMessages) {
                // Deduplicate: remove any confirmed optimistic messages
                _optimisticMessages.removeWhere((opt) => serverMessages.any(
                    (srv) =>
                        srv.senderId == opt.senderId &&
                        srv.content == opt.content &&
                        srv.createdAt.difference(opt.createdAt).inSeconds.abs() <
                            10));

                // Combine server messages with pending optimistic messages
                final combinedMessages = List<MessageModel>.from(serverMessages);
                for (final opt in _optimisticMessages) {
                  if (!combinedMessages.any((m) => m.id == opt.id)) {
                    combinedMessages.add(opt);
                  }
                }

                if (combinedMessages.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'This is the quiet start of a conversation.\nNo pressure — reply whenever feels right.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                // Initial scroll to bottom
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients &&
                      _scrollController.position.maxScrollExtent > 0 &&
                      _animatedIds.isEmpty) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ClipRect(
                  clipper: const _BottomOverflowClipper(),
                  child: ListView.builder(
                    controller: _scrollController,
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: combinedMessages.length,
                    itemBuilder: (context, index) {
                      final message = combinedMessages[index];
                      final isMine = message.senderId == myId;
                      // Only animate newly appearing messages
                      final isNew = !_animatedIds.contains(message.id);
                      if (isNew) _animatedIds.add(message.id);

                      return _AnimatedMessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        isMine: isMine,
                        animate: isNew,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: ScaleTransition(
                      scale: _inputFieldScale,
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Write at your own pace...',
                          hintStyle:
                              const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Animated tactile send button
                  ScaleTransition(
                    scale: _sendButtonScale,
                    child: _AnimatedSendButton(
                      isSending: _isSending,
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Allows launching message bubbles to overflow below the ListView into the
/// message box area without being clipped, while strictly clipping at the top.
class _BottomOverflowClipper extends CustomClipper<Rect> {
  const _BottomOverflowClipper();

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(-20, 0, size.width + 40, size.height + 160);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

// ── Animated send button ──────────────────────────────────────────────────────

class _AnimatedSendButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback? onPressed;

  const _AnimatedSendButton({
    required this.isSending,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.biscuit,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.biscuit.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: isSending
              ? const AdaptiveLoadingIndicator(
                  key: ValueKey('loading'),
                  size: 18,
                  strokeWidth: 2,
                  color: AppColors.background,
                )
              : const Icon(
                  Icons.arrow_upward,
                  key: ValueKey('arrow'),
                  color: AppColors.background,
                ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

// ── Animated message bubble ───────────────────────────────────────────────────

class _AnimatedMessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMine;
  final bool animate;

  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.animate,
  });

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _translation;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    // 460ms flight duration gives an organic, fluid soaring trajectory
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.isMine ? 460 : 380),
    );

    if (widget.isMine) {
      // Outgoing: Launches directly from message box (shifted down & centered over input)
      _translation = Tween<Offset>(
        begin: const Offset(-38.0, 78.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      // Scale expands out from compact launcher pill to full message bubble
      _scale = Tween<double>(begin: 0.68, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutBack,
        ),
      );

      // Subtle aerodynamic lift tilt that straightens into alignment
      _rotation = Tween<double>(begin: -0.045, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      // Fast opacity fade-in right at launch so the text is instantly visible
      _opacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.20, curve: Curves.easeOut),
      );
    } else {
      // Incoming: Slides gently from companion's side (left)
      _translation = Tween<Offset>(
        begin: const Offset(-28.0, 10.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

      _scale = Tween<double>(begin: 0.90, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      );

      _rotation = const AlwaysStoppedAnimation(0.0);

      _opacity = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      );
    }

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _MessageBubble(message: widget.message, isMine: widget.isMine);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final lift = (1.0 - progress);

        // Dynamic warm biscuit lift glow while airborne
        List<BoxShadow>? dynamicShadows;
        if (widget.isMine) {
          dynamicShadows = [
            if (lift > 0.01)
              BoxShadow(
                color: AppColors.biscuit.withValues(alpha: lift * 0.42),
                blurRadius: 18 * lift + 4,
                spreadRadius: 2 * lift,
                offset: Offset(0, 8 * lift + 2),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06 + 0.04 * lift),
              blurRadius: 6 + 6 * lift,
              offset: Offset(0, 2 + 2 * lift),
            ),
          ];
        }

        return Transform.translate(
          offset: _translation.value,
          child: Transform.rotate(
            angle: _rotation.value,
            child: Transform.scale(
              scale: _scale.value,
              alignment:
                  widget.isMine ? Alignment.bottomRight : Alignment.bottomLeft,
              child: Opacity(
                opacity: _opacity.value.clamp(0.0, 1.0),
                child: _MessageBubble(
                  message: widget.message,
                  isMine: widget.isMine,
                  shadows: dynamicShadows,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final List<BoxShadow>? shadows;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isGracefulExit) {
      return _GracefulExitBubble(message: message);
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.only(
          top: 3,
          bottom: 3,
          left: isMine ? 48 : 0,
          right: isMine ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.biscuit : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: shadows ??
              [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? AppColors.background : AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(message.createdAt.toLocal()),
              style: TextStyle(
                fontSize: 10,
                color: isMine
                    ? AppColors.background.withValues(alpha: 0.55)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Graceful exit bubble with scale-in animation ──────────────────────────────

class _GracefulExitBubble extends StatefulWidget {
  final MessageModel message;
  const _GracefulExitBubble({required this.message});

  @override
  State<_GracefulExitBubble> createState() => _GracefulExitBubbleState();
}

class _GracefulExitBubbleState extends State<_GracefulExitBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 40), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.duskLavender.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.spa_outlined,
                    size: 14,
                    color: AppColors.duskLavender,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Graceful Exit',
                    style: TextStyle(
                      color: AppColors.duskLavender,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.message.content,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
