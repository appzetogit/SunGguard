import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_enums.dart';
import '../../domain/entities/waybill_item_entity.dart';

class HistoryState extends Equatable {
  final bool isLoading;
  final String activeTab; // 'active' | 'delivered' | 'cancelled' | 'outstation'
  final String searchQuery;
  final List<WaybillItemEntity> allItems;
  final String? errorMessage;

  const HistoryState({
    this.isLoading = false,
    this.activeTab = 'active',
    this.searchQuery = '',
    this.allItems = const [],
    this.errorMessage,
  });

  int get activeCount => allItems.where((i) => i.status.isLive).length;
  int get deliveredCount => allItems
      .where((i) => i.status == ParcelStatus.delivered || i.status == ParcelStatus.returned)
      .length;
  int get cancelledCount => allItems
      .where((i) =>
          i.status == ParcelStatus.cancelled ||
          i.status == ParcelStatus.deliveryFailed)
      .length;
  int get outstationCount => allItems.where((i) => i.kind == 'outstation').length;

  List<WaybillItemEntity> get filteredItems {
    return allItems.where((item) {
      // 1. Tab filter
      if (activeTab == 'active' && !item.status.isLive) return false;
      if (activeTab == 'delivered' &&
          item.status != ParcelStatus.delivered &&
          item.status != ParcelStatus.returned) {
        return false;
      }
      if (activeTab == 'cancelled' &&
          item.status != ParcelStatus.cancelled &&
          item.status != ParcelStatus.deliveryFailed) {
        return false;
      }
      if (activeTab == 'outstation' && item.kind != 'outstation') {
        return false;
      }

      // 2. Search filter
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchRef = item.referenceId.toLowerCase().contains(q);
        final matchPickup = item.pickupAddress.toLowerCase().contains(q);
        final matchDrop = item.dropAddress.toLowerCase().contains(q);
        return matchRef || matchPickup || matchDrop;
      }

      return true;
    }).toList();
  }

  HistoryState copyWith({
    bool? isLoading,
    String? activeTab,
    String? searchQuery,
    List<WaybillItemEntity>? allItems,
    String? errorMessage,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      allItems: allItems ?? this.allItems,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        activeTab,
        searchQuery,
        allItems,
        errorMessage,
      ];
}
