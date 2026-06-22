import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'counter_event.dart';
import 'counter_state.dart';

/// Bloc 业务逻辑层：处理事件并输出不可变状态
class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState()) {
    on<LoadInitial>(_onLoadInitial);
    on<IncrementPressed>(_onIncrement);
    on<ResetPressed>(_onReset);
  }

  Future<void> _onLoadInitial(
      LoadInitial event, Emitter<CounterState> emit) async {
    emit(state.copyWith(status: CounterStatus.loading));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      emit(state.copyWith(status: CounterStatus.success));
    } catch (e) {
      emit(state.copyWith(status: CounterStatus.failure, error: '$e'));
    }
  }

  void _onIncrement(IncrementPressed event, Emitter<CounterState> emit) {
    emit(state.copyWith(value: state.value + 1, status: CounterStatus.success));
  }

  void _onReset(ResetPressed event, Emitter<CounterState> emit) {
    emit(state.copyWith(value: 0, status: CounterStatus.success));
  }
}
