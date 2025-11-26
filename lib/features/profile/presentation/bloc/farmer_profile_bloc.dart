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
  /// Implements retry logic for 401 errors to allow token refresh time
  Future<void> _onLoadFarmerProfile(
    LoadFarmerProfile event,
    Emitter<FarmerProfileState> emit,
  ) async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount <= maxRetries) {
      try {
        print('🔄 FarmerProfileBloc: Loading profile (attempt ${retryCount + 1}/${maxRetries + 1})...');
        emit(const FarmerProfileLoading());

        final profile = await repository.getProfile();

        print('✅ FarmerProfileBloc: Profile loaded successfully');
        emit(FarmerProfileLoaded(profile));
        return; // Success - exit retry loop

      } catch (e) {
        print('❌ FarmerProfileBloc: Error loading profile (attempt ${retryCount + 1}): $e');

        // Check if this is a 401 error and we haven't exhausted retries
        final is401Error = e.toString().contains('401') ||
                          e.toString().toLowerCase().contains('unauthorized');

        if (is401Error && retryCount < maxRetries) {
          print('⚠️ FarmerProfileBloc: Got 401 error, waiting for token refresh...');
          retryCount++;

          // Exponential backoff: 500ms, 1000ms, 1500ms
          final delayMs = 500 * retryCount;
          await Future.delayed(Duration(milliseconds: delayMs));

          print('🔄 FarmerProfileBloc: Retrying after token refresh delay...');
          continue; // Retry the loop
        }

        // Final failure or non-401 error - show error to user
        print('❌ FarmerProfileBloc: Final error after ${retryCount + 1} attempts');
        emit(FarmerProfileError(
          message: 'Profil yüklenirken hata oluştu: ${_getUserFriendlyError(e)}',
        ));
        return;
      }
    }
  }

  /// Convert technical error to user-friendly message
  String _getUserFriendlyError(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('401') || errorStr.toLowerCase().contains('unauthorized')) {
      return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
    } else if (errorStr.toLowerCase().contains('network') ||
               errorStr.toLowerCase().contains('socket')) {
      return 'İnternet bağlantınızı kontrol edin.';
    } else if (errorStr.toLowerCase().contains('timeout')) {
      return 'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.';
    } else if (errorStr.toLowerCase().contains('null check')) {
      return 'Profil verileri alınırken bir sorun oluştu. Lütfen tekrar deneyin.';
    }

    return 'Bir hata oluştu. Lütfen tekrar deneyin.';
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
