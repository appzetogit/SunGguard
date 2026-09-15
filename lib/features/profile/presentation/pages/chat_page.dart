import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sungguard/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/platform_settings_service.dart';
import '../../../../core/services/socket_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';

const List<String> kChatEmojis = [
  '😀', '😂', '😍', '🥺', '😎',
  '😭', '😡', '👍', '👎', '🎉',
  '❤️', '🔥', '✅', '❌', '👋',
  '🙏', '👀', '💯', '💩', '🤡',
];

class ChatMessage {
  final String id;
  final String text;
  final String mediaUrl;
  final String mediaType;
  final String sender; // 'user' | 'support'
  final DateTime? createdAt;
  final String time;

  ChatMessage({
    required this.id,
    required this.text,
    this.mediaUrl = '',
    this.mediaType = '',
    required this.sender,
    this.createdAt,
    required this.time,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, [int index = 0]) {
    final createdAtRaw = json['createdAt']?.toString();
    DateTime? dt;
    String formattedTime = '';
    if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
      try {
        dt = DateTime.parse(createdAtRaw).toLocal();
        formattedTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final isAdmin = json['isAdmin'] == true ||
        json['sender'] == 'support' ||
        json['sender'] == 'admin';

    return ChatMessage(
      id: json['_id']?.toString() ??
          json['id']?.toString() ??
          'msg_${DateTime.now().millisecondsSinceEpoch}_$index',
      text: (json['text'] ?? json['message'] ?? '').toString(),
      mediaUrl: (json['mediaUrl'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? '').toString(),
      sender: isAdmin ? 'support' : 'user',
      createdAt: dt,
      time: formattedTime,
    );
  }
}

class ChatPage extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialTicketId;

  /// Optional context so a chat opened from a parcel screen files the ticket
  /// against that parcel. Both are accepted by POST /tickets/create.
  final String? relatedParcelId;
  final String? relatedOrderId;

  const ChatPage({
    super.key,
    this.onBack,
    this.initialTicketId,
    this.relatedParcelId,
    this.relatedOrderId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ApiClient _apiClient;
  late final SocketService _socketService;
  final ImagePicker _imagePicker = ImagePicker();

  String? _ticketId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _showEmojiPicker = false;
  XFile? _selectedImageFile;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  // Stream-based real-time architecture
  final StreamController<List<ChatMessage>> _messageStreamCtrl =
      StreamController<List<ChatMessage>>.broadcast();
  List<ChatMessage> _messages = [];
  Timer? _periodicSyncTimer;

  String _supportPhone = PlatformSettingsService().current.supportPhone;
  String _appName = PlatformSettingsService().current.appName;

  Future<void> _loadPlatformSettings() async {
    final settings = await PlatformSettingsService().load();
    if (!mounted) return;
    setState(() {
      _supportPhone = settings.supportPhone;
      _appName = settings.appName;
    });
  }

  @override
  void initState() {
    super.initState();
    _apiClient = sl<ApiClient>();
    _socketService = sl<SocketService>();

    _ticketId = widget.initialTicketId;

    // Initial welcome placeholder messages
    _messages = [
      ChatMessage(
        id: 'welcome-1',
        text: 'Hi there! 👋 Welcome to $_appName Support.',
        sender: 'support',
        time: '',
      ),
      ChatMessage(
        id: 'welcome-2',
        text: 'Send a message and an admin will reply here.',
        sender: 'support',
        time: '',
      ),
    ];
    _emitMessages();

    _initSocket();
    _loadChat();
    _loadPlatformSettings();

    // Start background stream-sync ticker every 3.5 seconds
    _startPeriodicSync();
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    if (_ticketId != null && _ticketId!.isNotEmpty) {
      _socketService.emit('leave_ticket', _ticketId);
    }
    _socketService.off('ticket:message');
    _socketService.off('ticket:created');

    _messageStreamCtrl.close();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _emitMessages() {
    if (!_messageStreamCtrl.isClosed) {
      _messageStreamCtrl.add(List.unmodifiable(_messages));
    }
  }

  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (mounted && !_isSending) {
        _syncMessagesInBackground();
      }
    });
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/support');
    }
  }

  Future<void> _initSocket() async {
    await _socketService.connect();

    _socketService.on('ticket:message', (payload) {
      if (!mounted || payload == null) return;
      _handleIncomingSocketMessage(payload);
    });

  }

  void _handleIncomingSocketMessage(dynamic payload) {
    try {
      final Map<String, dynamic> data = payload is Map<String, dynamic>
          ? payload
          : Map<String, dynamic>.from(payload as Map);

      final targetTicketId = (data['ticketId'] ?? '').toString();
      if (_ticketId != null &&
          targetTicketId.isNotEmpty &&
          targetTicketId != _ticketId) {
        return;
      }

      final msgData = data['message'] is Map
          ? data['message'] as Map<String, dynamic>
          : data;
      final incoming = ChatMessage.fromJson(msgData);

      final index = _messages.indexWhere((m) => m.id == incoming.id);
      if (index >= 0) {
        _messages[index] = incoming;
      } else {
        _messages.add(incoming);
      }

      _emitMessages();
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _loadChat() async {
    setState(() => _isLoading = true);

    try {
      final res = await _apiClient.get(ApiEndpoints.myTickets);
      List<dynamic> rawList = [];

      if (res is List) {
        rawList = res;
      } else if (res is Map<String, dynamic>) {
        if (res['result'] is List) {
          rawList = res['result'] as List;
        } else if (res['results'] is List) {
          rawList = res['results'] as List;
        } else if (res['data'] is List) {
          rawList = res['data'] as List;
        }
      }

      final tickets = rawList.whereType<Map<String, dynamic>>().toList();
      Map<String, dynamic>? activeTicket;

      if (_ticketId != null && _ticketId!.isNotEmpty) {
        activeTicket = tickets.firstWhere(
          (t) => (t['_id'] ?? t['id'])?.toString() == _ticketId,
          orElse: () => tickets.isNotEmpty ? tickets.first : {},
        );
      } else {
        activeTicket = tickets.firstWhere(
          (t) => (t['status'] ?? '').toString().toLowerCase() != 'closed',
          orElse: () => tickets.isNotEmpty ? tickets.first : {},
        );
      }

      if (activeTicket.isNotEmpty) {
        final id = (activeTicket['_id'] ?? activeTicket['id'])?.toString();
        if (id != null && id.isNotEmpty) {
          _ticketId = id;
          _socketService.emit('join_ticket', id);

          final rawMessages = activeTicket['messages'];
          if (rawMessages is List && rawMessages.isNotEmpty) {
            final parsed = rawMessages
                .asMap()
                .entries
                .where((e) => e.value is Map)
                .map((e) => ChatMessage.fromJson(
                    Map<String, dynamic>.from(e.value as Map), e.key))
                .toList();

            if (parsed.isNotEmpty) {
              _messages = parsed;
              _emitMessages();
            }
          }
        }
      }
    } catch (_) {
      // Keep initial welcome messages
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _emitMessages();
        _scrollToBottom();
      }
    }
  }

  Future<void> _syncMessagesInBackground() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.myTickets);
      List<dynamic> rawList = [];

      if (res is List) {
        rawList = res;
      } else if (res is Map<String, dynamic>) {
        if (res['result'] is List) {
          rawList = res['result'] as List;
        } else if (res['results'] is List) {
          rawList = res['results'] as List;
        } else if (res['data'] is List) {
          rawList = res['data'] as List;
        }
      }

      final tickets = rawList.whereType<Map<String, dynamic>>().toList();
      Map<String, dynamic>? activeTicket;

      if (_ticketId != null && _ticketId!.isNotEmpty) {
        activeTicket = tickets.firstWhere(
          (t) => (t['_id'] ?? t['id'])?.toString() == _ticketId,
          orElse: () => {},
        );
      } else {
        activeTicket = tickets.firstWhere(
          (t) => (t['status'] ?? '').toString().toLowerCase() != 'closed',
          orElse: () => {},
        );
      }

      if (activeTicket.isNotEmpty) {
        final id = (activeTicket['_id'] ?? activeTicket['id'])?.toString();
        if (id != null && id.isNotEmpty && _ticketId != id) {
          _ticketId = id;
          _socketService.emit('join_ticket', id);
        }

        final rawMessages = activeTicket['messages'];
        if (rawMessages is List && rawMessages.isNotEmpty) {
          final parsed = rawMessages
              .asMap()
              .entries
              .where((e) => e.value is Map)
              .map((e) => ChatMessage.fromJson(
                  Map<String, dynamic>.from(e.value as Map), e.key))
              .toList();

          if (parsed.isNotEmpty && parsed.length != _messages.length) {
            _messages = parsed;
            _emitMessages();
            _scrollToBottom();
          }
        }
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file != null) {
        setState(() {
          _selectedImageFile = file;
          _showEmojiPicker = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.showError(context, AppLocalizations.of(context)!.error);
      }
    }
  }

  void _showAttachmentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF0F172A)),
                title: const Text(
                  'Open camera',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.0),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(height: 1.0, color: Color(0xFFF1F5F9)),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Color(0xFF0F172A)),
                title: const Text(
                  'Upload from gallery',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.0),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty && _selectedImageFile == null) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
      _showEmojiPicker = false;
    });

    try {
      String mediaUrl = '';

      if (_selectedImageFile != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            _selectedImageFile!.path,
            filename: _selectedImageFile!.name,
          ),
        });

        final uploadRes = await _apiClient.post(
          '/media/upload',
          data: formData,
        );

        if (uploadRes is Map) {
          mediaUrl = (uploadRes['url'] ??
                  uploadRes['result']?['url'] ??
                  uploadRes['data']?['url'] ??
                  '')
              .toString();
        }
      }

      // Optimistic message update to stream
      final optimisticMsg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaUrl.isNotEmpty ? 'image' : '',
        sender: 'user',
        createdAt: DateTime.now(),
        time: DateFormat('hh:mm a').format(DateTime.now()),
      );
      _messages.add(optimisticMsg);
      _emitMessages();
      _scrollToBottom();

      _inputCtrl.clear();
      setState(() {
        _selectedImageFile = null;
      });

      if (_ticketId == null || _ticketId!.isEmpty) {
        // Create new ticket
        final payload = {
          'subject': 'Support Chat',
          'description': text.isNotEmpty
              ? text
              : (mediaUrl.isNotEmpty ? 'Sent an image' : 'Support inquiry'),
          'priority': 'medium',
          // The ticket model carries relatedParcelId; when the chat is opened
          // from a parcel screen, filing it against that parcel is what lets
          // support see the context without asking for it.
          'category': widget.relatedParcelId != null ? 'parcel' : 'other',
          if (widget.relatedParcelId != null)
            'relatedParcelId': widget.relatedParcelId,
          if (widget.relatedOrderId != null)
            'relatedOrderId': widget.relatedOrderId,
          'userType': 'Customer',
          if (mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl,
          if (mediaUrl.isNotEmpty) 'mediaType': 'image',
          if (mediaUrl.isNotEmpty) 'mimeType': 'image/jpeg',
        };

        final res =
            await _apiClient.post(ApiEndpoints.createTicket, data: payload);
        final ticket =
            res is Map ? (res['result'] ?? res['data'] ?? res) : null;
        if (ticket is Map && ticket['_id'] != null) {
          final id = ticket['_id'].toString();
          _ticketId = id;
          _socketService.emit('join_ticket', id);

          final rawMessages = ticket['messages'];
          if (rawMessages is List) {
            final parsed = rawMessages
                .asMap()
                .entries
                .where((e) => e.value is Map)
                .map((e) => ChatMessage.fromJson(
                    Map<String, dynamic>.from(e.value as Map), e.key))
                .toList();

            _messages = parsed;
            _emitMessages();
          }
        }
      } else {
        // Reply to existing ticket
        final payload = {
          'text': text,
          if (mediaUrl.isNotEmpty) 'mediaUrl': mediaUrl,
          if (mediaUrl.isNotEmpty) 'mediaType': 'image',
          if (mediaUrl.isNotEmpty) 'mimeType': 'image/jpeg',
        };

        final res = await _apiClient.post(
          ApiEndpoints.replyTicket(_ticketId!),
          data: payload,
        );

        final ticket =
            res is Map ? (res['result'] ?? res['data'] ?? res) : null;
        if (ticket is Map && ticket['messages'] is List) {
          final rawMessages = ticket['messages'] as List;
          final parsed = rawMessages
              .asMap()
              .entries
              .where((e) => e.value is Map)
              .map((e) => ChatMessage.fromJson(
                  Map<String, dynamic>.from(e.value as Map), e.key))
              .toList();

          _messages = parsed;
          _emitMessages();
        }
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, AppLocalizations.of(context)!.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _callSupport() async {
    final cleanPhone = _supportPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppSnackBar.showInfo(context, '${AppLocalizations.of(context)!.supportCallUs}: $_supportPhone');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              size: 22.0, color: Color(0xFF0F172A)),
          onPressed: _handleBack,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'SG',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11.0,
                    height: 11.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Support Chat',
                  style: AppTypography.headingMedium.copyWith(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2.0),
                Row(
                  children: [
                    Container(
                      width: 5.0,
                      height: 5.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      'ONLINE',
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_outlined,
                size: 22.0, color: Color(0xFF475569)),
            onPressed: _callSupport,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFF1F5F9), height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // StreamBuilder for real-time reactive messages stream
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messageStreamCtrl.stream,
              initialData: _messages,
              builder: (context, snapshot) {
                final messageList = snapshot.data ?? _messages;

                if (_isLoading && messageList.isEmpty) {
                  return const Center(
                    child: Text(
                      'Loading chat…',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  itemCount: messageList.length,
                  itemBuilder: (context, index) {
                    final msg = messageList[index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),

          // Floating Image Preview (if image selected)
          if (_selectedImageFile != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.white,
              alignment: Alignment.centerLeft,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.file(
                      File(_selectedImageFile!.path),
                      width: 80.0,
                      height: 80.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageFile = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 12.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Emoji Picker Popover
          if (_showEmojiPicker)
            Container(
              height: 160.0,
              padding: const EdgeInsets.all(10.0),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6.0,
                  mainAxisSpacing: 6.0,
                ),
                itemCount: kChatEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = kChatEmojis[index];
                  return InkWell(
                    onTap: () {
                      _inputCtrl.text += emoji;
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 22.0),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Composer Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(28.0),
                  border: Border.all(color: const Color(0xFF0F172A), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.sentiment_satisfied_alt_outlined,
                        color: _showEmojiPicker
                            ? AppColors.primary
                            : const Color(0xFF94A3B8),
                        size: 22.0,
                      ),
                      onPressed: () {
                        setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                        });
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.attach_file_rounded,
                        color: Color(0xFF94A3B8),
                        size: 22.0,
                      ),
                      onPressed: _showAttachmentModal,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 4.0),
                      child: Material(
                        color: AppColors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _isSending ? null : _sendMessage,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _isSending
                                ? const SizedBox(
                                    width: 18.0,
                                    height: 18.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 18.0,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16.0),
                topRight: Radius.circular(isUser ? 2.0 : 16.0),
                bottomLeft: Radius.circular(isUser ? 16.0 : 2.0),
                bottomRight: const Radius.circular(16.0),
              ),
              border: Border.all(
                color: isUser ? AppColors.primary : const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 4.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (msg.mediaUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      msg.mediaUrl,
                      width: 200.0,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  if (msg.text.isNotEmpty) const SizedBox(height: 6.0),
                ],
                if (msg.text.isNotEmpty)
                  Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: isUser ? Colors.white : const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
          if (msg.time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3.0, left: 4.0, right: 4.0),
              child: Text(
                msg.time,
                style: const TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
