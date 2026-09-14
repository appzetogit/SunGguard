import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/parcel_home_repository.dart';
import 'parcel_home_event.dart';
import 'parcel_home_state.dart';

class ParcelHomeBloc extends Bloc<ParcelHomeEvent, ParcelHomeState> {
  final ParcelHomeRepository parcelHomeRepository;

  ParcelHomeBloc({required this.parcelHomeRepository}) : super(const ParcelHomeState()) {
    on<ParcelHomeFetchRequested>(_onFetchRequested);
    on<ParcelHomeServiceSwitched>(_onServiceSwitched);
  }

  Future<void> _onFetchRequested(
    ParcelHomeFetchRequested event,
    Emitter<ParcelHomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final shipments = await parcelHomeRepository.getActiveShipments();
      emit(state.copyWith(
        isLoading: false,
        activeShipments: shipments,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: "Couldn't load shipments",
      ));
    }
  }

  void _onServiceSwitched(
    ParcelHomeServiceSwitched event,
    Emitter<ParcelHomeState> emit,
  ) {
    emit(state.copyWith(activeService: event.service));
  }
}
