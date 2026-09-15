import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class HistoryFetchRequested extends HistoryEvent {}

class HistoryTabChanged extends HistoryEvent {
  final String tab; // 'active' | 'delivered' | 'cancelled'

  const HistoryTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}

class HistorySearchQueryChanged extends HistoryEvent {
  final String query;

  const HistorySearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}
