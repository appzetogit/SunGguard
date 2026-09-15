import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;

  ProfileBloc({required this.profileRepository}) : super(const ProfileState()) {
    on<ProfileFetchRequested>(_onFetchRequested);
    on<ProfileAddAddressRequested>(_onAddAddressRequested);
    on<ProfileEditAddressRequested>(_onEditAddressRequested);
    on<ProfileDeleteAddressRequested>(_onDeleteAddressRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
  }

  Future<void> _onFetchRequested(
    ProfileFetchRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final addresses = await profileRepository.getSavedAddresses();
      final balance = await profileRepository.getWalletBalance();
      final txs = await profileRepository.getWalletTransactions();

      emit(state.copyWith(
        isLoading: false,
        addresses: addresses,
        walletBalance: balance,
        transactions: txs,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onAddAddressRequested(
    ProfileAddAddressRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await profileRepository.addAddress(event.address);
    } catch (_) {}
    final addresses = await profileRepository.getSavedAddresses();
    emit(state.copyWith(isLoading: false, addresses: addresses));
  }

  Future<void> _onEditAddressRequested(
    ProfileEditAddressRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await profileRepository.updateAddress(event.address);
    } catch (_) {}
    final addresses = await profileRepository.getSavedAddresses();
    emit(state.copyWith(isLoading: false, addresses: addresses));
  }

  Future<void> _onDeleteAddressRequested(
    ProfileDeleteAddressRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      await profileRepository.deleteAddress(event.addressId);
    } catch (_) {}
    final addresses = await profileRepository.getSavedAddresses();
    emit(state.copyWith(isLoading: false, addresses: addresses));
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, isUpdated: false));
    try {
      final updatedUser = await profileRepository.updateProfile(
        name: event.name,
        email: event.email,
        avatar: event.avatar,
      );
      emit(state.copyWith(isLoading: false, isUpdated: true, updatedUser: updatedUser));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: "Couldn't update profile"));
    }
  }
}
