import 'package:equatable/equatable.dart';

abstract class ParcelHomeEvent extends Equatable {
  const ParcelHomeEvent();

  @override
  List<Object?> get props => [];
}

class ParcelHomeFetchRequested extends ParcelHomeEvent {}

class ParcelHomeServiceSwitched extends ParcelHomeEvent {
  final String service; // 'local' | 'outstation'

  const ParcelHomeServiceSwitched(this.service);

  @override
  List<Object?> get props => [service];
}
