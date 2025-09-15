import "package:get_it/get_it.dart";
import "../features/plant_analysis/data/repositories/plant_analysis_repository.dart";

/// Service locator instance
final GetIt getIt = GetIt.instance;

/// Initialize dependency injection
void initDependencyInjection() {
  // Register repositories
  getIt.registerLazySingleton<PlantAnalysisRepository>(
    () => PlantAnalysisRepository(),
  );
}
