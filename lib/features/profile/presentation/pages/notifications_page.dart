import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _apiClient = ApiClient.createDefault();
  final _scrollCtrl = ScrollController();
  SocketService? _socketService;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isMarkingRead = false;
  List<Map<String, dynamic>> _notifications = [];

  /// Straight from the response envelope, which the app used to discard
  /// along with page/total/totalPages.
  int _unreadCount = 0;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _scrollCtrl.addListener(_onScroll);
    _listenForLiveNotifications();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _socketService?.off('notification:new');
    super.dispose();
  }

  /// The backend emits `notification:new` to `customer:<id>` whenever a
  /// notification is created. Nothing listened for it, so the list only ever
  /// changed on a manual refresh.
  Future<void> _listenForLiveNotifications() async {
    try {
      _socketService = sl<SocketService>();
      await _socketService!.connect();
      _socketService!.off('notification:new');
      _socketService!.on('notification:new', (_) {
        if (mounted) _fetchNotifications();
      });
    } catch (_) {}
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _isLoadingMore || _page >= _totalPages) {
      return;
    }
    final position = _scrollCtrl.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _fetchNextPage();
    }
  }

  /// Marks everything read. The endpoint also accepts a single
  /// `notificationId` or a `notificationIds` array.
  Future<void> _markAllRead() async {
    if (_isMarkingRead || _unreadCount == 0) return;
    setState(() => _isMarkingRead = true);
    try {
      await _apiClient.patch(
        ApiEndpoints.notificationsMarkRead,
        data: {'markAll': 'true'},
      );
      if (!mounted) return;
      setState(() {
        _unreadCount = 0;
        _notifications =
            _notifications.map((n) => {...n, 'isRead': true}).toList();
      });
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, "Couldn't mark these as read");
      }
    } finally {
      if (mounted) setState(() => _isMarkingRead = false);
    }
  }

  Future<void> _fetchNextPage() async {
    setState(() => _isLoadingMore = true);
    try {
      final response = await _apiClient.get(
        ApiEndpoints.customerNotifications,
        queryParameters: {'page': _page + 1, 'limit': 20},
      );
      final parsed = _parseResponse(response);
      if (!mounted) return;
      setState(() {
        _notifications = [..._notifications, ...parsed.items];
        _page = parsed.page;
        _totalPages = parsed.totalPages;
        _unreadCount = parsed.unreadCount;
      });
    } catch (_) {
      // Leave the existing page in place; the next scroll retries.
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.get(
        ApiEndpoints.customerNotifications,
        queryParameters: {'page': 1, 'limit': 20},
      );
      final parsed = _parseResponse(response);

      if (mounted) {
        setState(() {
          _notifications = parsed.items;
          _page = parsed.page;
          _totalPages = parsed.totalPages;
          _unreadCount = parsed.unreadCount;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

  _NotificationPage _parseResponse(dynamic response) {
    final data = (response is Map)
        ? (response['result'] ?? response['data'] ?? response)
        : response;

    List<Map<String, dynamic>> items = [];
    int unread = 0;
    int page = 1;
    int totalPages = 1;

    if (data is Map) {
      final list =
          data['items'] ?? data['notifications'] ?? data['results'] ?? [];
      if (list is List) {
        items = list.whereType<Map<String, dynamic>>().toList();
      }
      unread = (data['unreadCount'] as num?)?.toInt() ?? 0;
      page = (data['page'] as num?)?.toInt() ?? 1;
      totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
    } else if (data is List) {
      items = data.whereType<Map<String, dynamic>>().toList();
    }

    return _NotificationPage(
      items: items,
      unreadCount: unread,
      page: page,
      totalPages: totalPages,
    );
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  String _formatTimestamp(String? isoString, AppLocalizations? l10n) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inMinutes < 1) {
        return l10n?.justNow ?? 'Just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24 && dateTime.day == now.day) {
        return DateFormat('h:mm a').format(dateTime);
      } else if (diff.inDays < 2 &&
          dateTime.day == now.subtract(const Duration(days: 1)).day) {
        return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
      } else {
        return DateFormat('dd MMM, h:mm a').format(dateTime);
      }
    } catch (_) {
      return '';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'parcel':
      case 'delivery':
      case 'order':
        return Icons.local_shipping_outlined;
      case 'payment':
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'promo':
      case 'offer':
        return Icons.local_offer_outlined;
      case 'support':
      case 'ticket':
        return Icons.headset_mic_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getNotificationIconColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'parcel':
      case 'delivery':
      case 'order':
        return const Color(0xFF059669);
      case 'payment':
      case 'wallet':
        return const Color(0xFF2563EB);
      case 'promo':
      case 'offer':
        return const Color(0xFFD97706);
      case 'support':
      case 'ticket':
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF0F172A);
    }
  }

  Color _getNotificationIconBg(String? type) {
    switch (type?.toLowerCase()) {
      case 'parcel':
      case 'delivery':
      case 'order':
        return const Color(0xFFECFDF5);
      case 'payment':
      case 'wallet':
        return const Color(0xFFEFF6FF);
      case 'promo':
      case 'offer':
        return const Color(0xFFFEF3C7);
      case 'support':
      case 'ticket':
        return const Color(0xFFF3E8FF);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18.0,
            color: Color(0xFF0F172A),
          ),
          onPressed: _handleBack,
        ),
        centerTitle: false,
        title: Text(
          l10n?.notificationsTitle ?? 'Notifications',
          style: AppTypography.headingLarge.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _isMarkingRead ? null : _markAllRead,
              icon: _isMarkingRead
                  ? const SizedBox(
                      width: 13.0,
                      height: 13.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Color(0xFF059669),
                      ),
                    )
                  : const Icon(
                      Icons.done_all_rounded,
                      size: 16.0,
                      color: Color(0xFF059669),
                    ),
              label: Text(
                'Mark all read ($_unreadCount)',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              size: 20.0,
              color: Color(0xFF64748B),
            ),
            onPressed: _fetchNotifications,
          ),
          IconButton(
            tooltip: 'Notification settings',
            icon: const Icon(
              Icons.tune_rounded,
              size: 20.0,
              color: Color(0xFF64748B),
            ),
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: const Color(0xFF059669),
        child: _isLoading
            ? _buildLoadingSkeleton()
            : _notifications.isEmpty
            ? _buildEmptyState(l10n)
            : _buildNotificationsList(l10n),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 140.0,
                      height: 14.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      width: double.infinity,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.0,
              height: 72.0,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 36.0,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              l10n?.noNotifications ?? 'No notifications yet',
              style: AppTypography.headingMedium.copyWith(
                fontSize: 17.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6.0),
            Text(
              l10n?.noNotificationsDesc ?? 'You will see updates about your bookings, deliveries, and account here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13.0,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(AppLocalizations? l10n) {
    return ListView.separated(
      // Attached so _onScroll can pull the next page as the list nears its end.
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      // One extra slot for the paging spinner when more pages remain.
      itemCount: _notifications.length + (_page < _totalPages ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10.0),
      itemBuilder: (context, index) {
        if (index >= _notifications.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          );
        }
        final item = _notifications[index];
        final title = item['title']?.toString() ?? 'Notification';
        final body =
            item['body']?.toString() ?? item['message']?.toString() ?? '';
        final type = item['type']?.toString() ?? item['category']?.toString();
        final createdAt =
            item['createdAt']?.toString() ??
            item['created_at']?.toString() ??
            item['timestamp']?.toString();
        final isRead = item['isRead'] == true || item['read'] == true;

        final icon = _getNotificationIcon(type);
        final iconColor = _getNotificationIconColor(type);
        final iconBg = _getNotificationIconBg(type);
        final timeStr = _formatTimestamp(createdAt, l10n);

        return Container(
          decoration: BoxDecoration(
            color: isRead ? Colors.white : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBBF7D0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x040F172A),
                blurRadius: 8.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(icon, color: iconColor, size: 22.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.bodyBold.copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Text(
                              timeStr,
                              style: AppTypography.monoLabel.copyWith(
                                fontSize: 10.5,
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        body,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12.5,
                          color: const Color(0xFF475569),
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!isRead) ...[
                const SizedBox(width: 6.0),
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}


/// One page of the notifications envelope.
class _NotificationPage {
  final List<Map<String, dynamic>> items;
  final int unreadCount;
  final int page;
  final int totalPages;

  const _NotificationPage({
    required this.items,
    required this.unreadCount,
    required this.page,
    required this.totalPages,
  });
}
