import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

class WalletPage extends StatefulWidget {
  final VoidCallback? onBack;

  const WalletPage({super.key, this.onBack});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingTransactions = true;

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(ProfileFetchRequested());
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final client = ApiClient.createDefault();
      // Server pages at max 50 (`page`, `limit` → `items, totalPages`).
      final all = <Map<String, dynamic>>[];
      var page = 1;
      var totalPages = 1;
      do {
        final res = await client.get(
          ApiEndpoints.customerTransactions,
          queryParameters: {'page': page, 'limit': 50},
        );
        final data = (res is Map) ? (res['result'] ?? res['data'] ?? res) : null;
        if (data is! Map) break;
        all.addAll(
          (data['items'] as List?)?.whereType<Map<String, dynamic>>() ??
              const <Map<String, dynamic>>[],
        );
        totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
        page++;
      } while (page <= totalPages && page <= 10);
      if (mounted) {
        setState(() {
          _transactions = all;
        });
      }
    } catch (_) {
      setState(() => _transactions = []);
    } finally {
      if (mounted) setState(() => _isLoadingTransactions = false);
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    final date = DateTime.tryParse(rawDate)?.toLocal();
    if (date == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    final timeStr = DateFormat('hh:mm a').format(date);
    if (itemDate == today) {
      return 'Today, $timeStr';
    } else if (itemDate == yesterday) {
      return 'Yesterday, $timeStr';
    } else {
      return '${DateFormat('d MMM').format(date)}, $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Top Bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: _handleBack,
                    borderRadius: BorderRadius.circular(20.0),
                    child: Container(
                      width: 40.0,
                      height: 40.0,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 26.0,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    AppLocalizations.of(context)!.walletTitle,
                    style: const TextStyle(
                      fontSize: 19.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Body content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF0C831F),
                onRefresh: () async {
                  context.read<ProfileBloc>().add(ProfileFetchRequested());
                  await _fetchTransactions();
                },
                child: BlocBuilder<ProfileBloc, ProfileState>(
                  builder: (context, state) {
                    final balance = state.walletBalance;
                    final l10n = AppLocalizations.of(context)!;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Available Balance Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x060F172A),
                                  blurRadius: 10.0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.walletBalance.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                Text(
                                  state.isLoading
                                      ? '...'
                                      : '₹${NumberFormat('#,##,###.##').format(balance)}',
                                  style: const TextStyle(
                                    fontSize: 28.0,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4.0),
                                const Text(
                                  'Refunds and wallet payments show in history below',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16.0),

                          // 2. Transaction History Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x060F172A),
                                  blurRadius: 10.0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 14.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: const [
                                      Text(
                                        'Transaction History',
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Color(0xFF94A3B8),
                                        size: 18.0,
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),

                                if (_isLoadingTransactions)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 40.0,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Loading...',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (_transactions.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0,
                                      vertical: 40.0,
                                    ),
                                    child: Center(
                                      child: Column(
                                        children: const [
                                          Text(
                                            'No wallet activity yet',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          SizedBox(height: 4.0),
                                          Text(
                                            'Credits (refunds) and wallet payments will appear here.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Color(0xFF94A3B8),
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _transactions.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                    itemBuilder: (context, index) {
                                      final tx = _transactions[index];
                                      final isCredit = tx['type'] == 'credit';
                                      final amount =
                                          (tx['amount'] as num?)?.toDouble() ??
                                          0.0;
                                      final title =
                                          tx['title']?.toString() ??
                                          (isCredit ? 'Credit' : 'Debit');
                                      final dateStr = _formatDate(
                                        tx['date']?.toString(),
                                      );
                                      final orderId = tx['orderId']?.toString();
                                      final reference = tx['reference']
                                          ?.toString();

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 14.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            // Icon Bubble
                                            Container(
                                              width: 40.0,
                                              height: 40.0,
                                              decoration: BoxDecoration(
                                                color: isCredit
                                                    ? const Color(
                                                        0xFFECFDF5,
                                                      ) // emerald-50
                                                    : const Color(
                                                        0xFFF1F5F9,
                                                      ), // slate-100
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                isCredit
                                                    ? Icons
                                                          .south_west_rounded // ArrowDownLeft
                                                    : Icons.north_east_rounded, // ArrowUpRight
                                                size: 19.0,
                                                color: isCredit
                                                    ? const Color(
                                                        0xFF059669,
                                                      ) // emerald-600
                                                    : const Color(
                                                        0xFF334155,
                                                      ), // slate-700
                                              ),
                                            ),
                                            const SizedBox(width: 12.0),

                                            // Text Details
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 14.0,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF1E293B),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2.0),
                                                  Text(
                                                    dateStr,
                                                    style: const TextStyle(
                                                      fontSize: 11.0,
                                                      color: Color(0xFF64748B),
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                  if (orderId != null &&
                                                      orderId.isNotEmpty) ...[
                                                    const SizedBox(height: 2.0),
                                                    Text(
                                                      '#$orderId',
                                                      style: const TextStyle(
                                                        fontSize: 10.0,
                                                        color: Color(
                                                          0xFF64748B,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ] else if (reference !=
                                                          null &&
                                                      reference.isNotEmpty) ...[
                                                    const SizedBox(height: 2.0),
                                                    Text(
                                                      reference,
                                                      style: const TextStyle(
                                                        fontSize: 10.0,
                                                        color: Color(
                                                          0xFF94A3B8,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w400,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            const SizedBox(width: 10.0),

                                            // Amount
                                            Text(
                                              '${isCredit ? '+' : '-'}₹${NumberFormat('#,##,###.##').format(amount)}',
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: isCredit
                                                    ? const Color(
                                                        0xFF059669,
                                                      ) // emerald-600
                                                    : const Color(
                                                        0xFF0F172A,
                                                      ), // slate-900
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 80.0),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
