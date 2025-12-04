import "package:get_it/get_it.dart";
import "package:dio/dio.dart";
import "../features/plant_analysis/domain/repositories/plant_analysis_repository.dart";
import "../features/plant_analysis/data/repositories/plant_analysis_repository_impl.dart";
import "../features/plant_analysis/data/services/plant_analysis_api_service.dart";
import "../core/services/auth_service.dart";

/// Service locator instance
final GetIt getIt = GetIt.instance;

/// Initialize dependency injection
void initDependencyInjection() {
  // Register repositories - using implementation class
  getIt.registerLazySingleton<PlantAnalysisRepository>(
    () => PlantAnalysisRepositoryImpl(
      getIt<PlantAnalysisApiService>(),
      getIt<AuthService>(),
      getIt<Dio>(), // Added missing Dio dependency
    ),
  );
}
