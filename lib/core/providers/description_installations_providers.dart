// lib/core/providers/description_installations_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/add_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/get_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/remove_installation_item_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/save_description_installations_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_description_selection_use_case.dart';
import 'package:inspec_app/features/description_installations/domain/usecases/update_installation_item_use_case.dart';

final getDescriptionInstallationsUseCaseProvider = Provider<GetDescriptionInstallationsUseCase>((ref) {
  return GetIt.instance<GetDescriptionInstallationsUseCase>();
});

final saveDescriptionInstallationsUseCaseProvider = Provider<SaveDescriptionInstallationsUseCase>((ref) {
  return GetIt.instance<SaveDescriptionInstallationsUseCase>();
});

final addInstallationItemUseCaseProvider = Provider<AddInstallationItemUseCase>((ref) {
  return GetIt.instance<AddInstallationItemUseCase>();
});

final removeInstallationItemUseCaseProvider = Provider<RemoveInstallationItemUseCase>((ref) {
  return GetIt.instance<RemoveInstallationItemUseCase>();
});

final updateInstallationItemUseCaseProvider = Provider<UpdateInstallationItemUseCase>((ref) {
  return GetIt.instance<UpdateInstallationItemUseCase>();
});

final updateDescriptionSelectionUseCaseProvider = Provider<UpdateDescriptionSelectionUseCase>((ref) {
  return GetIt.instance<UpdateDescriptionSelectionUseCase>();
});
