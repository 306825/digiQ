import 'package:flutter_riverpod/legacy.dart';

enum VerificationStatus { none, pending, approved, rejected }

class DriverVerificationState {
  final VerificationStatus status;
  final bool isSubmitting;

  DriverVerificationState({required this.status, this.isSubmitting = false});

  factory DriverVerificationState.initial() =>
      DriverVerificationState(status: VerificationStatus.none);
}

class DriverVerificationNotifier
    extends StateNotifier<DriverVerificationState> {
  DriverVerificationNotifier() : super(DriverVerificationState.initial());

  Future<void> submitDocuments() async {
    state = DriverVerificationState(
      status: VerificationStatus.pending,
      isSubmitting: true,
    );

    // API upload

    state = DriverVerificationState(status: VerificationStatus.pending);
  }
}

final driverVerificationProvider =
    StateNotifierProvider<DriverVerificationNotifier, DriverVerificationState>(
      (ref) => DriverVerificationNotifier(),
    );
