import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/waybill_item_entity.dart';
import '../services/excel_export_service.dart';

class ExportWaybillDialog extends StatefulWidget {
  final List<WaybillItemEntity> allItems;
  final String activeTab; // 'active' | 'delivered' | 'cancelled'

  const ExportWaybillDialog({
    super.key,
    required this.allItems,
    required this.activeTab,
  });

  static Future<void> show(
    BuildContext context, {
    required List<WaybillItemEntity> allItems,
    required String activeTab,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ExportWaybillDialog(allItems: allItems, activeTab: activeTab),
    );
  }

  @override
  State<ExportWaybillDialog> createState() => _ExportWaybillDialogState();
}

class _ExportWaybillDialogState extends State<ExportWaybillDialog> {
  late DateTime _fromDate;
  late DateTime _toDate;
  late String _selectedScope; // 'current' | 'all'
  bool _isGenerating = false;
  int _matchingCount = 0;
  String? _validationError;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _fromDate = now.subtract(const Duration(days: 30));
    _selectedScope = 'current';
    _recalculateMatchingCount();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _validateAndRecalculate() {
    setState(() {
      if (_fromDate.isAfter(_toDate)) {
        _validationError = 'From Date cannot be after To Date';
        _matchingCount = 0;
      } else {
        _validationError = null;
        _recalculateMatchingCount();
      }
    });
  }

  void _recalculateMatchingCount() {
    final start = DateTime(
      _fromDate.year,
      _fromDate.month,
      _fromDate.day,
      0,
      0,
      0,
    );
    final end = DateTime(_toDate.year, _toDate.month, _toDate.day, 23, 59, 59);

    final filtered = widget.allItems.where((item) {
      // Status scope filter
      if (_selectedScope == 'current') {
        if (widget.activeTab == 'active' && !item.status.isLive) return false;
        if (widget.activeTab == 'delivered' &&
            item.status != ParcelStatus.delivered &&
            item.status != ParcelStatus.returned) {
          return false;
        }
        if (widget.activeTab == 'cancelled' &&
            item.status != ParcelStatus.cancelled &&
            item.status != ParcelStatus.deliveryFailed) {
          return false;
        }
      }

      // Date range filter
      if (item.createdAt != null) {
        if (item.createdAt!.isBefore(start) || item.createdAt!.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();

    _matchingCount = filtered.length;
  }

  void _selectQuickRange(String rangeKey) {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    setState(() {
      _toDate = todayEnd;
      if (rangeKey == '7d') {
        _fromDate = now.subtract(const Duration(days: 7));
      } else if (rangeKey == '30d') {
        _fromDate = now.subtract(const Duration(days: 30));
      } else if (rangeKey == 'month') {
        _fromDate = DateTime(now.year, now.month, 1);
      }
      _validateAndRecalculate();
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
        if (isFrom) {
          _fromDate = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
        } else {
          _toDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
        _validateAndRecalculate();
      });
    }
  }

  Future<void> _handleDownload() async {
    if (_matchingCount == 0 || _validationError != null) return;

    setState(() => _isGenerating = true);

    try {
      // Check Android Storage Permission if needed
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied) {
          // Continue anyway using app documents dir
        }
      }

      final start = DateTime(
        _fromDate.year,
        _fromDate.month,
        _fromDate.day,
        0,
        0,
        0,
      );
      final end = DateTime(
        _toDate.year,
        _toDate.month,
        _toDate.day,
        23,
        59,
        59,
      );

      final exportItems = widget.allItems.where((item) {
        if (_selectedScope == 'current') {
          if (widget.activeTab == 'active' && !item.status.isLive) return false;
          if (widget.activeTab == 'delivered' &&
              item.status != ParcelStatus.delivered &&
              item.status != ParcelStatus.returned) {
            return false;
          }
          if (widget.activeTab == 'cancelled' &&
              item.status != ParcelStatus.cancelled &&
              item.status != ParcelStatus.deliveryFailed) {
            return false;
          }
        }
        if (item.createdAt != null) {
          if (item.createdAt!.isBefore(start) || item.createdAt!.isAfter(end)) {
            return false;
          }
        }
        return true;
      }).toList();

      final excelFile = await ExcelExportService.generateWaybillExcel(
        items: exportItems,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      final l10n = AppLocalizations.of(context)!;

      // Show success snackbar with "Open" action
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
                // Fallback to share sheet
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
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Drag Handle & Title
              Center(
                child: Container(
                  width: 38.0,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 10.0),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36.0,
                        height: 36.0,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: const Icon(
                          Icons.table_chart_outlined,
                          color: Color(0xFF059669),
                          size: 18.0,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Text(
                        'Export Waybill Data',
                        style: AppTypography.headingMedium.copyWith(
                          fontSize: 17.0,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF64748B),
                      size: 20.0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),

              // Scope Selector Toggle
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.all(3.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildScopeTab(
                        key: 'current',
                        label: '${widget.activeTab.toUpperCase()} TAB ONLY',
                        isSelected: _selectedScope == 'current',
                      ),
                    ),
                    Expanded(
                      child: _buildScopeTab(
                        key: 'all',
                        label: 'ALL STATUSES',
                        isSelected: _selectedScope == 'all',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12.0),

              // Quick Select Chips
              Text(
                'QUICK SELECT',
                style: AppTypography.monoLabel.copyWith(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  _buildQuickChip('Last 7 days', '7d'),
                  const SizedBox(width: 6.0),
                  _buildQuickChip('Last 30 days', '30d'),
                  const SizedBox(width: 6.0),
                  _buildQuickChip('This month', 'month'),
                ],
              ),

              const SizedBox(height: 12.0),

              // Date Pickers Row
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'FROM DATE',
                      value: dateFormat.format(_fromDate),
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: _buildDateField(
                      label: 'TO DATE',
                      value: dateFormat.format(_toDate),
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),

              if (_validationError != null) ...[
                const SizedBox(height: 6.0),
                Text(
                  _validationError!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 12.0),

              // Live Preview Count Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  color: _matchingCount > 0
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _matchingCount > 0
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _matchingCount > 0
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      color: _matchingCount > 0
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFDC2626),
                      size: 20.0,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        _matchingCount > 0
                            ? '$_matchingCount waybills found in this date range'
                            : 'No waybill records found for selected dates',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: _matchingCount > 0
                              ? const Color(0xFF1E40AF)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24.0),

              // Bottom Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          (_matchingCount == 0 ||
                              _validationError != null ||
                              _isGenerating)
                          ? null
                          : _handleDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      child: _isGenerating
                          ? const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.download_rounded,
                                  size: 18.0,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6.0),
                                Text(
                                  'Download Excel',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeTab({
    required String key,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedScope = key;
          _validateAndRecalculate();
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
            fontSize: 10.0,
            fontWeight: FontWeight.w800,
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFF64748B),
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String key) {
    return GestureDetector(
      onTap: () => _selectQuickRange(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
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
              vertical: 11.0,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16.0,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
