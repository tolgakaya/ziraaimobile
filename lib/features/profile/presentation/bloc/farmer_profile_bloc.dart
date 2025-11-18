import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/farmer_profile_repository.dart';
import 'farmer_profile_event.dart';
import 'farmer_profile_state.dart';

/// BLoC for farmer profile management
/// Handles loading and updating farmer profile
class FarmerProfileBloc extends Bloc<FarmerProfileEvent, FarmerProfileState> {
  final FarmerProfileRepository repository;

  FarmerProfileBloc({required this.repository})
      : super(const FarmerProfileInitial()) {
    on<LoadFarmerProfile>(_onLoadFarmerProfile);
    on<UpdateFarmerProfile>(_onUpdateFarmerProfile);
  }

  /// Handle load profile event
  Future<void> _onLoadFarmerProfile(
    LoadFarmerProfile event,
    Emitter<FarmerProfileState> emit,
  ) async {
    try {
      print('🔄 FarmerProfileBloc: Loading profile...');
      emit(const FarmerProfileLoading());

      final profile = await repository.getProfile();

      print('✅ FarmerProfileBloc: Profile loaded successfully');
      emit(FarmerProfileLoaded(profile));
    } catch (e) {
      print('❌ FarmerProfileBloc: Error loading profile: $e');
      emit(FarmerProfileError(
        message: 'Profil yüklenirken hata oluştu: ${e.toString()}',
      ));
    }
  }

  /// Handle update profile event
  Future<void> _onUpdateFarmerProfile(
    UpdateFarmerProfile event,
    Emitter<FarmerProfileState> emit,
  ) async {
    try {
      print('🔄 FarmerProfileBloc: Updating profile...');

      // Get current profile if available
      final currentState = state;
      final currentProfile = currentState is FarmerProfileLoaded
          ? currentState.profile
          : (currentState is FarmerProfileUpdateSuccess
              ? currentState.profile
              : null);

      if (currentProfile != null) {
        emit(FarmerProfileUpdating(currentProfile));
      } else {
        emit(const FarmerProfileLoading());
      }

      final updatedProfile = await repository.updateProfile(
        fullName: event.fullName,
        email: event.email,
        mobilePhones: event.mobilePhones,
        birthDate: event.birthDate,
        gender: event.gender,
        address: event.address,
        notes: event.notes,
      );

      print('✅ FarmerProfileBloc: Profile updated successfully');
      emit(FarmerProfileUpdateSuccess(profile: updatedProfile));
    } catch (e) {
      print('❌ FarmerProfileBloc: Error updating profile: $e');

      // Keep current profile if available
      final currentState = state;
      final currentProfile = currentState is FarmerProfileUpdating
          ? currentState.currentProfile
          : null;

      emit(FarmerProfileError(
        message: 'Profil güncellenirken hata oluştu: ${e.toString()}',
        currentProfile: currentProfile,
      ));
    }
  }
}
