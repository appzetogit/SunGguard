import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sungguard/l10n/app_localizations.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../widgets/waybill_history_card.dart';

class WaybillHistoryPage extends StatefulWidget {
  final Function(String route)? onNavigate;

  const WaybillHistoryPage({super.key, this.onNavigate});

  @override
  State<WaybillHistoryPage> createState() => _WaybillHistoryPageState();
}

class _WaybillHistoryPageState extends State<WaybillHistoryPage> {
  void _nav(String route) {
    if (widget.onNavigate != null) {
      widget.onNavigate!(route);
    } else {
      context.push(route);
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<HistoryBloc>().add(HistoryFetchRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            final items = state.filteredItems;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<HistoryBloc>().add(HistoryFetchRequested());
              },
              color: const Color(0xFF059669),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8.0),

                    // 1. Heading & Export Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            l10n.historyTitle,
                            style: AppTypography.headingLarge.copyWith(
                              fontSize: 24.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _nav('/history/export'),
                            borderRadius: BorderRadius.circular(12.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x080F172A),
                                    blurRadius: 8.0,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.download_rounded,
                                    size: 18.0,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    l10n.export,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 2. Filter Pills (ACTIVE, DELIVERED, CANCELLED, OUTSTATION)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill(
                            key: 'active',
                            label: state.activeCount > 0
                                ? '${l10n.historyActive.toUpperCase()} · ${state.activeCount}'
                                : l10n.historyActive.toUpperCase(),
                            currentTab: state.activeTab,
                          ),
                          const SizedBox(width: 8.0),
                          _buildFilterPill(
                            key: 'delivered',
                            label: state.deliveredCount > 0
                                ? '${l10n.historyCompleted.toUpperCase()} · ${state.deliveredCount}'
                                : l10n.historyCompleted.toUpperCase(),
                            currentTab: state.activeTab,
                          ),
                          const SizedBox(width: 8.0),
                          _buildFilterPill(
                            key: 'cancelled',
                            label: state.cancelledCount > 0
                                ? '${l10n.historyCancelled.toUpperCase()} · ${state.cancelledCount}'
                                : l10n.historyCancelled.toUpperCase(),
                            currentTab: state.activeTab,
                          ),
                          const SizedBox(width: 8.0),
                          _buildFilterPill(
                            key: 'outstation',
                            label: state.outstationCount > 0
                                ? '${l10n.homeOutstation.toUpperCase()} · ${state.outstationCount}'
                                : l10n.homeOutstation.toUpperCase(),
                            currentTab: state.activeTab,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // 3. Section Caption
                    if (items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0, left: 2.0),
                        child: Text(
                          state.activeTab == 'active'
                              ? 'IN TRANSIT'
                              : state.activeTab == 'outstation'
                                  ? 'OUTSTATION PARCELS'
                                  : 'PREVIOUS',
                          style: AppTypography.monoLabel.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF94A3B8),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                    // 4. Content Area
                    if (state.isLoading)
                      const Column(
                        children: [
                          WaybillCardSkeleton(),
                          WaybillCardSkeleton(),
                          WaybillCardSkeleton(),
                        ],
                      )
                    else if (items.isEmpty)
                      _buildEmptyStateCard(state.activeTab)
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return WaybillHistoryCard(
                            item: item,
                            onTap: () {
                              if (item.kind == 'outstation') {
                                _nav('/parcel/outstation/track/${item.id}');
                              } else {
                                _nav('/parcel/local/track/${item.id}');
                              }
                            },
                          );
                        },
                      ),

                    const SizedBox(
                      height: 110.0,
                    ), // Spacing for floating bottom bar
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String key,
    required String label,
    required String currentTab,
  }) {
    final isSelected = currentTab == key;

    return GestureDetector(
      onTap: () {
        context.read<HistoryBloc>().add(HistoryTabChanged(key));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x180F172A),
                    blurRadius: 10.0,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.monoLabel.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCard(String tab) {
    String title = 'No active waybills';
    String desc =
        'Book a new city parcel delivery to track your items here in real time.';

    if (tab == 'delivered') {
      title = 'No delivered parcels';
      desc = 'Completed parcel deliveries will be safely archived here.';
    } else if (tab == 'cancelled') {
      title = 'No cancelled bookings';
      desc = 'Any cancelled parcel requests will appear here with docket logs.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.0,
            height: 56.0,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 26.0,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: AppTypography.headingMedium.copyWith(
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
