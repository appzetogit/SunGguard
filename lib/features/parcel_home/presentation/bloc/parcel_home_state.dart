import 'package:equatable/equatable.dart';
import '../../domain/entities/parcel_summary_entity.dart';

class ParcelHomeState extends Equatable {
  final bool isLoading;
  final String activeService; // 'local' | 'outstation'
  final List<ParcelSummaryEntity> activeShipments;
  final String? errorMessage;

  const ParcelHomeState({
    this.isLoading = false,
    this.activeService = 'local',
    this.activeShipments = const [],
    this.errorMessage,
  });

  bool get isLocal => activeService == 'local';

  List<ParcelSummaryEntity> get localShipments =>
      activeShipments.where((p) => p.kind == 'local').toList();

  List<ParcelSummaryEntity> get outstationShipments =>
      activeShipments.where((p) => p.kind == 'outstation').toList();

  List<ParcelSummaryEntity> get currentShipments =>
      isLocal ? localShipments : outstationShipments;

  int get currentCount => currentShipments.length;

  ParcelHomeState copyWith({
    bool? isLoading,
    String? activeService,
    List<ParcelSummaryEntity>? activeShipments,
    String? errorMessage,
  }) {
    return ParcelHomeState(
      isLoading: isLoading ?? this.isLoading,
      activeService: activeService ?? this.activeService,
      activeShipments: activeShipments ?? this.activeShipments,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, activeService, activeShipments, errorMessage];
}
