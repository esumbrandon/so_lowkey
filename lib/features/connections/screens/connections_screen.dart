import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/widgets/app_nav_menu.dart';
import '../controllers/connections_controller.dart';
import '../models/connection_model.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({super.key});

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _myId {
    if (isSupabaseConfigured) {
      return Supabase.instance.client.auth.currentUser?.id ?? mockUserId;
    }
    return mockUserId;
  }

  Future<void> _accept(ConnectionModel connection) async {
    await ref.read(connectionsControllerProvider).accept(connection.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You\'re now connected with ${connection.peerAlias}!'),
          action: SnackBarAction(
            label: 'Chat',
            textColor: AppColors.biscuit,
            onPressed: () => context.go(
              '/chat/${connection.id}?alias=${connection.peerAlias}',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _decline(ConnectionModel connection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline Request',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Remove the connection request from ${connection.peerAlias}?',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Decline',
                style: TextStyle(color: AppColors.terracotta)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(connectionsControllerProvider).decline(connection.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // In offline mode use the dev notifier; in live mode use the stream.
    final List<ConnectionModel> all;
    if (!isSupabaseConfigured) {
      all = ref.watch(devConnectionsNotifierProvider);
    } else {
      final async = ref.watch(connectionsProvider);
      all = async.valueOrNull ?? [];
    }

    final myId = _myId;
    final active = all.where((c) => c.isActive || c.isClosed).toList();
    final pending = all.where((c) => c.status == 'pending').toList();
    final incomingCount =
        pending.where((c) => c.isIncomingPending(myId)).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize_outlined),
            tooltip: 'Dev Screen Switcher',
            onPressed: () => showAppNavigationModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Discover',
            onPressed: () => context.go('/discovery'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.biscuit,
          labelColor: AppColors.biscuit,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 16),
                  const SizedBox(width: 6),
                  Text('Active (${active.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('Pending'),
                  if (incomingCount > 0) ...[
                    const SizedBox(width: 6),
                    _CountBadge(count: incomingCount),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Active Tab ──────────────────────────────────────────────
          active.isEmpty
              ? _EmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: 'No active conversations yet.\nSay hello to someone in Discover!',
                  action: TextButton.icon(
                    icon: const Icon(Icons.explore_outlined,
                        color: AppColors.biscuit),
                    label: const Text('Go to Discover',
                        style: TextStyle(color: AppColors.biscuit)),
                    onPressed: () => context.go('/discovery'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 0),
                  itemCount: active.length,
                  separatorBuilder: (_, _) => const Divider(
                    height: 1,
                    indent: 84,
                    color: AppColors.surface,
                  ),
                  itemBuilder: (context, index) {
                    final conn = active[index];
                    return _ActiveConnectionTile(
                      connection: conn,
                      onTap: () => context.go(
                        '/chat/${conn.id}?alias=${conn.peerAlias}',
                      ),
                    );
                  },
                ),

          // ── Pending Tab ─────────────────────────────────────────────
          pending.isEmpty
              ? const _EmptyState(
                  icon: Icons.person_add_outlined,
                  message: 'No pending requests.\nRequests you send or receive will appear here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final conn = pending[index];
                    final isIncoming = conn.isIncomingPending(myId);
                    return _PendingConnectionTile(
                      connection: conn,
                      isIncoming: isIncoming,
                      onAccept: isIncoming ? () => _accept(conn) : null,
                      onDecline: isIncoming ? () => _decline(conn) : null,
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Active Connection Tile
// ────────────────────────────────────────────────────────────────────────────

class _ActiveConnectionTile extends StatelessWidget {
  final ConnectionModel connection;
  final VoidCallback onTap;

  const _ActiveConnectionTile({
    required this.connection,
    required this.onTap,
  });

  static const _batteryIcons = {
    'recharging': Icons.battery_alert,
    'low': Icons.battery_2_bar,
    'medium': Icons.battery_4_bar,
    'full': Icons.battery_full,
  };

  @override
  Widget build(BuildContext context) {
    final isClosed = connection.isClosed;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.surfaceElevated,
            child: Text(
              connection.peerAlias.isNotEmpty
                  ? connection.peerAlias[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: isClosed ? AppColors.textMuted : AppColors.biscuit,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          if (isClosed)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.spa_outlined,
                  size: 12,
                  color: AppColors.duskLavender,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              connection.peerAlias,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isClosed
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (connection.lastMessageAt != null)
            Text(
              _formatTime(connection.lastMessageAt!),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          if (connection.lastMessageContent != null)
            Text(
              connection.lastMessageContent!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            )
          else
            Text(
              connection.replyPaceLabel,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                _batteryIcons[connection.peerBatteryStatus] ??
                    Icons.battery_4_bar,
                size: 13,
                color: AppColors.sage,
              ),
              const SizedBox(width: 3),
              Text(
                connection.peerBatteryStatus,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.sage,
                ),
              ),
              if (isClosed) ...[
                const SizedBox(width: 8),
                const Text(
                  'Gracefully closed',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.duskLavender,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      onTap: isClosed ? null : onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1) {
      return DateFormat('MMM d').format(dt);
    } else {
      return DateFormat.jm().format(dt);
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Pending Connection Tile
// ────────────────────────────────────────────────────────────────────────────

class _PendingConnectionTile extends StatelessWidget {
  final ConnectionModel connection;
  final bool isIncoming;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _PendingConnectionTile({
    required this.connection,
    required this.isIncoming,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIncoming
              ? AppColors.biscuit.withValues(alpha: 0.4)
              : AppColors.surfaceElevated,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceElevated,
                child: Text(
                  connection.peerAlias.isNotEmpty
                      ? connection.peerAlias[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.biscuit,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.peerAlias,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      connection.replyPaceLabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isIncoming
                      ? AppColors.biscuit.withValues(alpha: 0.15)
                      : AppColors.duskLavender.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isIncoming ? 'Wants to connect' : 'Awaiting reply',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isIncoming
                        ? AppColors.biscuit
                        : AppColors.duskLavender,
                  ),
                ),
              ),
            ],
          ),
          if (isIncoming) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.surfaceElevated),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onDecline,
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.biscuit,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Empty State
// ────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.terracotta,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
