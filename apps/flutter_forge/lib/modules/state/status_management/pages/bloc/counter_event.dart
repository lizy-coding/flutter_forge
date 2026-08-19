import 'package:flutter/foundation.dart';

@immutable
sealed class CounterEvent {}

class LoadInitial extends CounterEvent {}

class IncrementPressed extends CounterEvent {}

class ResetPressed extends CounterEvent {}
