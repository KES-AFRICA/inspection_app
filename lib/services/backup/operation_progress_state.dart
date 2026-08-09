// lib/services/backup/operation_progress_state.dart

enum OperationType {
  export,
  import,
}

enum OperationStatus {
  initialization,
  preparing,
  inProgress,
  nextMission,
  completed,
  cancelled,
  error,
}

class OperationProgressState {
  final OperationType type;
  final OperationStatus status;
  final String title;
  final String? currentMissionName;
  final int currentMissionIndex;
  final int totalMissions;
  final String currentStep;
  final double overallProgress;
  final double currentMissionProgress;
  final int processedItemsCount;
  final int processedPhotosCount;
  final String? message;
  final String? errorDetail;
  final bool isCancelRequested;

  const OperationProgressState({
    required this.type,
    required this.status,
    required this.title,
    this.currentMissionName,
    this.currentMissionIndex = 0,
    this.totalMissions = 1,
    this.currentStep = 'Initialisation...',
    this.overallProgress = 0.0,
    this.currentMissionProgress = 0.0,
    this.processedItemsCount = 0,
    this.processedPhotosCount = 0,
    this.message,
    this.errorDetail,
    this.isCancelRequested = false,
  });

  OperationProgressState copyWith({
    OperationType? type,
    OperationStatus? status,
    String? title,
    String? currentMissionName,
    int? currentMissionIndex,
    int? totalMissions,
    String? currentStep,
    double? overallProgress,
    double? currentMissionProgress,
    int? processedItemsCount,
    int? processedPhotosCount,
    String? message,
    String? errorDetail,
    bool? isCancelRequested,
  }) {
    return OperationProgressState(
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      currentMissionName: currentMissionName ?? this.currentMissionName,
      currentMissionIndex: currentMissionIndex ?? this.currentMissionIndex,
      totalMissions: totalMissions ?? this.totalMissions,
      currentStep: currentStep ?? this.currentStep,
      overallProgress: overallProgress ?? this.overallProgress,
      currentMissionProgress: currentMissionProgress ?? this.currentMissionProgress,
      processedItemsCount: processedItemsCount ?? this.processedItemsCount,
      processedPhotosCount: processedPhotosCount ?? this.processedPhotosCount,
      message: message ?? this.message,
      errorDetail: errorDetail ?? this.errorDetail,
      isCancelRequested: isCancelRequested ?? this.isCancelRequested,
    );
  }
}
