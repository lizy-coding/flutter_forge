import 'package:equatable/equatable.dart';

enum CounterStatus { initial, loading, success, failure }

class CounterState extends Equatable {
  const CounterState(
      {this.value = 0, this.status = CounterStatus.initial, this.error});

  final int value;
  final CounterStatus status;
  final String? error;

  CounterState copyWith({int? value, CounterStatus? status, String? error}) {
    return CounterState(
      value: value ?? this.value,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [value, status, error];
}
