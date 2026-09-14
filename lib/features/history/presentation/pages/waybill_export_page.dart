import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/waybill_item_entity.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_state.dart';
import '../services/excel_export_service.dart';
import '../widgets/waybill_history_card.dart';

class WaybillExportPage extends StatefulWidget {
  final Function(String route)? onNavigate;

  const WaybillExportPage({super.key, this.onNavigate});

  @override
  State<WaybillExportPage> createState() => _WaybillExportPageState();
}

class _WaybillExportPageState extends State<WaybillExportPage> {
  late DateTime _fromDate;
  late DateTime _toDate;
  String _selectedStatusFilter =
      'all'; // 'all' | 'active' | 'delivered' | 'cancelled'
  String _selectedQuickRange = '30d'; // '7d' | '30d' | 'month' | ''
  bool _isGenerating = false;

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
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _fromDate = now.subtract(const Duration(days: 30));
  }

  void _selectQuickRange(String rangeKey) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    setState(() {
      _selectedQuickRange = rangeKey;
      _toDate = todayEnd;
      if (rangeKey == '7d') {
        _fromDate = now.subtract(const Duration(days: 7));
      } else if (rangeKey == '30d') {
        _fromDate = now.subtract(const Duration(days: 30));
      } else if (rangeKey == 'month') {
        _fromDate = DateTime(now.year, now.month, 1);
      }
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initialDate = isFrom ? _fromDate : _toDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF059669),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedQuickRange =
            ''; // Reset quick chip selection on custom date pick
        if (isFrom) {
          _fromDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        } else {
          _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  List<WaybillItemEntity> _getFilteredItems(List<WaybillItemEntity> allItems) {
    final start = DateTime(
      _fromDate.year,
      _fromDate.month,
      _fromDate.day,
      0,
      0,
      0,
    );
    final end = DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59);

    return allItems.where((item) {
      // Direct status filter
      if (_selectedStatusFilter == 'active' && !item.status.isLive) {
        return false;
      }
      if (_selectedStatusFilter == 'delivered' &&
          item.status != ParcelStatus.delivered &&
          item.status != ParcelStatus.returned) {
        return false;
      }
      if (_selectedStatusFilter == 'cancelled' &&
          item.status != ParcelStatus.cancelled &&
          item.status != ParcelStatus.deliveryFailed) {
        return false;
      }

      // Date range filter
      if (item.createdAt != null) {
        if (item.createdAt!.isBefore(start) || item.createdAt!.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _handleDownload(List<WaybillItemEntity> filteredItems) async {
    if (filteredItems.isEmpty || _isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          // Fallback to app documents dir
        }
      }

      final excelFile = await ExcelExportService.generateWaybillExcel(
        items: filteredItems,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (!mounted) return;
      setState(() => _isGenerating = false);
      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 20.0,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Text(
                  l10n.excelSavedSuccess,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l10n.seeDetails,
            textColor: Colors.white,
            onPressed: () async {
              final result = await OpenFilex.open(excelFile.path);
              if (result.type != ResultType.done) {
                await Share.shareXFiles([
                  XFile(excelFile.path),
                ], text: 'Waybill History Excel Export');
              }
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.exportFailed(e.toString())),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd MMM yyyy');

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/history');
            }
          },
        ),
        title: Text(
          l10n.exportFilterTitle,
          style: AppTypography.headingLarge.copyWith(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          final filteredItems = _getFilteredItems(state.allItems);
          final isValidRange = !_fromDate.isAfter(_toDate);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Controls Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 10.0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Filter Selector Label
                      Text(
                        l10n.selectStatusFilter,
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6.0),

                      // Status Filter Segmented Control
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.all(3.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatusFilterTab(
                                key: 'all',
                                label: l10n.allStatuses.toUpperCase(),
                              ),
                            ),
                            Expanded(
                              child: _buildStatusFilterTab(
                                key: 'active',
                                label: l10n.historyActive.toUpperCase(),
                              ),
                            ),
                            Expanded(
                              child: _buildStatusFilterTab(
                                key: 'delivered',
                                label: l10n.historyCompleted.toUpperCase(),
                              ),
                            ),
                            Expanded(
                              child: _buildStatusFilterTab(
                                key: 'cancelled',
                                label: l10n.historyCancelled.toUpperCase(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14.0),

                      // Quick Select Chips
                      Text(
                        l10n.quickSelect,
                        style: AppTypography.monoLabel.copyWith(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildQuickChip(l10n.last7Days, '7d'),
                            const SizedBox(width: 8.0),
                            _buildQuickChip(l10n.last30Days, '30d'),
                            const SizedBox(width: 8.0),
                            _buildQuickChip(l10n.thisMonth, 'month'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14.0),

                      // Date Pickers Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: l10n.fromDate,
                              value: dateFormat.format(_fromDate),
                              onTap: () => _pickDate(isFrom: true),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: _buildDateField(
                              label: l10n.toDate,
                              value: dateFormat.format(_toDate),
                              onTap: () => _pickDate(isFrom: false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16.0),

                // 2. Summary & Download Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  decoration: BoxDecoration(
                    color: filteredItems.isNotEmpty
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: filteredItems.isNotEmpty
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: filteredItems.isNotEmpty
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Icon(
                          filteredItems.isNotEmpty
                              ? Icons.description_outlined
                              : Icons.info_outline_rounded,
                          color: filteredItems.isNotEmpty
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                          size: 22.0,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              filteredItems.isNotEmpty
                                  ? l10n.waybillsFound(filteredItems.length)
                                  : l10n.noWaybillsFound,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: filteredItems.isNotEmpty
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              filteredItems.isNotEmpty
                                  ? l10n.matchingDateFilters
                                  : l10n.tryWiderDateRange,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: filteredItems.isNotEmpty
                                    ? const Color(0xFF047857)
                                    : const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed:
                            (filteredItems.isEmpty ||
                                !isValidRange ||
                                _isGenerating)
                            ? null
                            : () => _handleDownload(filteredItems),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 11.0,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: _isGenerating
                            ? const SizedBox(
                                width: 18.0,
                                height: 18.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                children: [
                                  const Icon(
                                    Icons.download_rounded,
                                    size: 16.0,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    l10n.excel,
                                    style: const TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // 3. Live Filtered Data Cards Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.filteredWaybills(filteredItems.length),
                      style: AppTypography.monoLabel.copyWith(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      l10n.showingLiveResults,
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 12.0,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10.0),

                // 4. Live Data Cards List
                if (filteredItems.isEmpty)
                  _buildEmptyCard()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
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

                const SizedBox(height: 40.0),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilterTab({required String key, required String label}) {
    final isSelected = _selectedStatusFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0A0F172A),
                    blurRadius: 6.0,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.monoLabel.copyWith(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            color: isSelected
                ? const Color(0xFF059669)
                : const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String key) {
    final isSelected = _selectedQuickRange == key;

    return GestureDetector(
      onTap: () => _selectQuickRange(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x180F172A),
                    blurRadius: 8.0,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14.0),
              const SizedBox(width: 5.0),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.monoLabel.copyWith(
              fontSize: 10.0,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6.0),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 15.0,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 52.0,
            height: 52.0,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.filter_alt_off_outlined,
              size: 24.0,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14.0),
          Text(
            AppLocalizations.of(context)!.noMatchingWaybills,
            style: AppTypography.headingMedium.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            AppLocalizations.of(context)!.tryWiderOrAllStatuses,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
