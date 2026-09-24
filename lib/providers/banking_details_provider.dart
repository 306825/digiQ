import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strut/core/api/banking_details_api.dart';
import 'package:strut/models/banking_details_model.dart';

class BankingDetailsNotifier extends AsyncNotifier<BankingDetails> {
  @override
  Future<BankingDetails> build() async {
    return ref.read(bankingDetailsApiProvider).adminGet();
  }

  Future<void> save(BankingDetails details) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(bankingDetailsApiProvider).adminUpdate(details),
    );
  }
}

final bankingDetailsProvider =
    AsyncNotifierProvider<BankingDetailsNotifier, BankingDetails>(
        BankingDetailsNotifier.new);
