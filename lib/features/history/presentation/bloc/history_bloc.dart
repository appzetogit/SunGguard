import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/history_repository.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final HistoryRepository historyRepository;

  HistoryBloc({required this.historyRepository}) : super(const HistoryState()) {
    on<HistoryFetchRequested>(_onFetchRequested);
    on<HistoryTabChanged>(_onTabChanged);
    on<HistorySearchQueryChanged>(_onSearchQueryChanged);
  }

  Future<void> _onFetchRequested(
    HistoryFetchRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await historyRepository.getWaybillHistory();
      emit(state.copyWith(isLoading: false, allItems: items));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "Couldn't load waybill history"));
    }
  }

  void _onTabChanged(
    HistoryTabChanged event,
    Emitter<HistoryState> emit,
  ) {
    emit(state.copyWith(activeTab: event.tab));
  }

  void _onSearchQueryChanged(
    HistorySearchQueryChanged event,
    Emitter<HistoryState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }
}
